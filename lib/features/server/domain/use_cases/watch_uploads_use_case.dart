import '../entities/server_upload_event.dart';
import '../repositories/server_repository.dart';

/// Streams live incoming-upload events (HUD transfer log).
class WatchUploadsUseCase {
  const WatchUploadsUseCase(this._repository);

  final ServerRepository _repository;

  Stream<ServerUploadEvent> execute() => _repository.watchUploads();
}
