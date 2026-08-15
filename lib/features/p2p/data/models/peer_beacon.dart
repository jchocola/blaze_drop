/// A UDP discovery beacon broadcast by every node on the LAN
/// (FUNCTIONALITY.md §4.1).
///
/// The receiver uses the UDP datagram's source address as the peer IP, so the
/// beacon only needs identity + service-port information.
class PeerBeacon {
  const PeerBeacon({
    required this.nodeId,
    required this.nodeName,
    required this.servicePort,
    this.platform = 'other',
  });

  /// Version of the beacon protocol.
  static const int protocolVersion = 1;

  final String nodeId;
  final String nodeName;
  final int servicePort;
  final String platform;

  Map<String, dynamic> toJson() => {
    'v': protocolVersion,
    'id': nodeId,
    'name': nodeName,
    'port': servicePort,
    'platform': platform,
  };

  /// Returns `null` for malformed / unknown-version beacons.
  static PeerBeacon? fromJson(Map<String, dynamic> json) {
    final version = json['v'];
    if (version != protocolVersion) {
      return null;
    }
    final id = json['id'];
    final name = json['name'];
    final port = json['port'];
    if (id is! String || name is! String || port is! int) {
      return null;
    }
    return PeerBeacon(
      nodeId: id,
      nodeName: name,
      servicePort: port,
      platform: json['platform'] is String ? json['platform'] as String : 'other',
    );
  }
}
