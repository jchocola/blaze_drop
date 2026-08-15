import '../entities/file_item.dart';
import '../repositories/peer_repository.dart';

/// Opens the device photo gallery (multi-select) and returns the chosen
/// photos staged for transfer.
class PickGalleryPhotosUseCase {
  const PickGalleryPhotosUseCase(this._repository);

  final PeerRepository _repository;

  Future<List<FileItem>> execute() => _repository.pickGalleryPhotos();
}
