import 'package:equatable/equatable.dart';

import 'file_item.dart';
import 'peer_device.dart';

/// An incoming connection request shown as a full-screen overlay
/// (FUNCTIONALITY.md §4.2).
///
/// The request carries a payload manifest so the receiver can decide whether
/// to accept the transfer. Auto-declines after [timeout].
class IncomingConnectionRequest extends Equatable {
  IncomingConnectionRequest({
    required this.requestId,
    required this.sender,
    this.files = const [],
    DateTime? receivedAt,
    this.timeout = const Duration(seconds: 30),
  }) : receivedAt = receivedAt ?? DateTime.now();

  /// Unique request id.
  final String requestId;

  /// The node that initiated the handshake.
  final PeerDevice sender;

  /// Payload manifest (file name + size preview).
  final List<FileItem> files;

  /// Moment the request was received.
  final DateTime receivedAt;

  /// How long the receiver has to respond before auto-decline.
  final Duration timeout;

  /// Absolute deadline after which the request auto-declines.
  DateTime get expiresAt => receivedAt.add(timeout);

  /// Total payload size in bytes.
  int get totalBytes => files.fold(0, (sum, f) => sum + f.size);

  /// Seconds left before auto-decline (>= 0).
  int get remainingSeconds {
    final left = expiresAt.difference(DateTime.now()).inSeconds;
    return left < 0 ? 0 : left;
  }

  /// True when the request should no longer be shown.
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  @override
  List<Object?> get props => [requestId, sender, files, receivedAt, timeout];
}
