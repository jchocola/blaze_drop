import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/incoming_connection_request.dart';
import '../../domain/entities/peer_device.dart';
import '../../domain/entities/transfer_session.dart';
import '../../domain/exceptions/peer_transfer_exception.dart';
import '../models/peer_beacon.dart';
import 'peer_transport_data_source.dart';

/// Socket-based P2P transport (FUNCTIONALITY.md §4).
///
/// - **Discovery:** every node broadcasts a UDP JSON beacon on
///   [beaconPort]; peers are pruned after [peerTimeout] without a beacon.
/// - **Handshake:** a TCP connection is opened to the peer's advertised
///   service port; the receiver may accept/decline (auto-decline after
///   [requestTimeout]).
/// - **Transfer:** files are streamed in [chunkSize] chunks after a JSON
///   manifest. All frame payloads use newline-delimited UTF-8 JSON; file
///   bodies are raw bytes.
///
/// The same class runs on both devices — each node is simultaneously a
/// beaconing server and a connecting client.
class PeerTransportImpl implements PeerTransportDataSource {
  PeerTransportImpl({
    required String nodeId,
    required String nodeName,
    this.beaconPort = AppConstants.p2pBeaconPort,
    this.servicePort = AppConstants.p2pServicePort,
    List<InternetAddress>? discoveryTargets,
    this.chunkSize = AppConstants.p2pChunkSize,
    this.beaconInterval = AppConstants.p2pBeaconInterval,
    this.scanInterval = AppConstants.p2pScanInterval,
    this.peerTimeout = AppConstants.p2pPeerTimeout,
    this.requestTimeout = AppConstants.p2pRequestTimeout,
    Future<String> Function()? inboxDirectoryProvider,
  }) : _nodeId = nodeId,
       _nodeName = nodeName,
       _discoveryTargets =
           discoveryTargets ??
           <InternetAddress>[
             InternetAddress('255.255.255.255'),
             InternetAddress('127.0.0.1'),
           ],
       _inboxDirectoryProvider =
           inboxDirectoryProvider ?? _defaultInboxDirectory;

  final String _nodeId;
  final String _nodeName;
  final int beaconPort;
  final int servicePort;
  final int chunkSize;
  final Duration beaconInterval;
  final Duration scanInterval;
  final Duration peerTimeout;
  final Duration requestTimeout;
  final List<InternetAddress> _discoveryTargets;
  final Future<String> Function() _inboxDirectoryProvider;

  @override
  String get nodeId => _nodeId;

  // --- Discovery state -----------------------------------------------------
  RawDatagramSocket? _beaconSocket;
  ServerSocket? _serverSocket;
  Timer? _beaconTimer;
  Timer? _scanTimer;
  bool _discoveryStarted = false;
  final Map<String, PeerDevice> _peers = {};
  final Map<String, List<DateTime>> _beaconTimes = {};
  final _peersController = StreamController<List<PeerDevice>>.broadcast();

  // --- Connection state ----------------------------------------------------
  Socket? _incomingSocket;
  Completer<bool>? _incomingDecision;
  Timer? _requestTimer;
  Socket? _outgoingSocket;
  var _requestCounter = 0;
  final _incomingController =
      StreamController<IncomingConnectionRequest>.broadcast();
  final _transferController = StreamController<TransferSession>.broadcast();
  bool _disposed = false;

  // --- Discovery -----------------------------------------------------------

  @override
  Stream<List<PeerDevice>> watchPeers() => _peersController.stream;

