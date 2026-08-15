import 'package:equatable/equatable.dart';

import '../../../../core/history/session_record.dart';

/// UI state for the TRANSFER HISTORY tab (FUNCTIONALITY.md mock).
class HistoryState extends Equatable {
  const HistoryState({
    this.sessions = const [],
    this.isLoading = true,
    this.isClearing = false,
    this.error,
  });

  /// Server sessions, newest first (capped at [AppConstants.maxHistorySessions]).
  final List<SessionRecord> sessions;

  final bool isLoading;

  final bool isClearing;

  final String? error;

  HistoryState copyWith({
    List<SessionRecord>? sessions,
    bool? isLoading,
    bool? isClearing,
    Object? error = _unset,
  }) {
    return HistoryState(
      sessions: sessions ?? this.sessions,
      isLoading: isLoading ?? this.isLoading,
      isClearing: isClearing ?? this.isClearing,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  static const _unset = Object();

  @override
  List<Object?> get props => [sessions, isLoading, isClearing, error];
}
