import 'package:equatable/equatable.dart';

/// A file staged on the host device to be published into the relay hub
/// (FUNCTIONALITY.md §5.4 "Host Management" — host→hub upload).
///
/// Domain-level model: no plugin types leak into this layer.
class HostPublishFile extends Equatable {
  const HostPublishFile({
    required this.name,
    required this.path,
    required this.size,
    this.mimeType,
  });

  /// File name (sanitized on publish to prevent path traversal).
  final String name;

  /// Absolute path on the host device.
  final String path;

  /// Size in bytes.
  final int size;

  /// MIME type (best-effort; derived from the extension when unknown).
  final String? mimeType;

  @override
  List<Object?> get props => [name, path, size, mimeType];
}
