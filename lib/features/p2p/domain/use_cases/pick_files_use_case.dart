import '../entities/file_item.dart';
import '../repositories/peer_repository.dart';

/// Opens the system file picker (multi-select) and returns the chosen files.
class PickFilesUseCase {
  const PickFilesUseCase(this._repository);

  final PeerRepository _repository;

  Future<List<FileItem>> execute() => _repository.pickFiles();
}
