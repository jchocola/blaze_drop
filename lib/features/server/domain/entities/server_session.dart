import 'package:equatable/equatable.dart';

/// Lifecycle of the local relay hub.
enum ServerStatus {
  /// Not running.
  idle,

  /// Binding sockets / resolving the local IP.
  starting,

  /// Actively serving the web client on [ServerSession.port].
  active,

  /// Stopped (explicitly or because the transport was torn down).
  stopped,
}

/// Snapshot of the running relay hub (FUNCTIONALITY.md §5.1 / §5.2).
///
/// Domain-level model — no `shelf`/`dart:io` types leak into this layer.
class ServerSession extends Equatable {
  const ServerSession({
    this.status = ServerStatus.idle,
    this.port = 0,
    this.localIp = '',
    this.startedAt,
  });

  final ServerStatus status;

  /// Port the hub is (or was) listening on.
  final int port;

  /// IPv4 address of this host on the local network.
  final String localIp;

  final DateTime? startedAt;

  /// Direct-connect URL advertised via the QR beacon, e.g.
  /// `http://192.168.1.10:8080`.
  String get url =>
      (localIp.isEmpty || port == 0) ? '' : 'http://$localIp:$port';

  /// Raw `tcp://ip:port` form shown on the "DIRECT CONNECT IP" readout.
  String get directConnect =>
      (localIp.isEmpty || port == 0) ? '' : 'tcp://$localIp:$port';

  bool get isActive => status == ServerStatus.active;

  ServerSession copyWith({
    ServerStatus? status,
    int? port,
    String? localIp,
    DateTime? startedAt,
  }) {
    return ServerSession(
      status: status ?? this.status,
      port: port ?? this.port,
      localIp: localIp ?? this.localIp,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  List<Object?> get props => [status, port, localIp, startedAt];
}
