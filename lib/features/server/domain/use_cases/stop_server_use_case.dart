import '../repositories/server_repository.dart';

/// Terminates the local relay hub (FUNCTIONALITY.md §5.4 "Stop Server").
class StopServerUseCase {
  const StopServerUseCase(this._repository);

  final ServerRepository _repository;

  Future<void> execute() => _repository.stopServer();
}