  @override
  Future<void> startDiscovery() async {
    if (_discoveryStarted || _disposed) {
      return;
    }
    try {
      _beaconSocket = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        beaconPort,
        reuseAddress: true,
        reusePort: true,
      );
      // Dart 3+ no longer enables SO_BROADCAST on bind — without this flag the
      // send to the 255.255.255.255 broadcast address fails with
      // `SocketException: Send failed (OS Error: Permission denied, errno = 13)`
      // on Android/Linux, and Dart closes the socket afterwards.
      _beaconSocket!.broadcastEnabled = true;
      _beaconSocket!.listen(
        _onDatagram,
        onError: (Object error, StackTrace stack) {
          AppLogger.error('Beacon socket error', error, stack);
        },
      );
      await _bindServerSocket();
      _discoveryStarted = true;
      _beaconTimer = Timer.periodic(beaconInterval, (_) => _broadcastBeacon());
      _scanTimer = Timer.periodic(scanInterval, (_) => _emitPeers());
      _broadcastBeacon();
      _emitPeers();
      AppLogger.info(
        'P2P discovery started (beacon:$beaconPort, service:${_serverSocket?.port ?? servicePort})',
      );
    } catch (error, stack) {
      AppLogger.error('Failed to start P2P discovery', error, stack);
      await _closeSockets();
      rethrow;
    }
  }

  @override
  Future<void> stopDiscovery() async {
    _beaconTimer?.cancel();
    _beaconTimer = null;
    _scanTimer?.cancel();
    _scanTimer = null;
    _requestTimer?.cancel();
    _requestTimer = null;
    await _closeSockets();
    _discoveryStarted = false;
    _peers.clear();
    AppLogger.info('P2P discovery stopped');
  }

  Future<void> _closeSockets() async {
    _beaconSocket?.close();
    _beaconSocket = null;
    try {
      await _serverSocket?.close();
    } catch (_) {}
    _serverSocket = null;
  }

  void _broadcastBeacon() {
    final socket = _beaconSocket;
    if (socket == null) {
      return;
    }
    final beacon = PeerBeacon(
      nodeId: _nodeId,
      nodeName: _nodeName,
      servicePort: _serverSocket?.port ?? servicePort,
      platform: _localPlatformName(),
    );
    final payload = utf8.encode(jsonEncode(beacon.toJson()));
    for (final target in _discoveryTargets) {
      try {
        socket.send(payload, target, beaconPort);
      } catch (error) {
        AppLogger.warning('Beacon send to $target failed: $error');
      }
    }
  }

  void _onDatagram(RawSocketEvent event) {
    final socket = _beaconSocket;
    if (socket == null || event != RawSocketEvent.read) {
      return;
    }
    final datagram = socket.receive();
    if (datagram == null) {
      return;
    }
    Map<String, dynamic>? json;
    try {
      final decoded = jsonDecode(utf8.decode(datagram.data));
      if (decoded is Map<String, dynamic>) {
        json = decoded;
      }
    } catch (_) {
      return;
    }
    final beacon = PeerBeacon.fromJson(json ?? const {});
    if (beacon == null || beacon.nodeId == _nodeId) {
      return; // ignore self / malformed beacons.
    }
    final now = DateTime.now();
    _beaconTimes.putIfAbsent(beacon.nodeId, () => []).add(now);
    _peers[beacon.nodeId] = PeerDevice(
      id: beacon.nodeId,
      name: beacon.nodeName,
      ipAddress: datagram.address.address,
      servicePort: beacon.servicePort,
      platform: _platformFromString(beacon.platform),
      signalStrength: _signalStrength(beacon.nodeId, now),
      lastSeen: now,
    );
  }

  void _emitPeers() {
    if (_disposed || _peersController.isClosed) {
      return;
    }
    final now = DateTime.now();
    _peers.removeWhere((_, peer) {
      final last = peer.lastSeen;
      return last != null && now.difference(last) > peerTimeout;
    });
    final list = _peers.values
        .map(
          (peer) => peer.copyWith(
            signalStrength: _signalStrength(peer.id, now),
          ),
        )
        .toList()
      ..sort((a, b) => b.signalStrength.compareTo(a.signalStrength));
    _peersController.add(list);
  }

  /// Heuristic link-quality score (0..100) derived from beacon cadence
  /// consistency — beacons arriving at the expected [beaconInterval] score
  /// high; erratic arrivals score lower.
  int _signalStrength(String peerId, DateTime now) {
    final times = _beaconTimes.putIfAbsent(peerId, () => []);
    times.add(now);
    while (times.length > 8) {
      times.removeAt(0);
    }
    if (times.length < 2) {
      return 45;
    }
    final intervals = <int>[];
    for (var i = 1; i < times.length; i++) {
      intervals.add(times[i].difference(times[i - 1]).inMilliseconds);
    }
    intervals.sort();
    final median = intervals[intervals.length ~/ 2];
    final expected = beaconInterval.inMilliseconds;
    final deviation =
        ((median - expected).abs() / expected).clamp(0.0, 1.0).toDouble();
    final score = ((1 - deviation) * 100).round().clamp(5, 100);
    return score;
  }

  Future<void> _bindServerSocket() async {
    try {
      _serverSocket = await ServerSocket.bind(
        InternetAddress.anyIPv4,
        servicePort,
        shared: true,
      );
    } catch (_) {
      // Port busy → auto-assign (FUNCTIONALITY.md §8).
      _serverSocket = await ServerSocket.bind(InternetAddress.anyIPv4, 0);
    }
    _serverSocket!.listen(
      (socket) {
        unawaited(_handleIncoming(socket));
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('P2P server socket error', error, stack);
      },
    );
  }

  // --- Incoming connection + receive ---------------------------------------

  @override
  Stream<IncomingConnectionRequest> watchIncomingRequests() =>
      _incomingController.stream;

  @override
  Future<void> respondToRequest({required bool accept}) async {
    final decision = _incomingDecision;
    if (decision == null) {
      throw const PeerTransferException('No pending connection request');
    }
    if (!decision.isCompleted) {
      decision.complete(accept);
    }
  }

  Future<void> _handleIncoming(Socket socket) async {
    if (_incomingSocket != null) {
      // One active incoming transfer at a time.
      _tryWriteJson(socket, const {'type': 'busy'});
      socket.destroy();
      return;
    }
    _incomingSocket = socket;
    final reader = _SocketReader(socket);
    try {
      final hello = await _readControl(reader);
      if (hello['type'] != 'hello') {
        throw const FormatException('Expected hello frame');
      }
      final sender = PeerDevice(
        id: (hello['from'] as String?) ?? 'unknown',
        name: (hello['fromName'] as String?) ?? 'UNKNOWN_NODE',
        ipAddress: socket.remoteAddress.address,
        servicePort: (hello['fromPort'] as int?) ?? 0,
        lastSeen: DateTime.now(),
      );
      final files = _filesFromJson(hello['files']);
      final request = IncomingConnectionRequest(
        requestId: 'req-${++_requestCounter}',
        sender: sender,
        files: files,
        timeout: requestTimeout,
      );
      if (!_incomingController.isClosed) {
        _incomingController.add(request);
      }
      // Wait for the receiver's decision (accept / decline / auto-decline).
      final decision = Completer<bool>();
      _incomingDecision = decision;
      _requestTimer?.cancel();
      _requestTimer = Timer(requestTimeout, () {
        if (!decision.isCompleted) {
          decision.complete(false);
        }
      });
      final accept = await decision.future;
      _requestTimer?.cancel();
      _requestTimer = null;
      _incomingDecision = null;

      if (!accept) {
        _tryWriteJson(socket, const {'type': 'declined'});
        await socket.flush();
        _incomingSocket = null;
        await socket.close();
        return;
      }

      final sessionId = _generateId();
      _tryWriteJson(socket, {'type': 'accepted', 'sessionId': sessionId});
      await socket.flush();
      await _receiveFiles(socket, reader, request, sessionId);
    } catch (error, stack) {
      AppLogger.error('Incoming P2P connection failed', error, stack);
      socket.destroy();
      _incomingSocket = null;
      _incomingDecision = null;
      _requestTimer?.cancel();
      _requestTimer = null;
    }
  }

  Future<void> _receiveFiles(
    Socket socket,
    _SocketReader reader,
    IncomingConnectionRequest request,
    String sessionId,
  ) async {
    final peer = request.sender;
    final totalBytes = request.totalBytes;
    var session = TransferSession(
      sessionId: sessionId,
      peer: peer,
      direction: TransferDirection.incoming,
      files: request.files,
      status: TransferStatus.transferring,
      bytesTotal: totalBytes,
      timestamp: DateTime.now(),
    );
    _emitTransfer(session);

    final inbox = await _inboxDirectoryProvider();
    final completedFiles = <FileItem>[];
    var transferred = 0;
    var lastTick = DateTime.now();
    var lastBytes = 0;

    try {
      while (true) {
        final control = await _readControl(reader);
        final type = control['type'] as String;
        if (type == 'file_start') {
          final name = FileUtils.sanitizeFileName(control['name'] as String);
          final size = control['size'] as int? ?? 0;
          final mime = control['mime'] as String?;
          final path = await FileUtils.resolveUniquePath(inbox, name);
          final file = await File(path).open(mode: FileMode.write);
          var written = 0;
          try {
            while (written < size) {
              final want = math.min(chunkSize, size - written);
              final data = await reader.readBytes(want);
              if (data.isEmpty) {
                break;
              }
              await file.writeFrom(data);
              written += data.length;
              transferred += data.length;
              final now = DateTime.now();
              final elapsed = now.difference(lastTick).inMilliseconds;
              if (elapsed >= 100) {
                final speed =
                    ((transferred - lastBytes) / elapsed * 1000).round();
                lastTick = now;
                lastBytes = transferred;
                session = session.copyWith(
                  bytesTransferred: transferred,
                  speedBytesPerSecond: speed,
                  progress: totalBytes == 0
                      ? 0
                      : (transferred / totalBytes).clamp(0.0, 1.0),
                );
                _emitTransfer(session);
              }
            }
          } finally {
            await file.flush();
            await file.close();
          }
          completedFiles.add(
            FileItem(name: name, path: path, size: written, mimeType: mime),
          );
        } else if (type == 'transfer_done') {
          break;
        }
      }
      final done = session.copyWith(
        status: TransferStatus.completed,
        progress: 1,
        bytesTransferred: transferred,
        bytesTotal: totalBytes,
        speedBytesPerSecond: 0,
        files: completedFiles,
      );
      _emitTransfer(done);
      AppLogger.info(
        'Received ${completedFiles.length} file(s) (${formatBytes(transferred)})',
      );
    } catch (error, stack) {
      AppLogger.error('P2P receive failed', error, stack);
      _emitTransfer(
        session.copyWith(
          status: TransferStatus.failed,
          error: error.toString(),
        ),
      );
    } finally {
      _incomingSocket = null;
      socket.destroy();
    }
  }

  // --- Outgoing send --------------------------------------------------------

  @override
  Future<TransferSession> sendFiles(
    PeerDevice peer,
    List<FileItem> files, {
    void Function(int transferred, int total)? onProgress,
  }) async {
    if (files.isEmpty) {
      throw const PeerTransferException('No files selected');
    }
    var session = TransferSession(
      sessionId: _generateId(),
      peer: peer,
      direction: TransferDirection.outgoing,
      files: files,
      status: TransferStatus.transferring,
      bytesTotal: files.fold(0, (sum, f) => sum + f.size),
      timestamp: DateTime.now(),
    );
    _emitTransfer(session);
    Socket? socket;
    try {
      socket = await Socket.connect(
        peer.ipAddress,
        peer.servicePort,
        timeout: requestTimeout,
      );
      _outgoingSocket = socket;
      final reader = _SocketReader(socket);

      // Handshake: send manifest, wait for accept/decline.
      _tryWriteJson(socket, {
        'type': 'hello',
        'from': _nodeId,
        'fromName': _nodeName,
        'fromPort': _serverSocket?.port ?? servicePort,
        'files': files
            .map(
              (f) => {
                'name': f.name,
                'size': f.size,
                'mime': f.mimeType ?? FileUtils.mimeTypeForName(f.name),
              },
            )
            .toList(),
      });
      await socket.flush();

      final response = await _readControl(reader);
      final responseType = response['type'] as String?;
      if (responseType == 'declined') {
        throw const PeerTransferException('Connection declined by peer');
      }
      if (responseType != 'accepted') {
        throw const FormatException('Unexpected handshake response');
      }
      session = session.copyWith(
        sessionId: response['sessionId'] as String? ?? session.sessionId,
      );
      _emitTransfer(session);

      var transferred = 0;
      var lastTick = DateTime.now();
      var lastBytes = 0;
      for (final file in files) {
        _tryWriteJson(socket, {
          'type': 'file_start',
          'name': file.name,
          'size': file.size,
          'mime': file.mimeType ?? FileUtils.mimeTypeForName(file.name),
        });
        await socket.flush();

        final raf = await File(file.path).open();
        var sent = 0;
        try {
          while (sent < file.size) {
            final want = math.min(chunkSize, file.size - sent);
            final chunk = await raf.read(want);
            if (chunk.isEmpty) {
              break;
            }
            socket.add(chunk);
            await socket.flush();
            sent += chunk.length;
            transferred += chunk.length;
            final now = DateTime.now();
            final elapsed = now.difference(lastTick).inMilliseconds;
            if (elapsed >= 100) {
              final speed =
                  ((transferred - lastBytes) / elapsed * 1000).round();
              lastTick = now;
              lastBytes = transferred;
              session = session.copyWith(
                bytesTransferred: transferred,
                speedBytesPerSecond: speed,
                progress: session.bytesTotal == 0
                    ? 0
                    : (transferred / session.bytesTotal).clamp(0.0, 1.0),
              );
              onProgress?.call(transferred, session.bytesTotal);
              _emitTransfer(session);
            }
          }
        } finally {
          await raf.close();
        }
      }

      _tryWriteJson(socket, const {'type': 'transfer_done'});
      await socket.flush();
      final done = session.copyWith(
        status: TransferStatus.completed,
        progress: 1,
        bytesTransferred: transferred,
        speedBytesPerSecond: 0,
      );
      onProgress?.call(transferred, done.bytesTotal);
      _emitTransfer(done);
      AppLogger.info(
        'Sent ${files.length} file(s) (${formatBytes(transferred)}) to ${peer.name}',
      );
      return done;
    } catch (error, stack) {
      AppLogger.error('P2P send failed', error, stack);
      final failed = session.copyWith(
        status: TransferStatus.failed,
        error: error.toString(),
      );
      _emitTransfer(failed);
      if (error is PeerTransferException) {
        rethrow;
      }
      throw PeerTransferException('Transfer failed: $error');
    } finally {
      _outgoingSocket = null;
      socket?.destroy();
    }
  }

  // --- Streams / helpers -----------------------------------------------------

  @override
  Stream<TransferSession> watchTransferUpdates() => _transferController.stream;

  void _emitTransfer(TransferSession session) {
    if (!_disposed && !_transferController.isClosed) {
      _transferController.add(session);
    }
  }

  void _tryWriteJson(Socket socket, Map<String, dynamic> json) {
    socket.write('${jsonEncode(json)}\n');
  }

  Future<Map<String, dynamic>> _readControl(_SocketReader reader) async {
    final line = await reader.readLine();
    final decoded = jsonDecode(line);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Expected JSON control frame');
    }
    return decoded;
  }

  List<FileItem> _filesFromJson(Object? raw) {
    if (raw is! List) {
      return const [];
    }
    final files = <FileItem>[];
    for (final item in raw) {
      if (item is! Map<String, dynamic>) {
        continue;
      }
      final name = item['name'] as String? ?? 'file';
      final size = item['size'] as int? ?? 0;
      final mime = item['mime'] as String?;
      files.add(
        FileItem(name: name, path: '', size: size, mimeType: mime),
      );
    }
    return files;
  }

  PeerPlatform _platformFromString(String value) {
    switch (value) {
      case 'android':
        return PeerPlatform.android;
      case 'ios':
        return PeerPlatform.ios;
      case 'windows':
        return PeerPlatform.windows;
      case 'macos':
        return PeerPlatform.macos;
      case 'linux':
        return PeerPlatform.linux;
      default:
        return PeerPlatform.other;
    }
  }

  String _localPlatformName() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'android';
      case TargetPlatform.iOS:
        return 'ios';
      case TargetPlatform.windows:
        return 'windows';
      case TargetPlatform.macOS:
        return 'macos';
      case TargetPlatform.linux:
        return 'linux';
      default:
        return 'other';
    }
  }

  String _generateId() {
    final random = math.Random.secure();
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final suffix = random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '$time-$suffix';
  }

  static Future<String> _defaultInboxDirectory() =>
      Directory.systemTemp.createTemp('blazedrop').then((d) => d.path);

  @override
  Future<void> dispose() async {
    _disposed = true;
    _beaconTimer?.cancel();
    _scanTimer?.cancel();
    _requestTimer?.cancel();
    await _closeSockets();
    _incomingSocket?.destroy();
    _incomingSocket = null;
    _outgoingSocket?.destroy();
    _outgoingSocket = null;
    await _peersController.close();
    await _incomingController.close();
    await _transferController.close();
  }
}

