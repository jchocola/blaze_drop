import '../entities/host_publish_file.dart';
import '../repositories/server_repository.dart';

/// Opens the host device photo gallery and returns photos staged for
/// publication into the relay hub.
class PickHostGalleryPhotosUseCase {
  const PickHostGalleryPhotosUseCase(this._repository);

  final ServerRepository _repository;

  Future<List<HostPublishFile>> execute() =>
      _repository.pickHostGalleryPhotos();
}
