import '../entities/host_publish_file.dart';
import '../repositories/server_repository.dart';

/// Opens the host device camera for a single shot and returns it staged for
/// publication into the relay hub.
class PickHostCameraPhotoUseCase {
  const PickHostCameraPhotoUseCase(this._repository);

  final ServerRepository _repository;

  Future<List<HostPublishFile>> execute() => _repository.pickHostCameraPhoto();
}
