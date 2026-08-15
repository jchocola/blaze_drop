import '../../../../core/history/history_repository.dart';
import '../../../../core/history/session_record.dart';

/// Loads the latest history, newest session first.
class GetHistoryUseCase {
  const GetHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Future<List<SessionRecord>> execute() => _repository.getHistory();
}
