import 'dart:convert';
import 'dart:io';

import 'package:blaze_drop/features/p2p/data/datasources/peer_transport_impl.dart';
import 'package:blaze_drop/features/p2p/domain/entities/file_item.dart';
import 'package:blaze_drop/features/p2p/domain/entities/incoming_connection_request.dart';
import 'package:blaze_drop/features/p2p/domain/entities/peer_device.dart';
import 'package:blaze_drop/features/p2p/domain/entities/transfer_session.dart';
import 'package:blaze_drop/features/p2p/domain/exceptions/peer_transfer_exception.dart';
import 'package:flutter_test/flutter_test.dart';

/// Polls [condition] until it is true or [timeout] elapses.
Future<void> waitUntil(
  bool Function() condition, {
  Duration timeout = const Duration(seconds: 5),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) {
      fail('Condition not met within ${timeout.inSeconds}s');
    }
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
}

void main() {
  group('PeerTransportImpl discovery', () {
    test('detects a beacon, reports the peer and prunes it when stale', () async {
      final transport = PeerTransportImpl(
        nodeId: 'node-a',
        nodeName: 'ALPHA',
        beaconPort: 45210,
        servicePort: 0,
        discoveryTargets: <InternetAddress>[
          InternetAddress('127.0.0.1'),
        ],
        beaconInterval: const Duration(milliseconds: 30),
        scanInterval: const Duration(milliseconds: 50),
        peerTimeout: const Duration(milliseconds: 200),
      );
      await transport.startDiscovery();
      addTearDown(transport.dispose);

      final snapshots = <List<PeerDevice>>[];
      final sub = transport.watchPeers().listen(snapshots.add);
      addTearDown(sub.cancel);

      // A raw UDP socket impersonates a second node "BRAVO".
      final beacon = utf8.encode(
        jsonEncode({
          'v': 1,
          'id': 'node-b',
          'name': 'BRAVO',
          'port': 45299,
          'platform': 'android',
        }),
      );
      final sender = await RawDatagramSocket.bind(
        InternetAddress.loopbackIPv4,
        0,
      );
      sender.send(beacon, InternetAddress.loopbackIPv4, 45210);

      await waitUntil(
        () => snapshots.isNotEmpty && snapshots.last.any((p) => p.id == 'node-b'),
      );

      final bravo = snapshots.last.firstWhere((p) => p.id == 'node-b');
      expect(bravo.name, 'BRAVO');
      expect(bravo.ipAddress, '127.0.0.1');
      expect(bravo.servicePort, 45299);
      expect(bravo.platform, PeerPlatform.android);

      // With no further beacons the peer is pruned after peerTimeout.
      await waitUntil(
        () =>
            snapshots.isNotEmpty &&
            snapshots.last.where((p) => p.id == 'node-b').isEmpty,
        timeout: const Duration(seconds: 3),
      );

      sender.close();
    });
  });

  group('PeerTransportImpl handshake + transfer', () {
    late Directory dirA;
    late Directory dirB;

    setUp(() {
      dirA = Directory.systemTemp.createTempSync('blazedrop_send');
      dirB = Directory.systemTemp.createTempSync('blazedrop_inbox');
    });

    tearDown(() {
      if (dirA.existsSync()) {
        dirA.deleteSync(recursive: true);
      }
      if (dirB.existsSync()) {
        dirB.deleteSync(recursive: true);
      }
    });

    (PeerTransportImpl, PeerTransportImpl) buildPair({
      Duration requestTimeout = const Duration(seconds: 30),
    }) {
      final a = PeerTransportImpl(
        nodeId: 'node-a',
        nodeName: 'ALPHA',
        beaconPort: 45220,
        servicePort: 45230,
        discoveryTargets: const [],
        chunkSize: 64 * 1024,
        requestTimeout: requestTimeout,
      );
      final b = PeerTransportImpl(
        nodeId: 'node-b',
        nodeName: 'BRAVO',
        beaconPort: 45221,
        servicePort: 45231,
        discoveryTargets: const [],
        chunkSize: 64 * 1024,
        requestTimeout: requestTimeout,
        inboxDirectoryProvider: () async => dirB.path,
      );
      return (a, b);
    }

    test('accepts the request and transfers the file intact', () async {
      final content = List<int>.generate(
        300 * 1024,
        (i) => (i * 7) % 256,
      ); // ~300 KB, exercises multiple chunks.
      final source = File('${dirA.path}/payload.dat')
        ..writeAsBytesSync(content);

      final (a, b) = buildPair();
      await a.startDiscovery();
      await b.startDiscovery();
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      final incoming = <IncomingConnectionRequest>[];
      final incomingSub = b.watchIncomingRequests().listen(incoming.add);
      addTearDown(incomingSub.cancel);
      final transfersB = <TransferSession>[];
      final transferSub = b.watchTransferUpdates().listen(transfersB.add);
      addTearDown(transferSub.cancel);

      const peerB = PeerDevice(
        id: 'node-b',
        name: 'BRAVO',
        ipAddress: '127.0.0.1',
        servicePort: 45231,
      );

      final sendFuture = a.sendFiles(
        peerB,
        [
          FileItem(
            name: 'payload.dat',
            path: source.path,
            size: content.length,
            mimeType: 'application/octet-stream',
          ),
        ],
      );

      await waitUntil(() => incoming.isNotEmpty);
      expect(incoming.single.sender.name, 'ALPHA');
      expect(incoming.single.totalBytes, content.length);

      await b.respondToRequest(accept: true);

      final session = await sendFuture.timeout(const Duration(seconds: 5));
      expect(session.status, TransferStatus.completed);
      expect(session.bytesTransferred, content.length);

      await waitUntil(
        () => transfersB.any((t) => t.status == TransferStatus.completed),
      );
      final saved = File('${dirB.path}/payload.dat');
      expect(saved.existsSync(), isTrue);
      expect(saved.readAsBytesSync(), content);
    });

    test('auto-declines on timeout when the receiver never answers', () async {
      final content = List<int>.generate(4096, (i) => i % 251);
      final source = File('${dirA.path}/p.bin')..writeAsBytesSync(content);

      final (a, b) = buildPair(
        requestTimeout: const Duration(milliseconds: 500),
      );
      await a.startDiscovery();
      await b.startDiscovery();
      addTearDown(a.dispose);
      addTearDown(b.dispose);

      final incoming = <IncomingConnectionRequest>[];
      final incomingSub = b.watchIncomingRequests().listen(incoming.add);
      addTearDown(incomingSub.cancel);

      const peerB = PeerDevice(
        id: 'node-b',
        name: 'BRAVO',
        ipAddress: '127.0.0.1',
        servicePort: 45231,
      );
      final sendFuture = a.sendFiles(
        peerB,
        [FileItem(name: 'p.bin', path: source.path, size: content.length)],
      );

      await waitUntil(() => incoming.isNotEmpty);
      // Do not answer — the transport request timer should auto-decline.
      await expectLater(sendFuture, throwsA(isA<PeerTransferException>()));
    });
  });
}
