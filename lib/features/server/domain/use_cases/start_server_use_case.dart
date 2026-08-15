import '../entities/server_session.dart';
import '../repositories/server_repository.dart';

/// Activates the local relay hub (FUNCTIONALITY.md §5.1).
class StartServerUseCase {
  const StartServerUseCase(this._repository);

  final ServerRepository _repository;

  Future<ServerSession> execute({int sessionTimeoutMinutes = 15}) =>
      _repository.startServer(sessionTimeoutMinutes: sessionTimeoutMinutes);
}