/// Buffered reader over a [Socket] that can read newline-delimited UTF-8
/// control lines and exact-size binary chunks.
class _SocketReader {
  _SocketReader(this._socket) {
    _socket.listen(
      _onData,
      onDone: _onDone,
      onError: (Object _) => _onDone(),
      cancelOnError: true,
    );
  }

  final Socket _socket;
  final List<int> _buffer = [];
  var _start = 0;
  Completer<void>? _pending;
  var _done = false;

  void _onData(List<int> data) {
    _buffer.addAll(data);
    _wake();
  }

  void _onDone() {
    _done = true;
    _wake();
  }

  void _wake() {
    final pending = _pending;
    _pending = null;
    pending?.complete();
  }

  List<int> _available() => _buffer.sublist(_start);

  List<int> _consume(int count) {
    final out = _buffer.sublist(_start, _start + count);
    _start += count;
    if (_start > 8192 && _start * 2 > _buffer.length) {
      _buffer.removeRange(0, _start);
      _start = 0;
    }
    return out;
  }

  Future<void> _wait() async {
    if (_available().isNotEmpty || _done) {
      return;
    }
    final completer = Completer<void>();
    _pending = completer;
    await completer.future;
  }

  Future<String> readLine() async {
    final line = <int>[];
    while (true) {
      final available = _available();
      final newline = available.indexOf(0x0A);
      if (newline >= 0) {
        line.addAll(_consume(newline));
        _consume(1); // trailing newline.
        return utf8.decode(line);
      }
      line.addAll(_consume(available.length));
      if (_done) {
        throw const SocketException('Peer closed the connection');
      }
      await _wait();
    }
  }

  Future<List<int>> readBytes(int count) async {
    final out = <int>[];
    while (out.length < count) {
      final available = _available();
      final take = math.min(available.length, count - out.length);
      if (take > 0) {
        out.addAll(_consume(take));
      }
      if (out.length >= count) {
        break;
      }
      if (_done) {
        throw const SocketException('Peer closed mid-transfer');
      }
      await _wait();
    }
    return out;
  }
}
