import 'package:blaze_drop/core/history/history_file.dart';
import 'package:blaze_drop/core/history/session_record.dart';
import 'package:blaze_drop/features/history/data/datasources/history_local_data_source.dart';
import 'package:blaze_drop/features/history/data/repositories_impl/history_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

const _fileA = HistoryFile(
  name: 'a.txt',
  size: 5,
  kind: HistoryFileKind.received,
);

const _fileB = HistoryFile(
  name: 'b.zip',
  size: 100,
  kind: HistoryFileKind.published,
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late LocalHistoryRepositoryImpl repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    repository = LocalHistoryRepositoryImpl(HistoryLocalDataSource(prefs));
  });

  group('LocalHistoryRepositoryImpl', () {
    test('startSession records a session and persists it', () async {
      final session = await repository.startSession(id: 's1');

      expect(session.id, 's1');
      expect(session.isActive, isTrue);

      final history = await repository.getHistory();
      expect(history.length, 1);
      expect(history.first.id, 's1');
    });

    test('addFile appends to the open session and persists', () async {
      await repository.startSession(id: 's1');
      await repository.addFile(_fileA);
      await repository.addFile(_fileB);

      final history = await repository.getHistory();
      expect(history.first.files.length, 2);
      expect(history.first.files[0], _fileA);
      expect(history.first.files[1], _fileB);
    });

    test('endSession closes the open session', () async {
      await repository.startSession(id: 's1');
      await repository.addFile(_fileA);

      await repository.endSession();

      final history = await repository.getHistory();
      expect(history.first.endedAt, isNotNull);
      expect(history.first.isActive, isFalse);
    });

    test('prunes history to the last 3 sessions', () async {
      await repository.startSession(id: 's1');
      await repository.startSession(id: 's2');
      await repository.startSession(id: 's3');
      await repository.startSession(id: 's4');

      final history = await repository.getHistory();
      expect(history.length, 3);
      expect(history.map((s) => s.id).toList(), ['s4', 's3', 's2']);
    });

    test('clearHistory wipes everything', () async {
      await repository.startSession(id: 's1');
      await repository.addFile(_fileA);

      await repository.clearHistory();

      expect(await repository.getHistory(), isEmpty);
    });

    test('addFile without an open session is a no-op', () async {
      await repository.startSession(id: 's1');
      await repository.endSession();

      await repository.addFile(_fileA);

      expect((await repository.getHistory()).first.files, isEmpty);
    });

    test('persists across repository instances', () async {
      await repository.startSession(id: 's1');
      await repository.addFile(_fileA);
      await repository.endSession();

      SharedPreferences prefs = await SharedPreferences.getInstance();
      final reloaded = LocalHistoryRepositoryImpl(
        HistoryLocalDataSource(prefs),
      );
      final history = await reloaded.getHistory();

      expect(history.length, 1);
      expect(history.first.id, 's1');
      expect(history.first.files.single.name, 'a.txt');
      expect(history.first.endedAt, isNotNull);
    });

    test('watchHistory emits on mutations', () async {
      final events = <List<SessionRecord>>[];
      final subscription = repository.watchHistory().listen(events.add);

      await repository.startSession(id: 's1');
      await Future<void>.delayed(Duration.zero);

      expect(events, isNotEmpty);
      expect(events.last.single.id, 's1');
      await subscription.cancel();
    });
  });
}
