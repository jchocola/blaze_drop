import '../entities/server_shared_file.dart';
import '../repositories/server_repository.dart';

/// Lists files currently shareable on the hub.
class ListSharedFilesUseCase {
  const ListSharedFilesUseCase(this._repository);

  final ServerRepository _repository;

  Future<List<ServerSharedFile>> execute() => _repository.listSharedFiles();
}
