import '../entities/host_publish_file.dart';
import '../entities/server_shared_file.dart';
import '../repositories/server_repository.dart';

/// Publishes host-picked files into the relay hub so guests can download them
/// (FUNCTIONALITY.md §5.4 host upload).
class PublishFilesUseCase {
  const PublishFilesUseCase(this._repository);

  final ServerRepository _repository;

  Future<List<ServerSharedFile>> execute(List<HostPublishFile> files) =>
      _repository.publishFiles(files);
}
