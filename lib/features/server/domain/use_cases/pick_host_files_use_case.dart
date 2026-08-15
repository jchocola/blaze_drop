import '../entities/host_publish_file.dart';
import '../repositories/server_repository.dart';

/// Opens the host file picker and returns files staged for publication.
class PickHostFilesUseCase {
  const PickHostFilesUseCase(this._repository);

  final ServerRepository _repository;

  Future<List<HostPublishFile>> execute() => _repository.pickHostFiles();
}
