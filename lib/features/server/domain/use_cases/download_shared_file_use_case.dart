import '../entities/server_shared_file.dart';
import '../repositories/server_repository.dart';

/// Pulls a copy of a hub file into the host's local received folder
/// (FUNCTIONALITY.md §5.4 host download).
class DownloadSharedFileUseCase {
  const DownloadSharedFileUseCase(this._repository);

  final ServerRepository _repository;

  Future<ServerSharedFile?> execute(String fileId) =>
      _repository.downloadSharedFile(fileId);
}
