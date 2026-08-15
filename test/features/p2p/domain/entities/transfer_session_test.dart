import 'package:blaze_drop/features/p2p/domain/entities/file_item.dart';
import 'package:blaze_drop/features/p2p/domain/entities/peer_device.dart';
import 'package:blaze_drop/features/p2p/domain/entities/transfer_session.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const peer = PeerDevice(
    id: 'node-1',
    name: 'ONYX_RIG',
    ipAddress: '192.168.1.45',
    servicePort: 43211,
  );

  const files = <FileItem>[
    FileItem(name: 'system_override.zip', path: '/tmp/x.zip', size: 420 * 1024 * 1024),
    FileItem(name: 'notes.md', path: '/tmp/notes.md', size: 12 * 1024 * 1024),
  ];

  group('TransferSession', () {
    test('computes speed label', () {
      final session = TransferSession(
        sessionId: 's-1',
        peer: peer,
        direction: TransferDirection.outgoing,
        files: files,
        speedBytesPerSecond: 45 * 1024 * 1024,
      );
      expect(session.speedLabel, '45.0 MB/s');
    });

    test('estimates remaining seconds from speed and remaining bytes', () {
      final session = TransferSession(
        sessionId: 's-2',
        peer: peer,
        direction: TransferDirection.incoming,
        files: files,
        bytesTotal: 432 * 1024 * 1024,
        bytesTransferred: 32 * 1024 * 1024,
        speedBytesPerSecond: 100 * 1024 * 1024,
      );
      expect(session.estimatedSecondsRemaining, 4);
    });

    test('returns 0 remaining time without speed or total', () {
      final session = TransferSession(
        sessionId: 's-3',
        peer: peer,
        direction: TransferDirection.outgoing,
        files: files,
      );
      expect(session.estimatedSecondsRemaining, 0);
    });

    test('copyWith preserves identity and overrides progress fields', () {
      final session = TransferSession(
        sessionId: 's-4',
        peer: peer,
        direction: TransferDirection.incoming,
        files: files,
        status: TransferStatus.transferring,
        bytesTotal: 432 * 1024 * 1024,
      );
      final updated = session.copyWith(
        status: TransferStatus.completed,
        progress: 1,
        bytesTransferred: 432 * 1024 * 1024,
      );
      expect(updated.sessionId, 's-4');
      expect(updated.peer, peer);
      expect(updated.direction, TransferDirection.incoming);
      expect(updated.status, TransferStatus.completed);
      expect(updated.progress, 1);
      expect(updated.bytesTransferred, 432 * 1024 * 1024);
    });
  });
}
