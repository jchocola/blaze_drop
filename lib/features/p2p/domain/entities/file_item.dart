import 'package:equatable/equatable.dart';

/// A single file in a payload (FUNCTIONALITY.md §6).
class FileItem extends Equatable {
  const FileItem({
    required this.name,
    required this.path,
    required this.size,
    this.mimeType,
  });

  /// File name (sanitized on receive to prevent path traversal).
  final String name;

  /// Absolute path on the current device.
  final String path;

  /// Size in bytes.
  final int size;

  /// MIME type (best-effort; derived from the extension when unknown).
  final String? mimeType;

  /// Human-readable size, e.g. `14.2 MB`.
  String get sizeLabel => formatBytes(size);

  FileItem copyWith({String? name, String? path, int? size, String? mimeType}) {
    return FileItem(
      name: name ?? this.name,
      path: path ?? this.path,
      size: size ?? this.size,
      mimeType: mimeType ?? this.mimeType,
    );
  }

  @override
  List<Object?> get props => [name, path, size, mimeType];
}

/// Formats [bytes] into a compact binary-size label (`B`, `KB`, `MB`, `GB`).
String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  const units = <String>['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = -1;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text = value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}
