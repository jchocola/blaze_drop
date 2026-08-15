import '../entities/downloaded_file.dart';
import '../repositories/server_repository.dart';

/// Pulls a copy of a hub file to this device — photos land in the photo
/// gallery, other files in documents (FUNCTIONALITY.md §5.4 host download).
class DownloadSharedFileUseCase {
  const DownloadSharedFileUseCase(this._repository);

  final ServerRepository _repository;

  Future<DownloadedFile?> execute(String fileId) =>
      _repository.downloadSharedFile(fileId);
}
