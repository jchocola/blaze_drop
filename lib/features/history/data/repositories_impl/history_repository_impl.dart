import 'dart:async';

import '../../../../core/constants/constants.dart';
import '../../../../core/history/history_file.dart';
import '../../../../core/history/history_repository.dart';
import '../../../../core/history/session_record.dart';
import '../../../../core/utils/logger.dart';
import '../datasources/history_local_data_source.dart';

/// Concrete [HistoryRepository] backed by [HistoryLocalDataSource].
///
/// Records are best-effort: persistence failures are logged and swallowed so
/// that recording history never breaks a live transfer.
class LocalHistoryRepositoryImpl implements HistoryRepository {
  LocalHistoryRepositoryImpl(this._dataSource);

  final HistoryLocalDataSource _dataSource;

  final _controller = StreamController<List<SessionRecord>>.broadcast();
  SessionRecord? _open;
  List<SessionRecord> _cache = const [];

  Future<void> _load() async {
    try {
      _cache = await _dataSource.read();
    } catch (error, stack) {
      AppLogger.error('Failed to load history', error, stack);
      _cache = const [];
    }
  }

  Future<void> _persist() async {
    try {
      await _dataSource.write(_cache);
    } catch (error, stack) {
      AppLogger.error('Failed to persist history', error, stack);
    }
  }

  void _emit() {
    if (!_controller.isClosed) {
      _controller.add(List<SessionRecord>.unmodifiable(_cache));
    }
  }

  @override
  Future<SessionRecord> startSession({String? id}) async {
    await _load();
    // Defensively close any still-open session before a new one begins.
    if (_cache.isNotEmpty && _cache.first.isActive) {
      _cache = [..._cache];
      _cache[0] = _cache[0].copyWith(endedAt: DateTime.now());
    }
    final session = SessionRecord(
      id: id ?? 'session-${DateTime.now().millisecondsSinceEpoch}',
      startedAt: DateTime.now(),
    );
    _cache = [session, ..._cache];
    if (_cache.length > AppConstants.maxHistorySessions) {
      _cache = _cache.sublist(0, AppConstants.maxHistorySessions);
    }
    _open = session;
    await _persist();
    _emit();
    return session;
  }

  @override
  Future<void> endSession() async {
    await _load();
    _open = null;
    if (_cache.isNotEmpty && _cache.first.isActive) {
      _cache = [..._cache];
      _cache[0] = _cache[0].copyWith(endedAt: DateTime.now());
      await _persist();
      _emit();
    }
  }

  @override
  Future<void> addFile(HistoryFile file) async {
    await _load();
    final open = _open;
    if (open == null) {
      return; // no active session
    }
    final index = _cache.indexWhere((s) => s.id == open.id);
    if (index < 0) {
      return;
    }
    final current = _cache[index];
    _cache = [..._cache];
    _cache[index] = current.copyWith(files: [...current.files, file]);
    await _persist();
    _emit();
  }

  @override
  Future<List<SessionRecord>> getHistory() async {
    await _load();
    return _sorted(_cache);
  }

  List<SessionRecord> _sorted(List<SessionRecord> sessions) {
    final copy = [...sessions];
    copy.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return copy;
  }

  @override
  Stream<List<SessionRecord>> watchHistory() => _controller.stream;

  @override
  Future<void> clearHistory() async {
    try {
      await _dataSource.clear();
    } catch (error, stack) {
      AppLogger.error('Failed to clear history', error, stack);
    }
    _cache = const [];
    _open = null;
    _emit();
  }
}
