import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:shelf_multipart/shelf_multipart.dart';
import 'package:shelf_router/shelf_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/storage_paths.dart';
import '../../domain/entities/connected_client.dart';
import '../../domain/entities/downloaded_file.dart';
import '../../domain/entities/host_publish_file.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/server_shared_file.dart';
import '../../domain/entities/server_upload_event.dart';
import 'device_media_store.dart';
import 'local_ip_resolver.dart';
import 'media_store.dart';
import 'web_client_assets.dart';
import 'web_server_transport.dart';

/// HTTP relay hub built on `shelf` + `shelf_router` (FUNCTIONALITY.md §5).
///
/// Serves the embedded web client (`assets/web_client/`) and exposes:
///
/// | Route | Purpose |
/// |-------|---------|
/// | `GET /` | Guest web client (HTML) |
/// | `GET /style.css`, `GET /app.js` | Guest web client assets |
/// | `GET /files` | JSON list of shareable files |
/// | `GET /download/{fileId}` | Stream a file to the guest |
/// | `POST /upload` | `multipart/form-data` upload (streamed to disk) |
/// | `GET /api/ping` | Liveness beacon from the guest web client |
///
/// Guests are tracked by remote IP; the list is pruned by a liveness timeout
/// and the configured session timeout. Uploads land in the shared "BlazeDrop"
/// directory with sanitized names and are surfaced as [ServerUploadEvent]s.
class ShelfWebServerTransport implements WebServerTransport {
  ShelfWebServerTransport({
    required LocalIpResolver ipResolver,
    required WebClientAssets assets,
    Future<String> Function()? sharedDirectoryProvider,
    MediaStore? mediaStore,
    this.clientTimeout = AppConstants.serverClientTimeout,
  }) : _ipResolver = ipResolver,
       _assets = assets,
       _sharedDirectoryProvider =
           sharedDirectoryProvider ?? _defaultSharedDirectory,
       _mediaStore = mediaStore ?? DeviceMediaStore();

  final LocalIpResolver _ipResolver;
  final WebClientAssets _assets;
  final Future<String> Function() _sharedDirectoryProvider;
  final MediaStore _mediaStore;
  final Duration clientTimeout;

  HttpServer? _server;
  Timer? _pruneTimer;
  var _preferredPort = AppConstants.serverDefaultPort;
  var _lastSessionTimeoutMinutes = _defaultSessionMinutes;
  Duration _sessionTimeout = const Duration(minutes: 15);
  ServerSession _session = const ServerSession(status: ServerStatus.idle);
  final Map<String, ConnectedClient> _clients = {};
  final Map<String, DateTime> _connectedAt = {};
  bool _disposed = false;

  final _statusController = StreamController<ServerSession>.broadcast();
  final _clientsController =
      StreamController<List<ConnectedClient>>.broadcast();
  final _uploadsController = StreamController<ServerUploadEvent>.broadcast();

  @override
  Stream<ServerSession> watchStatus() => _statusController.stream;

  @override
  Stream<List<ConnectedClient>> watchClients() => _clientsController.stream;

  @override
  Stream<ServerUploadEvent> watchUploads() => _uploadsController.stream;

  // --- Lifecycle ----------------------------------------------------------

  @override
  Future<ServerSession> start({
    required int preferredPort,
    required int sessionTimeoutMinutes,
  }) async {
    _preferredPort = preferredPort;
    _lastSessionTimeoutMinutes = sessionTimeoutMinutes > 0
        ? sessionTimeoutMinutes
        : _defaultSessionMinutes;
    _sessionTimeout = Duration(minutes: _lastSessionTimeoutMinutes);
    final ip = await _ipResolver.resolve();
    final handler = _handler();

    // Try preferredPort, then 8081, 8082, … finally an OS-assigned port
    // (FUNCTIONALITY.md §8 "Server Port Conflict").
    HttpServer? server;
    var port = preferredPort;
    for (var attempt = 0; attempt < AppConstants.serverPortAttempts; attempt++) {
      try {
        server = await shelf_io.serve(handler, InternetAddress.anyIPv4, port);
        break;
      } on SocketException {
        port++;
      }
    }
    server ??= await shelf_io.serve(handler, InternetAddress.anyIPv4, 0);

    _server = server;
    _session = ServerSession(
      status: ServerStatus.active,
      port: server.port,
      localIp: ip,
      startedAt: DateTime.now(),
    );
    _statusController.add(_session);
    _pruneTimer?.cancel();
    _pruneTimer = Timer.periodic(clientTimeout, (_) => _pruneClients());
    AppLogger.info('Relay hub active: ${_session.url}');
    return _session;
  }

