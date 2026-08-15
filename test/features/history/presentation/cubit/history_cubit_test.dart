import 'dart:async';

import 'package:blaze_drop/core/history/history_file.dart';
import 'package:blaze_drop/core/history/session_record.dart';
import 'package:blaze_drop/features/history/domain/use_cases/clear_history_use_case.dart';
import 'package:blaze_drop/features/history/domain/use_cases/get_history_use_case.dart';
import 'package:blaze_drop/features/history/domain/use_cases/watch_history_use_case.dart';
import 'package:blaze_drop/features/history/presentation/cubit/history_cubit.dart';
import 'package:blaze_drop/features/history/presentation/cubit/history_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetHistory extends Mock implements GetHistoryUseCase {}

class _MockWatchHistory extends Mock implements WatchHistoryUseCase {}

class _MockClearHistory extends Mock implements ClearHistoryUseCase {}

final _session = SessionRecord(
  id: 's1',
  startedAt: DateTime(2026, 1, 1, 10, 30),
  endedAt: DateTime(2026, 1, 1, 10, 35),
  files: const [
    HistoryFile(
      name: 'report.pdf',
      size: 100,
      kind: HistoryFileKind.received,
    ),
  ],
);

void main() {
  group('HistoryCubit', () {
    late _MockGetHistory getHistory;
    late _MockWatchHistory watchHistory;
    late _MockClearHistory clearHistory;
    late StreamController<List<SessionRecord>> watchController;

    setUp(() {
      getHistory = _MockGetHistory();
      watchHistory = _MockWatchHistory();
      clearHistory = _MockClearHistory();
      watchController = StreamController<List<SessionRecord>>.broadcast();
      when(
        () => watchHistory.execute(),
      ).thenAnswer((_) => watchController.stream);
    });

    tearDown(() async {
      await watchController.close();
    });

    HistoryCubit buildCubit() {
      return HistoryCubit(
        getHistoryUseCase: getHistory,
        watchHistoryUseCase: watchHistory,
        clearHistoryUseCase: clearHistory,
      );
    }

    test('initial state is loading', () {
      final cubit = buildCubit();
      expect(cubit.state.isLoading, isTrue);
      expect(cubit.state.sessions, isEmpty);
    });

    blocTest<HistoryCubit, HistoryState>(
      'initialize loads the persisted history',
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      setUp: () {
        when(
          () => getHistory.execute(),
        ).thenAnswer((_) async => [_session]);
      },
      expect: () => [
        HistoryState(sessions: [_session], isLoading: false),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'watch stream updates the sessions live',
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        watchController.add([_session]);
        await Future<void>.delayed(Duration.zero);
      },
      setUp: () {
        when(() => getHistory.execute()).thenAnswer((_) async => const []);
      },
      expect: () => [
        const HistoryState(sessions: [], isLoading: false),
        HistoryState(sessions: [_session], isLoading: false),
      ],
    );

    blocTest<HistoryCubit, HistoryState>(
      'clearHistory delegates and clears the loading flag',
      build: buildCubit,
      seed: () => HistoryState(sessions: [_session], isLoading: false),
      act: (cubit) => cubit.clearHistory(),
      setUp: () {
        when(() => clearHistory.execute()).thenAnswer((_) async {});
      },
      expect: () => [
        HistoryState(sessions: [_session], isLoading: false, isClearing: true),
        HistoryState(sessions: [_session], isLoading: false, isClearing: false),
      ],
    );
  });
}
