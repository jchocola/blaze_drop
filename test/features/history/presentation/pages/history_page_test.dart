import 'dart:async';

import 'package:blaze_drop/core/constants/constants.dart';
import 'package:blaze_drop/core/history/history_file.dart';
import 'package:blaze_drop/core/history/session_record.dart';
import 'package:blaze_drop/core/theme/theme.dart';
import 'package:blaze_drop/features/history/domain/use_cases/clear_history_use_case.dart';
import 'package:blaze_drop/features/history/domain/use_cases/get_history_use_case.dart';
import 'package:blaze_drop/features/history/domain/use_cases/watch_history_use_case.dart';
import 'package:blaze_drop/features/history/presentation/cubit/history_cubit.dart';
import 'package:blaze_drop/features/history/presentation/pages/history_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetHistory extends Mock implements GetHistoryUseCase {}

class _MockWatchHistory extends Mock implements WatchHistoryUseCase {}

class _MockClearHistory extends Mock implements ClearHistoryUseCase {}

final _session = SessionRecord(
  id: 'session-123',
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
  group('HistoryPage', () {
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
        () => getHistory.execute(),
      ).thenAnswer((_) async => const []);
      when(
        () => watchHistory.execute(),
      ).thenAnswer((_) => watchController.stream);
      when(() => clearHistory.execute()).thenAnswer((_) async {});
    });

    tearDown(() async {
      await watchController.close();
    });

    Widget buildApp(HistoryCubit cubit) {
      return BlocProvider.value(
        value: cubit,
        child: MaterialApp(theme: AppTheme.dark, home: const HistoryPage()),
      );
    }

    HistoryCubit buildCubit() {
      return HistoryCubit(
        getHistoryUseCase: getHistory,
        watchHistoryUseCase: watchHistory,
        clearHistoryUseCase: clearHistory,
      );
    }

    testWidgets('renders the retention notice and an empty state', (
      tester,
    ) async {
      final cubit = buildCubit();
      await tester.pumpWidget(buildApp(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('TRANSFER HISTORY'), findsOneWidget);
      expect(
        find.text(
          'STORING LAST ${AppConstants.maxHistorySessions} SESSIONS — '
          'older archives are auto-pruned.',
        ),
        findsOneWidget,
      );
      expect(find.text('NO SESSIONS RECORDED'), findsOneWidget);
      expect(find.text('CLEAR HISTORY'), findsOneWidget);
    });

    testWidgets('renders a recorded session with its files', (tester) async {
      when(
        () => getHistory.execute(),
      ).thenAnswer((_) async => [_session]);
      final cubit = buildCubit();

      await tester.pumpWidget(buildApp(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(find.text('123'), findsOneWidget); // session short id
      expect(find.text('report.pdf'), findsOneWidget);
      expect(find.text('RECEIVED'), findsOneWidget);
    });

    testWidgets('CLEAR HISTORY delegates to the cubit', (tester) async {
      when(
        () => getHistory.execute(),
      ).thenAnswer((_) async => [_session]);
      final cubit = buildCubit();

      await tester.pumpWidget(buildApp(cubit));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      await tester.tap(find.text('CLEAR HISTORY'));
      await tester.pump();

      verify(() => clearHistory.execute()).called(1);
    });
  });
}
