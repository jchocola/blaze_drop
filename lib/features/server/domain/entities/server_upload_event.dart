import 'package:equatable/equatable.dart';

import '../../../../core/utils/format_bytes.dart';

/// Stage of a guest→host upload.
enum ServerUploadStatus {
  /// Bytes are being written to disk.
  receiving,

  /// Saved successfully.
  completed,

  /// Aborted (client dropped, disk error, …).
  failed,
}

/// A single incoming file transfer observed by the host HUD
/// (FUNCTIONALITY.md §5.4 "Incoming Files").
class ServerUploadEvent extends Equatable {
  const ServerUploadEvent({
    required this.fileName,
    required this.transferredBytes,
    required this.totalBytes,
    required this.status,
    this.clientIp = '',
    this.savedPath,
    this.message,
  });

  final String fileName;

  final int transferredBytes;

  /// 0 when unknown (e.g. chunked uploads without a content-length).
  final int totalBytes;

  final ServerUploadStatus status;

  final String clientIp;

  /// Destination on disk once [ServerUploadStatus.completed].
  final String? savedPath;

  final String? message;

  /// 0..1 completion fraction.
  double get progress {
    if (totalBytes <= 0) {
      return status == ServerUploadStatus.completed ? 1 : 0;
    }
    return (transferredBytes / totalBytes).clamp(0.0, 1.0);
  }

  String get sizeLabel => formatBytes(transferredBytes);

  ServerUploadEvent copyWith({
    int? transferredBytes,
    int? totalBytes,
    ServerUploadStatus? status,
    String? savedPath,
    String? message,
  }) {
    return ServerUploadEvent(
      fileName: fileName,
      transferredBytes: transferredBytes ?? this.transferredBytes,
      totalBytes: totalBytes ?? this.totalBytes,
      status: status ?? this.status,
      clientIp: clientIp,
      savedPath: savedPath ?? this.savedPath,
      message: message ?? this.message,
    );
  }

  @override
  List<Object?> get props => [
    fileName,
    transferredBytes,
    totalBytes,
    status,
    clientIp,
    savedPath,
    message,
  ];
}
