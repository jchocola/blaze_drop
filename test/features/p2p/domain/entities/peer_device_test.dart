import 'package:blaze_drop/features/p2p/domain/entities/peer_device.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PeerDevice', () {
    const peer = PeerDevice(
      id: 'node-1',
      name: 'NEXUS_NODE_09',
      ipAddress: '192.168.1.10',
      servicePort: 43211,
      platform: PeerPlatform.android,
      signalStrength: 88,
    );

    test('derives initials from underscore-separated words', () {
      expect(peer.initials, 'NN');
    });

    test('derives initials for single-word names', () {
      const single = PeerDevice(
        id: 'node-2',
        name: 'Pixel',
        ipAddress: '192.168.1.11',
        servicePort: 43211,
      );
      expect(single.initials, 'PI');
    });

    test('copyWith preserves identity and overrides selected fields', () {
      final updated = peer.copyWith(
        signalStrength: 40,
        isConnected: true,
        lastSeen: DateTime(2026),
      );
      expect(updated.id, 'node-1');
      expect(updated.name, 'NEXUS_NODE_09');
      expect(updated.signalStrength, 40);
      expect(updated.isConnected, isTrue);
      expect(updated.lastSeen, DateTime(2026));
      expect(updated.platform, PeerPlatform.android);
    });

    test('defaults to other platform, 0 strength and not connected', () {
      const fresh = PeerDevice(
        id: 'node-3',
        name: 'X',
        ipAddress: '10.0.0.2',
        servicePort: 43211,
      );
      expect(fresh.platform, PeerPlatform.other);
      expect(fresh.signalStrength, 0);
      expect(fresh.isConnected, isFalse);
      expect(fresh.isSelf, isFalse);
    });
  });
}
