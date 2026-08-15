import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/history/session_record.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/use_cases/clear_history_use_case.dart';
import '../../domain/use_cases/get_history_use_case.dart';
import '../../domain/use_cases/watch_history_use_case.dart';
import 'history_state.dart';

/// Orchestrates the TRANSFER HISTORY tab (FUNCTIONALITY.md mock).
///
/// Loads the persisted session log, subscribes to live updates and clears the
/// log on demand. No business logic here — delegates to use cases (RULE.md §2).
class HistoryCubit extends Cubit<HistoryState> {
  HistoryCubit({
    required this.getHistoryUseCase,
    required this.watchHistoryUseCase,
    required this.clearHistoryUseCase,
  }) : super(const HistoryState());

  final GetHistoryUseCase getHistoryUseCase;
  final WatchHistoryUseCase watchHistoryUseCase;
  final ClearHistoryUseCase clearHistoryUseCase;

  StreamSubscription<List<SessionRecord>>? _subscription;
  bool _initialized = false;

  /// Loads the current log and subscribes to live updates.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    try {
      final sessions = await getHistoryUseCase.execute();
      if (!isClosed) {
        emit(state.copyWith(sessions: sessions, isLoading: false));
      }
    } catch (error, stack) {
      AppLogger.error('Failed to load transfer history', error, stack);
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: 'Failed to load history'));
      }
    }
    _subscription = watchHistoryUseCase.execute().listen(
      (sessions) {
        if (!isClosed) {
          emit(
            state.copyWith(
              sessions: sessions,
              isLoading: false,
              error: null,
            ),
          );
        }
      },
      onError: (Object error, StackTrace stack) {
        AppLogger.error('History stream error', error, stack);
      },
    );
  }

  /// Wipes the whole transfer history.
  Future<void> clearHistory() async {
    if (state.isClearing) {
      return;
    }
    emit(state.copyWith(isClearing: true, error: null));
    try {
      await clearHistoryUseCase.execute();
      if (!isClosed) {
        emit(state.copyWith(isClearing: false));
      }
      AppLogger.info('Transfer history cleared');
    } catch (error, stack) {
      AppLogger.error('Failed to clear transfer history', error, stack);
      if (!isClosed) {
        emit(state.copyWith(isClearing: false, error: 'Failed to clear history'));
      }
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    _subscription = null;
    await super.close();
  }
}
