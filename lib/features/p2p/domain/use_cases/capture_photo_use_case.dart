import '../entities/file_item.dart';
import '../repositories/peer_repository.dart';

/// Opens the system camera and returns the captured shot staged for transfer.
class CapturePhotoUseCase {
  const CapturePhotoUseCase(this._repository);

  final PeerRepository _repository;

  Future<List<FileItem>> execute() => _repository.capturePhoto();
}
