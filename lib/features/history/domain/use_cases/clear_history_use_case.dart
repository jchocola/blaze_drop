import '../../../../core/history/history_repository.dart';

/// Clears the whole transfer history.
class ClearHistoryUseCase {
  const ClearHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<void> execute() => _repository.clearHistory();
}
