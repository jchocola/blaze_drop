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
    this.isHttps = true,
    this.certFingerprint,
  });

  final ServerStatus status;

  /// Port the hub is (or was) listening on.
  final int port;

  /// IPv4 address of this host on the local network.
  final String localIp;

  final DateTime? startedAt;

  /// Whether the hub serves HTTPS (self-signed TLS). HTTPS is non-negotiable
  /// per FUNCTIONALITY.md §7.
  final bool isHttps;

  /// Lowercase hex SHA-256 fingerprint of the served certificate. Used for
  /// the QR beacon so guests can verify they reached the right host
  /// (FUNCTIONALITY.md §7 "the app validates the checksum").
  final String? certFingerprint;

  String get _scheme => isHttps ? 'https' : 'http';

  /// Direct-connect URL advertised via the QR beacon, e.g.
  /// `https://192.168.1.10:8080`.
  String get url =>
      (localIp.isEmpty || port == 0) ? '' : '$_scheme://$localIp:$port';

  /// Browser-openable `https://ip:port` form shown on the "DIRECT CONNECT IP"
  /// readout (guests connect via HTTPS, not a raw TCP socket).
  String get directConnect =>
      (localIp.isEmpty || port == 0) ? '' : '$_scheme://$localIp:$port';

  /// QR beacon payload: the HTTPS URL plus the certificate fingerprint in the
  /// fragment so a guest can pin the identity it just connected to.
  String get qrCodeData {
    final base = url;
    if (base.isEmpty) {
      return '';
    }
    final fingerprint = certFingerprint;
    return (fingerprint == null || fingerprint.isEmpty)
        ? base
        : '$base#sha256=$fingerprint';
  }

  bool get isActive => status == ServerStatus.active;

  ServerSession copyWith({
    ServerStatus? status,
    int? port,
    String? localIp,
    DateTime? startedAt,
    bool? isHttps,
    String? certFingerprint,
  }) {
    return ServerSession(
      status: status ?? this.status,
      port: port ?? this.port,
      localIp: localIp ?? this.localIp,
      startedAt: startedAt ?? this.startedAt,
      isHttps: isHttps ?? this.isHttps,
      certFingerprint: certFingerprint ?? this.certFingerprint,
    );
  }

  @override
  List<Object?> get props => [
    status,
    port,
    localIp,
    startedAt,
    isHttps,
    certFingerprint,
  ];
}
