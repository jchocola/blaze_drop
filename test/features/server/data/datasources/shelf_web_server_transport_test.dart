import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:blaze_drop/features/server/data/datasources/local_ip_resolver.dart';
import 'package:blaze_drop/features/server/data/datasources/shelf_web_server_transport.dart';
import 'package:blaze_drop/features/server/data/datasources/web_client_assets.dart';
import 'package:blaze_drop/features/server/domain/entities/connected_client.dart';
import 'package:blaze_drop/features/server/domain/entities/server_session.dart';
import 'package:blaze_drop/features/server/domain/entities/server_upload_event.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

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

void main() {
  late ShelfWebServerTransport transport;
  late Directory tempDir;
  late List<ServerUploadEvent> uploadEvents;
  late StreamSubscription<ServerUploadEvent> uploadSubscription;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('blazedrop_server_test');
    transport = ShelfWebServerTransport(
      ipResolver: const _FakeIpResolver('192.168.1.10'),
      assets: const _FakeAssets(
        html: '<html>guest</html>',
        css: 'body{}',
        js: 'console.log(1);',
      ),
      sharedDirectoryProvider: () async => tempDir.path,
      clientTimeout: const Duration(seconds: 5),
    );
    uploadEvents = [];
    uploadSubscription = transport.watchUploads().listen(uploadEvents.add);
  });

  tearDown(() async {
    await uploadSubscription.cancel();
    await transport.dispose();
    await tempDir.delete(recursive: true);
  });

  Future<ServerSession> startHub() =>
      transport.start(preferredPort: 0, sessionTimeoutMinutes: 15);

  Uri hubUri(ServerSession session, String path) =>
      Uri.parse('http://127.0.0.1:${session.port}$path');

  test('starts on a free port and exposes the resolved IP/URL', () async {
    final session = await startHub();

    expect(session.status, ServerStatus.active);
    expect(session.localIp, '192.168.1.10');
    expect(session.port, greaterThan(0));
    expect(session.url, 'http://192.168.1.10:${session.port}');
    expect(session.directConnect, 'tcp://192.168.1.10:${session.port}');
  });

  test('serves the embedded web client at GET /', () async {
    final session = await startHub();
    final response = await http.get(hubUri(session, '/'));

    expect(response.statusCode, 200);
    expect(response.body, '<html>guest</html>');
    expect(response.headers['content-type'], contains('text/html'));
  });

  test('ping registers the guest in the connected-client list', () async {
    final session = await startHub();
    final clientSnapshots = <List<ConnectedClient>>[];
    final subscription = transport.watchClients().listen(clientSnapshots.add);

    await http.get(hubUri(session, '/api/ping?client=NODE-X'));
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
    final response = await http.Response.fromStream(await request.send());
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

    final filesResponse = await http.get(hubUri(session, '/files'));
    expect(filesResponse.statusCode, 200);
    final filesJson = jsonDecode(filesResponse.body) as Map<String, dynamic>;
    final files = filesJson['files'] as List;
    expect(
      files.any((f) => (f as Map)['name'] == 'test.txt'),
      isTrue,
    );

    final downloadResponse = await http.get(
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

    final response = await http.Response.fromStream(await request.send());
    expect(response.statusCode, 200);

    final savedFiles = tempDir.listSync().whereType<File>().toList();
    expect(savedFiles.length, 1);
    expect(File('${tempDir.parent.path}/evil.txt').existsSync(), isFalse);
  });

  test('download of a missing file returns 404', () async {
    final session = await startHub();
    final response = await http.get(hubUri(session, '/download/nope.txt'));

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
}