  @override
  Future<void> stop() async {
    _pruneTimer?.cancel();
    _pruneTimer = null;
    final server = _server;
    _server = null;
    if (server != null) {
      try {
        await server.close(force: true);
      } catch (error, stack) {
        AppLogger.error('Failed to close relay hub', error, stack);
      }
    }
    _clients.clear();
    _connectedAt.clear();
    _session = const ServerSession(status: ServerStatus.stopped);
    _statusController.add(_session);
    _emitClients();
    AppLogger.info('Relay hub stopped');
  }

  @override
  Future<void> refresh() async {
    final nextPort = _preferredPort + 1;
    await stop();
    await start(
      preferredPort: nextPort,
      sessionTimeoutMinutes: _lastSessionTimeoutMinutes,
    );
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await stop();
    await _statusController.close();
    await _clientsController.close();
    await _uploadsController.close();
  }

  // --- Routes -------------------------------------------------------------

  Handler _handler() {
    final router = Router()
      ..get('/', (Request request) => _serveAsset(
        request,
        AppConstants.webClientIndexPath,
        'text/html',
      ))
      ..get('/style.css', (Request request) => _serveAsset(
        request,
        AppConstants.webClientCssPath,
        'text/css',
      ))
      ..get('/app.js', (Request request) => _serveAsset(
        request,
        AppConstants.webClientJsPath,
        'application/javascript',
      ))
      ..get('/files', _handleFiles)
      ..get('/download/<fileId>', _handleDownload)
      ..post('/upload', _handleUpload)
      ..get('/api/ping', _handlePing);

    // Every request marks the guest as seen; the ping endpoint also updates
    // the guest codename.
    return (Request request) {
      _touchClient(request);
      return router.call(request);
    };
  }

  Future<Response> _serveAsset(
    Request request,
    String assetPath,
    String contentType,
  ) async {
    try {
      final body = await _assets.load(assetPath);
      return Response.ok(
        body,
        headers: {'Content-Type': '$contentType; charset=utf-8'},
      );
    } catch (error, stack) {
      AppLogger.error('Web client asset unavailable: $assetPath', error, stack);
      return Response.internalServerError(body: 'Asset unavailable');
    }
  }

  Future<Response> _handleFiles(Request request) async {
    final files = await _scanDirectory(await _sharedDirectory());
    final payload = files
        .map(
          (f) => <String, Object?>{
            'id': f.id,
            'name': f.name,
            'size': f.size,
            'mimeType': f.mimeType,
            'addedAt': f.addedAt?.toIso8601String(),
          },
        )
        .toList();
    return _json({'files': payload});
  }

  Future<Response> _handleDownload(Request request, String fileId) async {
    final dir = await _sharedDirectory();
    final safeId = FileUtils.sanitizeFileName(fileId);
    final file = File('$dir${Platform.pathSeparator}$safeId');
    try {
      if (!await file.exists()) {
        return Response.notFound('File not found');
      }
      final size = await file.length();
      return Response.ok(
        file.openRead(),
        headers: {
          'Content-Type': FileUtils.mimeTypeForName(safeId),
          'Content-Length': '$size',
          'Content-Disposition':
              'attachment; filename="${Uri.encodeComponent(safeId)}"',
        },
      );
    } catch (error, stack) {
      AppLogger.error('Download failed: $fileId', error, stack);
      return Response.internalServerError(body: 'Download failed');
    }
  }

