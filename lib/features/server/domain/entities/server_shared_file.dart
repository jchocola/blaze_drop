import 'package:equatable/equatable.dart';

import '../../../../core/utils/format_bytes.dart';

/// A file stored on the host and shareable with guests
/// (FUNCTIONALITY.md §5.3 "Download Area").
class ServerSharedFile extends Equatable {
  const ServerSharedFile({
    required this.id,
    required this.name,
    required this.path,
    required this.size,
    this.mimeType,
    this.addedAt,
  });

  /// Unique id used by `GET /download/{id}` (the sanitized file name).
  final String id;

  final String name;

  /// Absolute path on the host device.
  final String path;

  /// Size in bytes.
  final int size;

  final String? mimeType;

  final DateTime? addedAt;

  String get sizeLabel => formatBytes(size);

  @override
  List<Object?> get props => [id, name, path, size, mimeType, addedAt];
}
