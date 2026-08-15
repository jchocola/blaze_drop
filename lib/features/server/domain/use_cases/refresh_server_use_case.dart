import '../repositories/server_repository.dart';

/// Regenerates the hub (QR/URL) on a fresh port if the current one is
/// congested or conflicted (FUNCTIONALITY.md §5.2 "Refresh").
class RefreshServerUseCase {
  const RefreshServerUseCase(this._repository);

  final ServerRepository _repository;

  Future<void> execute() => _repository.refreshServer();
}
