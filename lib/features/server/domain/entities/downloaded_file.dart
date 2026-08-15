import 'package:equatable/equatable.dart';

/// Where a host "download" from the hub was stored.
enum DownloadTarget {
  /// Imported into the device photo library (photos only).
  gallery,

  /// Copied into the documents folder (everything else).
  documents,
}

/// Result of a host download from the relay hub (FUNCTIONALITY.md §5.4).
///
/// Photos are routed to the gallery, all other files to documents.
class DownloadedFile extends Equatable {
  const DownloadedFile({
    required this.name,
    required this.target,
    this.path = '',
  });

  /// Stored file name.
  final String name;

  final DownloadTarget target;

  /// Destination on disk for [DownloadTarget.documents]; the source path (or
  /// empty) for [DownloadTarget.gallery] items living in the photo library.
  final String path;

  @override
  List<Object?> get props => [name, target, path];
}