  Future<Response> _handleUpload(Request request) async {
    final multipart = request.multipart();
    if (multipart == null) {
      return _json(
        {'ok': false, 'error': 'expected multipart/form-data'},
        status: 400,
      );
    }
    final ip = _clientIp(request);
    _setClientState(ip, ClientConnectionState.syncing);
    final dir = await _sharedDirectory();
    final results = <Map<String, Object?>>[];
    try {
      await for (final part in multipart.parts) {
        final filename = _filenameOf(part.headers['content-disposition']);
        if (filename == null) {
          continue; // non-file form field
        }
        final safeName = FileUtils.sanitizeFileName(filename);
        final target = await FileUtils.resolveUniquePath(dir, safeName);
        final savedName = p.basename(target);
        final total = int.tryParse(part.headers['content-length'] ?? '') ?? 0;
        _uploadsController.add(
          ServerUploadEvent(
            fileName: savedName,
            transferredBytes: 0,
            totalBytes: total,
            status: ServerUploadStatus.receiving,
            clientIp: ip,
          ),
        );
        final file = File(target);
        final sink = file.openWrite();
        var transferred = 0;
        var lastEmitted = 0;
        try {
          await for (final chunk in part) {
            transferred += chunk.length;
            sink.add(chunk);
            if (transferred - lastEmitted >= _progressEmitThreshold) {
              lastEmitted = transferred;
              _uploadsController.add(
                ServerUploadEvent(
                  fileName: savedName,
                  transferredBytes: transferred,
                  totalBytes: total,
                  status: ServerUploadStatus.receiving,
                  clientIp: ip,
                ),
              );
            }
          }
          await sink.flush();
          await sink.close();
          final size = await file.length();
          _uploadsController.add(
            ServerUploadEvent(
              fileName: savedName,
              transferredBytes: size,
              totalBytes: size,
              status: ServerUploadStatus.completed,
              clientIp: ip,
              savedPath: target,
            ),
          );
          results.add({
            'name': savedName,
            'size': size,
            'mimeType': FileUtils.mimeTypeForName(savedName),
          });
        } catch (error, stack) {
          await sink.close().catchError((_) => file);
          await file.delete().catchError((_) => file);
          _uploadsController.add(
            ServerUploadEvent(
              fileName: savedName,
              transferredBytes: transferred,
              totalBytes: total,
              status: ServerUploadStatus.failed,
              clientIp: ip,
              message: 'Upload aborted',
            ),
          );
          AppLogger.error('Upload failed: $savedName', error, stack);
          results.add({'name': savedName, 'error': error.toString()});
        }
      }
    } catch (error, stack) {
      AppLogger.error('Multipart body malformed', error, stack);
      return _json(
        {'ok': false, 'error': 'malformed upload'},
        status: 400,
      );
    } finally {
      _setClientState(ip, ClientConnectionState.idle);
    }
    return _json({'ok': true, 'files': results});
  }

  Future<Response> _handlePing(Request request) async {
    final name = request.url.queryParameters['client'];
    _touchClient(request, name: name);
    return _json({
      'status': 'ok',
      'node': AppConstants.appName,
      'port': _session.port,
    });
  }

  // --- Client tracking ----------------------------------------------------

  void _touchClient(Request request, {String? name}) {
    if (_disposed) {
      return;
    }
    final ip = _clientIp(request);
    final now = DateTime.now();
    final existing = _clients[ip];
    if (existing == null) {
      _clients[ip] = ConnectedClient(
        id: ip,
        name: (name == null || name.isEmpty) ? _guessName(request) : name,
        ipAddress: ip,
        userAgent: request.headers['user-agent'] ?? '',
        lastSeen: now,
      );
      _connectedAt[ip] = now;
    } else {
      _clients[ip] = existing.copyWith(
        name: (name == null || name.isEmpty) ? existing.name : name,
        lastSeen: now,
      );
    }
    _emitClients();
  }

  void _setClientState(String ip, ClientConnectionState state) {
    final client = _clients[ip];
    if (client == null) {
      return;
    }
    _clients[ip] = client.copyWith(state: state);
    _emitClients();
  }

  void _pruneClients() {
    if (_disposed || _clients.isEmpty) {
      return;
    }
    final now = DateTime.now();
    final livenessCutoff = now.subtract(clientTimeout);
    final sessionCutoff = now.subtract(_sessionTimeout);
    final before = _clients.length;
    _clients.removeWhere((ip, client) {
      final firstSeen = _connectedAt[ip] ?? now;
      final lastSeen = client.lastSeen ?? now;
      return lastSeen.isBefore(livenessCutoff) ||
          firstSeen.isBefore(sessionCutoff);
    });
    if (_clients.length != before) {
      _emitClients();
    }
  }

  void _emitClients() {
    if (!_clientsController.isClosed) {
      _clientsController.add(List<ConnectedClient>.of(_clients.values));
    }
  }

  String _clientIp(Request request) {
    final info =
        request.context['shelf.io.connection_info'] as HttpConnectionInfo?;
    return info?.remoteAddress.address ?? 'unknown';
  }

