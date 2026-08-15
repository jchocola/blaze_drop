import 'history_file.dart';
import 'session_record.dart';

/// Persistence boundary for the server-session transfer history.
///
/// Declared in `core` so the server feature can record sessions/files while
/// the history feature (UI) reads and clears them — without depending on
/// each other (RULE.md §1.2).
abstract interface class HistoryRepository {
  /// Starts a new session (closing any still-open one) and prunes the log to
  /// the last [AppConstants.maxHistorySessions] sessions. Returns the new
  /// session record.
  Future<SessionRecord> startSession({String? id});

  /// Ends the current open session.
  Future<void> endSession();

  /// Appends [file] to the current open session (no-op when none is open).
  Future<void> addFile(HistoryFile file);

  /// Latest history, newest session first.
  Future<List<SessionRecord>> getHistory();

  /// Live history updates (emitted on every mutation).
  Stream<List<SessionRecord>> watchHistory();

  /// Clears the whole history.
  Future<void> clearHistory();
}
