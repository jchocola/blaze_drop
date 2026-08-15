import 'package:equatable/equatable.dart';

import 'file_item.dart';
import 'peer_device.dart';

/// Direction of a [TransferSession] relative to the local node.
enum TransferDirection { incoming, outgoing }

/// Lifecycle status of a transfer.
enum TransferStatus {
  pending,
  transferring,
  completed,
  failed,
  declined,
}

/// A single file-transfer session between two peers (FUNCTIONALITY.md §6).
class TransferSession extends Equatable {
  const TransferSession({
    required this.sessionId,
    required this.peer,
    required this.direction,
    this.files = const [],
    this.status = TransferStatus.pending,
    this.progress = 0,
    this.bytesTransferred = 0,
    this.bytesTotal = 0,
    this.speedBytesPerSecond = 0,
    this.timestamp,
    this.error,
  });

  /// UUID of the session.
  final String sessionId;

  /// The remote node involved in this session.
  final PeerDevice peer;

  final TransferDirection direction;

  final List<FileItem> files;

  final TransferStatus status;

  /// Overall progress, 0..1.
  final double progress;

  final int bytesTransferred;

  final int bytesTotal;

  /// Instantaneous throughput in bytes per second.
  final int speedBytesPerSecond;

  final DateTime? timestamp;

  final String? error;

  /// Formatted speed, e.g. `45.0 MB/s`.
  String get speedLabel => '${formatBytes(speedBytesPerSecond)}/s';

  /// Estimated remaining time in seconds (best-effort).
  int get estimatedSecondsRemaining {
    if (speedBytesPerSecond <= 0 || bytesTotal <= 0) {
      return 0;
    }
    final remaining = bytesTotal - bytesTransferred;
    if (remaining <= 0) {
      return 0;
    }
    return (remaining / speedBytesPerSecond).ceil();
  }

  TransferSession copyWith({
    String? sessionId,
    List<FileItem>? files,
    TransferStatus? status,
    double? progress,
    int? bytesTransferred,
    int? bytesTotal,
    int? speedBytesPerSecond,
    DateTime? timestamp,
    String? error,
  }) {
    return TransferSession(
      sessionId: sessionId ?? this.sessionId,
      peer: peer,
      direction: direction,
      files: files ?? this.files,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      bytesTransferred: bytesTransferred ?? this.bytesTransferred,
      bytesTotal: bytesTotal ?? this.bytesTotal,
      speedBytesPerSecond: speedBytesPerSecond ?? this.speedBytesPerSecond,
      timestamp: timestamp ?? this.timestamp,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [
    sessionId,
    peer,
    direction,
    files,
    status,
    progress,
    bytesTransferred,
    bytesTotal,
    speedBytesPerSecond,
    timestamp,
    error,
  ];
}
