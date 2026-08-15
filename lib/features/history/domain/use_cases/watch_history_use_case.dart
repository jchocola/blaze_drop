import '../../../../core/history/history_repository.dart';
import '../../../../core/history/session_record.dart';

/// Streams the latest history (emitted on every mutation).
class WatchHistoryUseCase {
  const WatchHistoryUseCase(this._repository);

  final HistoryRepository _repository;

  Stream<List<SessionRecord>> execute() => _repository.watchHistory();
}
