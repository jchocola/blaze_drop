import 'package:blaze_drop/features/p2p/domain/entities/file_item.dart';
import 'package:blaze_drop/features/p2p/domain/entities/incoming_connection_request.dart';
import 'package:blaze_drop/features/p2p/domain/entities/peer_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const sender = PeerDevice(
    id: 'node-1',
    name: 'NEXUS_NODE_09',
    ipAddress: '192.168.1.10',
    servicePort: 43211,
  );

  const files = <FileItem>[
    FileItem(name: 'encrypted_keys_v2.dat', path: '', size: 14 * 1024 * 1024),
    FileItem(
      name: 'project_x_assets.zip',
      path: '',
      size: 890 * 1024 * 1024,
    ),
    FileItem(name: 'schematic_final.png', path: '', size: 4 * 1024 * 1024),
  ];

  group('IncomingConnectionRequest', () {
    test('sums the payload manifest size', () {
      final request = IncomingConnectionRequest(
        requestId: 'req-1',
        sender: sender,
        files: files,
        receivedAt: DateTime(2026),
      );
      expect(request.totalBytes, 908 * 1024 * 1024);
      expect(request.files, hasLength(3));
    });

    test('defaults receivedAt to now and timeout to 30s', () {
      final request = IncomingConnectionRequest(
        requestId: 'req-2',
        sender: sender,
      );
      expect(request.timeout, const Duration(seconds: 30));
      expect(
        request.receivedAt.isBefore(DateTime.now()),
        isTrue,
      );
      expect(
        request.expiresAt,
        request.receivedAt.add(const Duration(seconds: 30)),
      );
    });

    test('reports expiry for past deadlines', () {
      final request = IncomingConnectionRequest(
        requestId: 'req-3',
        sender: sender,
        files: files,
        receivedAt: DateTime.now().subtract(const Duration(seconds: 31)),
      );
      expect(request.isExpired, isTrue);
      expect(request.remainingSeconds, 0);
    });

    test('is not expired while within the window', () {
      final request = IncomingConnectionRequest(
        requestId: 'req-4',
        sender: sender,
        files: files,
        receivedAt: DateTime.now(),
      );
      expect(request.isExpired, isFalse);
      expect(request.remainingSeconds, greaterThan(0));
    });

    test('equality considers identity, sender, files and timing', () {
      final a = IncomingConnectionRequest(
        requestId: 'req-5',
        sender: sender,
        files: files,
        receivedAt: DateTime(2026),
      );
      final b = IncomingConnectionRequest(
        requestId: 'req-5',
        sender: sender,
        files: files,
        receivedAt: DateTime(2026),
      );
      expect(a, b);
    });
  });
}
