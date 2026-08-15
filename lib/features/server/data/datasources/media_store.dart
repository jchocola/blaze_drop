import '../../domain/entities/downloaded_file.dart';

/// Stores a downloaded file on the host device, choosing the target by type:
/// photos → gallery, everything else → documents (FUNCTIONALITY.md §5.4).
abstract interface class MediaStore {
  Future<DownloadedFile> store({
    required String sourcePath,
    required String fileName,
  });
}
