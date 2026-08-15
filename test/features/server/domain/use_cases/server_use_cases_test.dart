import 'dart:async';

import 'package:blaze_drop/features/server/domain/entities/downloaded_file.dart';
import 'package:blaze_drop/features/server/domain/entities/host_publish_file.dart';
import 'package:blaze_drop/features/server/domain/entities/server_session.dart';
import 'package:blaze_drop/features/server/domain/entities/server_shared_file.dart';
import 'package:blaze_drop/features/server/domain/repositories/server_repository.dart';
import 'package:blaze_drop/features/server/domain/use_cases/download_shared_file_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/list_shared_files_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/pick_host_files_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/publish_files_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/refresh_server_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/start_server_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/stop_server_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/watch_server_status_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockServerRepository extends Mock implements ServerRepository {}

const _activeSession = ServerSession(
  status: ServerStatus.active,
  port: 8080,
  localIp: '192.168.1.10',
);

const _hostFile = HostPublishFile(
  name: 'deploy.zip',
  path: '/tmp/deploy.zip',
  size: 42,
);

const _publishedFile = ServerSharedFile(
  id: 'deploy.zip',
  name: 'deploy.zip',
  path: '/shared/deploy.zip',
  size: 42,
);

void main() {
  group('Server use cases', () {
    late _MockServerRepository repository;

    setUp(() {
      repository = _MockServerRepository();
    });

    test('StartServerUseCase delegates with the session timeout', () async {
      when(
        () => repository.startServer(sessionTimeoutMinutes: any(named: 'sessionTimeoutMinutes')),
      ).thenAnswer((_) async => _activeSession);

      final result = await StartServerUseCase(repository).execute(
        sessionTimeoutMinutes: 30,
      );

      expect(result, _activeSession);
      verify(() => repository.startServer(sessionTimeoutMinutes: 30)).called(1);
    });

    test('StopServerUseCase delegates', () async {
      when(() => repository.stopServer()).thenAnswer((_) async {});

      await StopServerUseCase(repository).execute();

      verify(() => repository.stopServer()).called(1);
    });

    test('RefreshServerUseCase delegates', () async {
      when(() => repository.refreshServer()).thenAnswer((_) async {});

      await RefreshServerUseCase(repository).execute();

      verify(() => repository.refreshServer()).called(1);
    });

    test('WatchServerStatusUseCase forwards the status stream', () async {
      final controller = StreamController<ServerSession>.broadcast();
      when(() => repository.watchStatus()).thenAnswer((_) => controller.stream);

      final events = <ServerSession>[];
      final subscription = WatchServerStatusUseCase(repository)
          .execute()
          .listen(events.add);

      controller.add(_activeSession);
      await Future<void>.delayed(Duration.zero);

      expect(events.single, _activeSession);
      await subscription.cancel();
      await controller.close();
    });

    test('ListSharedFilesUseCase returns the shared files', () async {
      when(() => repository.listSharedFiles()).thenAnswer((_) async => [
        _publishedFile,
      ]);

      final result = await ListSharedFilesUseCase(repository).execute();

      expect(result, [_publishedFile]);
    });

    test('PickHostFilesUseCase returns the staged host files', () async {
      when(() => repository.pickHostFiles()).thenAnswer((_) async => [
        _hostFile,
      ]);

      final result = await PickHostFilesUseCase(repository).execute();

      expect(result, [_hostFile]);
    });

    test('PublishFilesUseCase publishes the staged files', () async {
      when(
        () => repository.publishFiles(any()),
      ).thenAnswer((_) async => [_publishedFile]);

      final result = await PublishFilesUseCase(repository).execute(
        const [_hostFile],
      );

      expect(result, [_publishedFile]);
      verify(() => repository.publishFiles(const [_hostFile])).called(1);
    });

    test('DownloadSharedFileUseCase pulls the shared file', () async {
      const downloaded = DownloadedFile(
        name: 'photo.png',
        target: DownloadTarget.gallery,
      );
      when(
        () => repository.downloadSharedFile(any()),
      ).thenAnswer((_) async => downloaded);

      final result = await DownloadSharedFileUseCase(repository).execute(
        'photo.png',
      );

      expect(result, downloaded);
      verify(() => repository.downloadSharedFile('photo.png')).called(1);
    });
  });
}
