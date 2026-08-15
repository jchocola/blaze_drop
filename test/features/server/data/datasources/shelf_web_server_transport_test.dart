import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blaze_drop/features/server/data/datasources/local_ip_resolver.dart';
import 'package:blaze_drop/features/server/data/datasources/media_store.dart';
import 'package:blaze_drop/features/server/data/datasources/shelf_web_server_transport.dart';
import 'package:blaze_drop/features/server/data/datasources/tls_certificate_provider.dart';
import 'package:blaze_drop/features/server/data/datasources/web_client_assets.dart';
import 'package:blaze_drop/features/server/domain/entities/connected_client.dart';
import 'package:blaze_drop/features/server/domain/entities/downloaded_file.dart';
import 'package:blaze_drop/features/server/domain/entities/host_publish_file.dart';
import 'package:blaze_drop/features/server/domain/entities/server_session.dart';
import 'package:blaze_drop/features/server/domain/entities/server_upload_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

class _FakeIpResolver implements LocalIpResolver {
  const _FakeIpResolver(this.ip);

  final String ip;

  @override
  Future<String> resolve() async => ip;
}

class _FakeAssets implements WebClientAssets {
  const _FakeAssets({required this.html, required this.css, required this.js});

  final String html;
  final String css;
  final String js;

  @override
  Future<String> load(String assetPath) async {
    if (assetPath.endsWith('index.html')) {
      return html;
    }
    if (assetPath.endsWith('style.css')) {
      return css;
    }
    if (assetPath.endsWith('app.js')) {
      return js;
    }
    throw ArgumentError('Unknown asset: $assetPath');
  }
}

/// Fake [MediaStore] that copies everything to a documents dir (no `gal`).
class _FakeMediaStore implements MediaStore {
  _FakeMediaStore(this.documentsDir);

  final String documentsDir;

  @override
  Future<DownloadedFile> store({
    required String sourcePath,
    required String fileName,
  }) async {
    final target = '$documentsDir/${fileName.replaceAll(RegExp(r'[/\\]'), '_')}';
    await File(sourcePath).copy(target);
    return DownloadedFile(
      name: fileName,
      target: DownloadTarget.documents,
      path: target,
    );
  }
}

