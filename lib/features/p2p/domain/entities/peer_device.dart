import 'package:equatable/equatable.dart';

/// Logical platform of a discovered node.
enum PeerPlatform { android, ios, windows, macos, linux, other }

/// A node discovered on the local network (FUNCTIONALITY.md §4.1).
///
/// Domain-level model: no plugin types leak into this layer.
class PeerDevice extends Equatable {
  const PeerDevice({
    required this.id,
    required this.name,
    required this.ipAddress,
    required this.servicePort,
    this.platform = PeerPlatform.other,
    this.signalStrength = 0,
    this.lastSeen,
    this.isConnected = false,
    this.isSelf = false,
  });

  /// Unique node id (from the discovery beacon).
  final String id;

  /// Human-readable device name (e.g. `NEXUS_NODE_09`).
  final String name;

  /// IPv4 address on the local network.
  final String ipAddress;

  /// TCP port the peer listens on for handshakes/transfers.
  final int servicePort;

  final PeerPlatform platform;

  /// Estimated link quality, 0..100.
  final int signalStrength;

  /// Timestamp of the last received beacon (used for stale pruning).
  final DateTime? lastSeen;

  final bool isConnected;

  /// True when this entry represents the local node itself.
  final bool isSelf;

  /// Initials used for the generated avatar (e.g. `NN` for NEXUS_NODE_09).
  String get initials {
    final parts = name
        .split(RegExp(r'[\s_-]+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return '?';
    }
    if (parts.length == 1) {
      final part = parts.first;
      return part.length > 1
          ? part.substring(0, 2).toUpperCase()
          : part.toUpperCase();
    }
    // Head letter + the first alphabetic tail letter (skip numeric segments
    // such as the `09` in `NEXUS_NODE_09`).
    final head = parts.first[0];
    var tail = parts.last[0];
    for (final part in parts.skip(1)) {
      if (RegExp(r'[A-Za-z]').hasMatch(part[0])) {
        tail = part[0];
        break;
      }
    }
    return '$head$tail'.toUpperCase();
  }

  PeerDevice copyWith({
    String? name,
    String? ipAddress,
    int? servicePort,
    PeerPlatform? platform,
    int? signalStrength,
    DateTime? lastSeen,
    bool? isConnected,
    bool? isSelf,
  }) {
    return PeerDevice(
      id: id,
      name: name ?? this.name,
      ipAddress: ipAddress ?? this.ipAddress,
      servicePort: servicePort ?? this.servicePort,
      platform: platform ?? this.platform,
      signalStrength: signalStrength ?? this.signalStrength,
      lastSeen: lastSeen ?? this.lastSeen,
      isConnected: isConnected ?? this.isConnected,
      isSelf: isSelf ?? this.isSelf,
    );
  }

  @override
  List<Object?> get props => [
    id,
    name,
    ipAddress,
    servicePort,
    platform,
    signalStrength,
    lastSeen,
    isConnected,
    isSelf,
  ];
}
