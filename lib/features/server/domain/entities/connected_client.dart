import 'package:equatable/equatable.dart';

/// Current activity of a connected guest.
enum ClientConnectionState {
  /// Connected but not transferring.
  idle,

  /// Mid-upload.
  syncing,
}

/// A guest device currently connected to the local relay hub
/// (FUNCTIONALITY.md §5.4 "Connected Clients").
class ConnectedClient extends Equatable {
  const ConnectedClient({
    required this.id,
    required this.name,
    required this.ipAddress,
    this.state = ClientConnectionState.idle,
    this.lastSeen,
    this.userAgent = '',
  });

  /// Stable key (the guest's remote IP).
  final String id;

  /// Codename reported by the guest web client (e.g. `NODE-ALPHA-9`).
  final String name;

  final String ipAddress;

  final ClientConnectionState state;

  /// Last time the guest pinged the hub.
  final DateTime? lastSeen;

  /// Browser user-agent (debug aid).
  final String userAgent;

  ConnectedClient copyWith({
    String? name,
    ClientConnectionState? state,
    DateTime? lastSeen,
    String? userAgent,
  }) {
    return ConnectedClient(
      id: id,
      name: name ?? this.name,
      ipAddress: ipAddress,
      state: state ?? this.state,
      lastSeen: lastSeen ?? this.lastSeen,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  @override
  List<Object?> get props => [id, name, ipAddress, state, lastSeen, userAgent];
}
