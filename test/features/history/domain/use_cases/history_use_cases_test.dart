import 'dart:async';

import 'package:blaze_drop/core/history/history_repository.dart';
import 'package:blaze_drop/core/history/session_record.dart';
import 'package:blaze_drop/features/history/domain/use_cases/clear_history_use_case.dart';
import 'package:blaze_drop/features/history/domain/use_cases/get_history_use_case.dart';
import 'package:blaze_drop/features/history/domain/use_cases/watch_history_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockHistoryRepository extends Mock implements HistoryRepository {}

void main() {
  group('History use cases', () {
    late _MockHistoryRepository repository;

    setUp(() {
      repository = _MockHistoryRepository();
    });

    test('GetHistoryUseCase returns the latest history', () async {
      final session = SessionRecord(id: 's1', startedAt: DateTime(2026));
      when(() => repository.getHistory()).thenAnswer((_) async => [session]);

      final result = await GetHistoryUseCase(repository).execute();

      expect(result, [session]);
    });

    test('WatchHistoryUseCase forwards the stream', () async {
      final controller = StreamController<List<SessionRecord>>.broadcast();
      when(
        () => repository.watchHistory(),
      ).thenAnswer((_) => controller.stream);

      final events = <List<SessionRecord>>[];
      final subscription = WatchHistoryUseCase(repository)
          .execute()
          .listen(events.add);

      controller.add(const []);
      await Future<void>.delayed(Duration.zero);

      expect(events.single, isEmpty);
      await subscription.cancel();
      await controller.close();
    });

    test('ClearHistoryUseCase delegates', () async {
      when(() => repository.clearHistory()).thenAnswer((_) async {});

      await ClearHistoryUseCase(repository).execute();

      verify(() => repository.clearHistory()).called(1);
    });
  });
}