  String _guessName(Request request) {
    final userAgent = request.headers['user-agent'] ?? '';
    if (userAgent.contains('Mobile')) {
      return 'MOBILE_GUEST';
    }
    if (userAgent.contains('Macintosh')) {
      return 'MAC_GUEST';
    }
    if (userAgent.contains('Windows')) {
      return 'WIN_GUEST';
    }
    if (userAgent.contains('Linux')) {
      return 'LINUX_GUEST';
    }
    return 'WEB_GUEST';
  }

  // --- Shared storage -----------------------------------------------------

  @override
  Future<List<ServerSharedFile>> listFiles() async {
    return _scanDirectory(await _sharedDirectory());
  }

  @override
  Future<List<ServerSharedFile>> publishFiles(
    List<HostPublishFile> files,
  ) async {
    final dir = await _sharedDirectory();
    final results = <ServerSharedFile>[];
    for (final file in files) {
      final source = File(file.path);
      if (!await source.exists()) {
        continue;
      }
      final safeName = FileUtils.sanitizeFileName(file.name);
      final target = await FileUtils.resolveUniquePath(dir, safeName);
      await source.copy(target);
      final savedName = p.basename(target);
      final size = await File(target).length();
      final shared = ServerSharedFile(
        id: FileUtils.sanitizeFileName(savedName),
        name: savedName,
        path: target,
        size: size,
        mimeType:
            file.mimeType ?? FileUtils.mimeTypeForName(savedName),
        addedAt: DateTime.now(),
      );
      results.add(shared);
      // Surface the publication in the HUD so host + guests see it live.
      _uploadsController.add(
        ServerUploadEvent(
          fileName: savedName,
          transferredBytes: size,
          totalBytes: size,
          status: ServerUploadStatus.completed,
          clientIp: 'HOST',
          savedPath: target,
        ),
      );
      AppLogger.info('Host published $savedName to the hub');
    }
    return results;
  }

  @override
  Future<DownloadedFile?> downloadSharedFile(String fileId) async {
    final sharedDir = await _sharedDirectory();
    final safeId = FileUtils.sanitizeFileName(fileId);
    final source = File('$sharedDir${Platform.pathSeparator}$safeId');
    if (!await source.exists()) {
      return null;
    }
    final fileName = p.basename(source.path);
    final downloaded = await _mediaStore.store(
      sourcePath: source.path,
      fileName: fileName,
    );
    AppLogger.info(
      'Host downloaded $fileName → ${downloaded.target.name}',
    );
    return downloaded;
  }

  @override
  Future<String> getLocalIp() => _ipResolver.resolve();

  @override
  Future<String> getSharedDirectory() => _sharedDirectory();

  Future<String> _sharedDirectory() => _sharedDirectoryProvider();

  static Future<String> _defaultSharedDirectory() =>
      StoragePaths.inboxDirectory;

  Future<List<ServerSharedFile>> _scanDirectory(String dir) async {
    final directory = Directory(dir);
    if (!await directory.exists()) {
      return const [];
    }
    final results = <ServerSharedFile>[];
    await for (final entity in directory.list(followLinks: false)) {
      if (entity is! File) {
        continue;
      }
      final name = p.basename(entity.path);
      try {
        final size = await entity.length();
        final stat = await entity.stat();
        results.add(
          ServerSharedFile(
            id: FileUtils.sanitizeFileName(name),
            name: name,
            path: entity.path,
            size: size,
            mimeType: FileUtils.mimeTypeForName(name),
            addedAt: stat.modified,
          ),
        );
      } catch (error, stack) {
        AppLogger.error('Failed to stat shared file: $name', error, stack);
      }
    }
    results.sort(
      (a, b) => (b.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
        a.addedAt ?? DateTime.fromMillisecondsSinceEpoch(0),
      ),
    );
    return results;
  }

  // --- Helpers ------------------------------------------------------------

  static const int _progressEmitThreshold = 256 * 1024;
  static const int _defaultSessionMinutes = 15;

  Response _json(Map<String, Object?> body, {int status = 200}) {
    return Response(
      status,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
  }

  String? _filenameOf(String? disposition) {
    final header = disposition ?? '';
    final star = RegExp(
      r'''filename\*\s*=\s*(?:UTF-8''|utf-8'')([^;]+)''',
      caseSensitive: false,
    ).firstMatch(header);
    if (star != null) {
      try {
        return Uri.decodeComponent(star.group(1) ?? '');
      } catch (_) {
        return star.group(1);
      }
    }
    final plain = RegExp(
      r'filename\s*=\s*"?([^";]+)"?',
      caseSensitive: false,
    ).firstMatch(header);
    return plain?.group(1);
  }
}
