import '../entities/server_session.dart';
import '../repositories/server_repository.dart';

/// Streams live hub status updates.
class WatchServerStatusUseCase {
  const WatchServerStatusUseCase(this._repository);

  final ServerRepository _repository;

  Stream<ServerSession> execute() => _repository.watchStatus();
}