void main() {
  late ShelfWebServerTransport transport;
  late Directory tempDir;
  late Directory receivedDir;
  late List<ServerUploadEvent> uploadEvents;
  late StreamSubscription<ServerUploadEvent> uploadSubscription;

  // TLS identity is generated once (RSA keygen is slow) and cached in a temp
  // dir; all tests reuse the same certificate because the fake IP is fixed.
  late Directory tlsDir;
  late TlsCertificateProvider tlsProvider;
  late http.Client client; // accepts self-signed certs (test-only).

  setUpAll(() async {
    tlsDir = await Directory.systemTemp.createTemp('blazedrop_tls_test');
    tlsProvider = FileSystemTlsCertificateProvider(
      cacheDirectoryProvider: () async => tlsDir,
    );
    client = IOClient(
      HttpClient()..badCertificateCallback = (_, _, _) => true,
    );
  });

  tearDownAll(() async {
    client.close();
    await tlsDir.delete(recursive: true);
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('blazedrop_server_test');
    receivedDir = await Directory.systemTemp.createTemp(
      'blazedrop_received_test',
    );
    transport = ShelfWebServerTransport(
      ipResolver: const _FakeIpResolver('192.168.1.10'),
      assets: const _FakeAssets(
        html: '<html>guest</html>',
        css: 'body{}',
        js: 'console.log(1);',
      ),
      tlsProvider: tlsProvider,
      sharedDirectoryProvider: () async => tempDir.path,
      mediaStore: _FakeMediaStore(receivedDir.path),
      clientTimeout: const Duration(seconds: 5),
    );
    uploadEvents = [];
    uploadSubscription = transport.watchUploads().listen(uploadEvents.add);
  });

  tearDown(() async {
    await uploadSubscription.cancel();
    await transport.dispose();
    await tempDir.delete(recursive: true);
    await receivedDir.delete(recursive: true);
  });

  Future<ServerSession> startHub() =>
      transport.start(preferredPort: 0, sessionTimeoutMinutes: 15);

  Uri hubUri(ServerSession session, String path) =>
      Uri.parse('https://127.0.0.1:${session.port}$path');

  test('starts on a free port, serving HTTPS with a cert fingerprint', () async {
    final session = await startHub();

    expect(session.status, ServerStatus.active);
    expect(session.localIp, '192.168.1.10');
    expect(session.port, greaterThan(0));
    expect(session.isHttps, isTrue);
    expect(session.url, 'https://192.168.1.10:${session.port}');
    expect(session.directConnect, 'https://192.168.1.10:${session.port}');
    expect(session.certFingerprint, isNotNull);
    expect(session.certFingerprint, matches(RegExp(r'^[0-9a-f]{64}$')));
    expect(
      session.qrCodeData,
      'https://192.168.1.10:${session.port}#sha256=${session.certFingerprint}',
    );
  });

  test('serves the embedded web client over TLS at GET /', () async {
    final session = await startHub();
    final response = await client.get(hubUri(session, '/'));

    expect(response.statusCode, 200);
    expect(response.body, '<html>guest</html>');
    expect(response.headers['content-type'], contains('text/html'));
  });

  test('serves the root CA at GET /ca.pem for guest trust', () async {
    final session = await startHub();
    final response = await client.get(hubUri(session, '/ca.pem'));

    expect(response.statusCode, 200);
    expect(response.body, contains('-----BEGIN CERTIFICATE-----'));
    expect(response.body, contains('-----END CERTIFICATE-----'));
    expect(response.headers['content-type'], contains('pem'));
  });

  test('rejects plain HTTP on the TLS port', () async {
    final session = await startHub();
    final plain = HttpClient();
    try {
      final request = await plain
          .getUrl(Uri.parse('http://127.0.0.1:${session.port}/'))
          .then((r) => r.close());
      fail('plain HTTP should not reach the TLS server, got: $request');
    } on HttpException {
      // Expected: the TLS server refuses a plaintext client.
    } on SocketException {
      // Also acceptable: connection closed/reset on plaintext.
    } finally {
      plain.close();
    }
  });

  test('starting the server clears the upload cache', () async {
    // A stale file from a previous session lives in the shared cache dir.
    final stale = File('${tempDir.path}/stale_upload.zip');
    await stale.writeAsString('leftover');
    expect(await stale.exists(), isTrue);

    final session = await startHub();

    expect(await stale.exists(), isFalse);

    final filesResponse = await client.get(hubUri(session, '/files'));
    expect(filesResponse.statusCode, 200);
    final filesJson = jsonDecode(filesResponse.body) as Map<String, dynamic>;
    expect(filesJson['files'], isEmpty);
  });

  test('ping registers the guest in the connected-client list', () async {
    final session = await startHub();
    final clientSnapshots = <List<ConnectedClient>>[];
    final subscription = transport.watchClients().listen(clientSnapshots.add);

    await client.get(hubUri(session, '/api/ping?client=NODE-X'));
    await Future<void>.delayed(Duration.zero);

    final latest = clientSnapshots.last;
    expect(latest.any((c) => c.name == 'NODE-X'), isTrue);
    expect(latest.any((c) => c.ipAddress == '127.0.0.1'), isTrue);

    await subscription.cancel();
  });

  test('upload persists the file, emits events and serves /files + /download',
      () async {
    final session = await startHub();
    final uri = hubUri(session, '/upload');

    final request = http.MultipartRequest('POST', uri);
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        utf8.encode('hello world'),
        filename: 'test.txt',
      ),
    );
    final response = await http.Response.fromStream(await client.send(request));
    expect(response.statusCode, 200);

    final saved = File('${tempDir.path}/test.txt');
    expect(await saved.exists(), isTrue);
    expect(await saved.readAsString(), 'hello world');

    await Future<void>.delayed(Duration.zero);
    expect(
      uploadEvents.any(
        (e) =>
            e.status == ServerUploadStatus.completed &&
            e.fileName == 'test.txt',
      ),
      isTrue,
    );

    final filesResponse = await client.get(hubUri(session, '/files'));
    expect(filesResponse.statusCode, 200);
    final filesJson = jsonDecode(filesResponse.body) as Map<String, dynamic>;
    final files = filesJson['files'] as List;
    expect(files.any((f) => (f as Map)['name'] == 'test.txt'), isTrue);

    final downloadResponse = await client.get(
      hubUri(session, '/download/test.txt'),
    );
    expect(downloadResponse.statusCode, 200);
    expect(downloadResponse.body, 'hello world');
  });

  test('sanitizes traversal-style upload names into the shared dir', () async {
    final session = await startHub();
    final request = http.MultipartRequest('POST', hubUri(session, '/upload'));
    request.files.add(
      http.MultipartFile.fromBytes('file', utf8.encode('x'), filename: '../../evil.txt'),
    );

    final response = await http.Response.fromStream(await client.send(request));
    expect(response.statusCode, 200);

    final savedFiles = tempDir.listSync().whereType<File>().toList();
    expect(savedFiles.length, 1);
    expect(File('${tempDir.parent.path}/evil.txt').existsSync(), isFalse);
  });

  test('download of a missing file returns 404', () async {
    final session = await startHub();
    final response = await client.get(hubUri(session, '/download/nope.txt'));

    expect(response.statusCode, 404);
  });

  test('stop flips the status stream to stopped', () async {
    await startHub();
    final statusSnapshots = <ServerSession>[];
    final subscription = transport.watchStatus().listen(statusSnapshots.add);

    await transport.stop();
    await Future<void>.delayed(Duration.zero);

    expect(statusSnapshots.last.status, ServerStatus.stopped);
    await subscription.cancel();
  });

  test('publishFiles copies host files into the hub and exposes them', () async {
    final session = await startHub();
    final source = File('${tempDir.path}/_source_deploy.zip');
    await source.writeAsBytes(utf8.encode('host payload'));

    final published = await transport.publishFiles(
      [
        HostPublishFile(name: 'deploy.zip', path: source.path, size: 12),
      ],
    );

    // The copy landed in the shared dir (not under the source name).
    expect(published.length, 1);
    expect(await File('${tempDir.path}/deploy.zip').exists(), isTrue);
    expect(
      await File('${tempDir.path}/deploy.zip').readAsString(),
      'host payload',
    );

    // A completed upload event surfaces for the HUD.
    await Future<void>.delayed(Duration.zero);
    expect(
      uploadEvents.any(
        (e) =>
            e.status == ServerUploadStatus.completed &&
            e.fileName == 'deploy.zip',
      ),
      isTrue,
    );

    // Guests can list the published asset.
    final filesResponse = await client.get(hubUri(session, '/files'));
    expect(filesResponse.statusCode, 200);
    final filesJson = jsonDecode(filesResponse.body) as Map<String, dynamic>;
    final files = filesJson['files'] as List;
    expect(files.any((f) => (f as Map)['name'] == 'deploy.zip'), isTrue);
  });

  test('downloadSharedFile stores the file through the media store', () async {
    await startHub();
    await File('${tempDir.path}/secret.txt').writeAsString('secret data');

    final downloaded = await transport.downloadSharedFile('secret.txt');

    expect(downloaded, isNotNull);
    expect(downloaded!.name, 'secret.txt');
    expect(downloaded.target, DownloadTarget.documents);
    expect(await File('${receivedDir.path}/secret.txt').exists(), isTrue);
    expect(
      await File('${receivedDir.path}/secret.txt').readAsString(),
      'secret data',
    );
  });

  test('downloadSharedFile returns null when the file is missing', () async {
    await startHub();
    final downloaded = await transport.downloadSharedFile('nope.txt');

    expect(downloaded, isNull);
  });
}
