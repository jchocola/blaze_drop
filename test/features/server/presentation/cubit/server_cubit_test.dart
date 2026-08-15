import 'dart:async';

import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/core/config/settings_repository.dart';
import 'package:blaze_drop/core/history/history_file.dart';
import 'package:blaze_drop/core/history/history_repository.dart';
import 'package:blaze_drop/core/history/session_record.dart';
import 'package:blaze_drop/features/server/domain/entities/connected_client.dart';
import 'package:blaze_drop/features/server/domain/entities/downloaded_file.dart';
import 'package:blaze_drop/features/server/domain/entities/host_publish_file.dart';
import 'package:blaze_drop/features/server/domain/entities/server_session.dart';
import 'package:blaze_drop/features/server/domain/entities/server_shared_file.dart';
import 'package:blaze_drop/features/server/domain/entities/server_upload_event.dart';
import 'package:blaze_drop/features/server/domain/use_cases/download_shared_file_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/list_shared_files_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/pick_host_files_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/publish_files_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/refresh_server_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/start_server_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/stop_server_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/watch_connected_clients_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/watch_server_status_use_case.dart';
import 'package:blaze_drop/features/server/domain/use_cases/watch_uploads_use_case.dart';
import 'package:blaze_drop/features/server/presentation/cubit/server_cubit.dart';
import 'package:blaze_drop/features/server/presentation/cubit/server_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockStartServer extends Mock implements StartServerUseCase {}

class _MockStopServer extends Mock implements StopServerUseCase {}

class _MockRefreshServer extends Mock implements RefreshServerUseCase {}

class _MockWatchStatus extends Mock implements WatchServerStatusUseCase {}

class _MockWatchClients extends Mock implements WatchConnectedClientsUseCase {}

class _MockWatchUploads extends Mock implements WatchUploadsUseCase {}

class _MockListFiles extends Mock implements ListSharedFilesUseCase {}

class _MockPickHostFiles extends Mock implements PickHostFilesUseCase {}

class _MockPublishFiles extends Mock implements PublishFilesUseCase {}

class _MockDownloadSharedFile extends Mock
    implements DownloadSharedFileUseCase {}

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockHistoryRepository extends Mock implements HistoryRepository {}

const _activeSession = ServerSession(
  status: ServerStatus.active,
  port: 8080,
  localIp: '192.168.1.10',
);

const _client = ConnectedClient(
  id: '127.0.0.1',
  name: 'NODE-X',
  ipAddress: '127.0.0.1',
);

const _completedUpload = ServerUploadEvent(
  fileName: 'report.pdf',
  transferredBytes: 100,
  totalBytes: 100,
  status: ServerUploadStatus.completed,
  clientIp: '127.0.0.1',
);

const _sharedFile = ServerSharedFile(
  id: 'report.pdf',
  name: 'report.pdf',
  path: '/tmp/report.pdf',
  size: 100,
);

const _hostFile = HostPublishFile(
  name: 'deploy.zip',
  path: '/tmp/deploy.zip',
  size: 42,
);

void main() {
  setUpAll(() {
    registerFallbackValue(
      const HistoryFile(
        name: 'fb.bin',
        size: 0,
        kind: HistoryFileKind.received,
      ),
    );
  });

  group('ServerCubit', () {
    late _MockStartServer startServer;
    late _MockStopServer stopServer;
    late _MockRefreshServer refreshServer;
    late _MockWatchStatus watchStatus;
    late _MockWatchClients watchClients;
    late _MockWatchUploads watchUploads;
    late _MockListFiles listFiles;
    late _MockPickHostFiles pickHostFiles;
    late _MockPublishFiles publishFiles;
    late _MockDownloadSharedFile downloadSharedFile;
    late _MockSettingsRepository settingsRepository;
    late _MockHistoryRepository historyRepository;
    late StreamController<ServerSession> statusController;
    late StreamController<List<ConnectedClient>> clientsController;
    late StreamController<ServerUploadEvent> uploadsController;

    setUp(() {
      startServer = _MockStartServer();
      stopServer = _MockStopServer();
      refreshServer = _MockRefreshServer();
      watchStatus = _MockWatchStatus();
      watchClients = _MockWatchClients();
      watchUploads = _MockWatchUploads();
      listFiles = _MockListFiles();
      pickHostFiles = _MockPickHostFiles();
      publishFiles = _MockPublishFiles();
      downloadSharedFile = _MockDownloadSharedFile();
      settingsRepository = _MockSettingsRepository();
      historyRepository = _MockHistoryRepository();
      statusController = StreamController<ServerSession>.broadcast();
      clientsController =
          StreamController<List<ConnectedClient>>.broadcast();
      uploadsController = StreamController<ServerUploadEvent>.broadcast();

      when(
        () => settingsRepository.loadConfig(),
      ).thenAnswer((_) async => AppConfig.defaults);
      when(
        () => watchStatus.execute(),
      ).thenAnswer((_) => statusController.stream);
      when(
        () => watchClients.execute(),
      ).thenAnswer((_) => clientsController.stream);
      when(
        () => watchUploads.execute(),
      ).thenAnswer((_) => uploadsController.stream);
      when(
        () => listFiles.execute(),
      ).thenAnswer((_) async => const [_sharedFile]);
      when(
        () => historyRepository.startSession(),
      ).thenAnswer(
        (_) async => SessionRecord(id: 'test', startedAt: DateTime.now()),
      );
      when(
        () => historyRepository.endSession(),
      ).thenAnswer((_) async {});
      when(
        () => historyRepository.addFile(any()),
      ).thenAnswer((_) async {});
    });

    tearDown(() async {
      await statusController.close();
      await clientsController.close();
      await uploadsController.close();
    });

    ServerCubit buildCubit() {
      return ServerCubit(
        startServerUseCase: startServer,
        stopServerUseCase: stopServer,
        refreshServerUseCase: refreshServer,
        watchServerStatusUseCase: watchStatus,
        watchConnectedClientsUseCase: watchClients,
        watchUploadsUseCase: watchUploads,
        listSharedFilesUseCase: listFiles,
        pickHostFilesUseCase: pickHostFiles,
        publishFilesUseCase: publishFiles,
        downloadSharedFileUseCase: downloadSharedFile,
        settingsRepository: settingsRepository,
        historyRepository: historyRepository,
      );
    }

    test('initial state is idle with no clients', () {
      final cubit = buildCubit();
      expect(cubit.state.isActive, isFalse);
      expect(cubit.state.session.status, ServerStatus.idle);
      expect(cubit.state.clients, isEmpty);
      expect(cubit.state.uploads, isEmpty);
    });

    blocTest<ServerCubit, ServerState>(
      'initialize applies the HUD preference from config',
      build: buildCubit,
      act: (cubit) => cubit.initialize(),
      setUp: () {
        when(
          () => settingsRepository.loadConfig(),
        ).thenAnswer((_) async => const AppConfig(showHudLogs: false));
      },
      expect: () => const [
        ServerState(hudLogsEnabled: false),
      ],
    );

    blocTest<ServerCubit, ServerState>(
      'startServer activates the hub and lists shared files',
      build: buildCubit,
      act: (cubit) => cubit.initialize().then((_) => cubit.startServer()),
      setUp: () {
        when(
          () => settingsRepository.loadConfig(),
        ).thenAnswer(
          (_) async => const AppConfig(
            showHudLogs: false,
            sessionTimeoutMinutes: 30,
          ),
        );
        when(
          () => startServer.execute(
            sessionTimeoutMinutes: any(named: 'sessionTimeoutMinutes'),
          ),
        ).thenAnswer((_) async => _activeSession);
        when(
          () => listFiles.execute(),
        ).thenAnswer((_) async => const [_sharedFile]);
      },
      expect: () => const [
        ServerState(hudLogsEnabled: false),
        ServerState(session: _activeSession, hudLogsEnabled: false),
        ServerState(
          session: _activeSession,
          hudLogsEnabled: false,
          sharedFiles: [_sharedFile],
        ),
      ],
    );

    blocTest<ServerCubit, ServerState>(
      'startServer surfaces an error on failure',
      build: buildCubit,
      act: (cubit) => cubit.startServer(),
      setUp: () {
        when(
          () => startServer.execute(
            sessionTimeoutMinutes: any(named: 'sessionTimeoutMinutes'),
          ),
        ).thenThrow(Exception('boom'));
      },
      expect: () => const [
        ServerState(error: 'Server failed to start'),
      ],
    );

    blocTest<ServerCubit, ServerState>(
      'stopServer clears the session, clients and upload log',
      build: buildCubit,
      seed: () => const ServerState(
        session: _activeSession,
        clients: [_client],
        uploads: [_completedUpload],
        hudLogsEnabled: false,
      ),
      act: (cubit) => cubit.stopServer(),
      setUp: () {
        when(() => stopServer.execute()).thenAnswer((_) async {});
      },
      expect: () => const [
        ServerState(
          session: ServerSession(status: ServerStatus.stopped),
          hudLogsEnabled: false,
        ),
      ],
    );

    blocTest<ServerCubit, ServerState>(
      'refresh rebinds and re-lists files',
      build: buildCubit,
      act: (cubit) => cubit.refresh(),
      setUp: () {
        when(() => refreshServer.execute()).thenAnswer((_) async {});
        when(
          () => listFiles.execute(),
        ).thenAnswer((_) async => const [_sharedFile]);
      },
      expect: () => const [
        ServerState(isRefreshing: true),
        ServerState(isRefreshing: true, sharedFiles: [_sharedFile]),
        ServerState(isRefreshing: false, sharedFiles: [_sharedFile]),
      ],
    );

    blocTest<ServerCubit, ServerState>(
      'completed uploads refresh the shared-file list',
      build: buildCubit,
      act: (cubit) async {
        await cubit.initialize();
        uploadsController.add(_completedUpload);
        await Future<void>.delayed(Duration.zero);
      },
      expect: () => [
        const ServerState(hudLogsEnabled: true),
        const ServerState(
          hudLogsEnabled: true,
          uploads: [_completedUpload],
        ),
        const ServerState(
          hudLogsEnabled: true,
          uploads: [_completedUpload],
          sharedFiles: [_sharedFile],
        ),
      ],
    );

    blocTest<ServerCubit, ServerState>(
      'pickAndPublishFiles publishes staged files and refreshes the list',
      build: buildCubit,
      act: (cubit) => cubit.pickAndPublishFiles(),
      setUp: () {
        when(
          () => pickHostFiles.execute(),
        ).thenAnswer((_) async => const [_hostFile]);
        when(
          () => publishFiles.execute(any()),
        ).thenAnswer((_) async => const [_sharedFile]);
      },
      expect: () => const [
        ServerState(isPublishing: true),
        ServerState(isPublishing: false),
        ServerState(isPublishing: false, sharedFiles: [_sharedFile]),
      ],
    );

    blocTest<ServerCubit, ServerState>(
      'pickAndPublishFiles skips publishing when nothing is picked',
      build: buildCubit,
      act: (cubit) => cubit.pickAndPublishFiles(),
      setUp: () {
        when(() => pickHostFiles.execute()).thenAnswer((_) async => const []);
      },
      expect: () => const [
        ServerState(isPublishing: true),
        ServerState(isPublishing: false),
      ],
    );

    blocTest<ServerCubit, ServerState>(
      'pickAndPublishFiles surfaces an error on failure',
      build: buildCubit,
      act: (cubit) => cubit.pickAndPublishFiles(),
      setUp: () {
        when(
          () => pickHostFiles.execute(),
        ).thenAnswer((_) async => const [_hostFile]);
        when(
          () => publishFiles.execute(any()),
        ).thenThrow(Exception('boom'));
      },
      expect: () => const [
        ServerState(isPublishing: true),
        ServerState(isPublishing: true, error: 'Failed to publish files'),
        ServerState(isPublishing: false, error: 'Failed to publish files'),
      ],
    );

    test('downloadSharedFile returns the downloaded result', () async {
      const downloaded = DownloadedFile(
        name: 'report.pdf',
        target: DownloadTarget.documents,
        path: '/tmp/report.pdf',
      );
      when(
        () => downloadSharedFile.execute('report.pdf'),
      ).thenAnswer((_) async => downloaded);
      final cubit = buildCubit();

      final result = await cubit.downloadSharedFile('report.pdf');

      expect(result, downloaded);
      expect(result!.target, DownloadTarget.documents);
      verify(() => downloadSharedFile.execute('report.pdf')).called(1);
    });

    test('downloadSharedFile returns null when the file is missing', () async {
      when(
        () => downloadSharedFile.execute(any()),
      ).thenAnswer((_) async => null);
      final cubit = buildCubit();

      expect(await cubit.downloadSharedFile('nope.pdf'), isNull);
    });

    // --- History recording -------------------------------------------------

    test('startServer opens a history session', () async {
      when(
        () => startServer.execute(
          sessionTimeoutMinutes: any(named: 'sessionTimeoutMinutes'),
        ),
      ).thenAnswer((_) async => _activeSession);
      when(
        () => listFiles.execute(),
      ).thenAnswer((_) async => const <ServerSharedFile>[]);

      final cubit = buildCubit();
      await cubit.startServer();

      verify(() => historyRepository.startSession()).called(1);
    });

    test('completed uploads record a received history entry', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      uploadsController.add(_completedUpload);
      await Future<void>.delayed(Duration.zero);

      verify(
        () => historyRepository.addFile(
          any(
            that: isA<HistoryFile>().having(
              (f) => f.kind,
              'kind',
              HistoryFileKind.received,
            ),
          ),
        ),
      ).called(1);
    });

    test('stopServer closes the history session', () async {
      when(() => stopServer.execute()).thenAnswer((_) async {});
      final cubit = buildCubit();

      await cubit.stopServer();

      verify(() => historyRepository.endSession()).called(1);
    });

    test('pickAndPublishFiles records published history entries', () async {
      when(
        () => pickHostFiles.execute(),
      ).thenAnswer((_) async => const [_hostFile]);
      when(
        () => publishFiles.execute(any()),
      ).thenAnswer((_) async => const [_sharedFile]);

      final cubit = buildCubit();
      await cubit.pickAndPublishFiles();

      verify(
        () => historyRepository.addFile(
          any(
            that: isA<HistoryFile>().having(
              (f) => f.kind,
              'kind',
              HistoryFileKind.published,
            ),
          ),
        ),
      ).called(1);
    });

    test('downloadSharedFile records a downloaded history entry', () async {
      const downloaded = DownloadedFile(
        name: 'report.pdf',
        target: DownloadTarget.documents,
        path: '/tmp/report.pdf',
        size: 100,
      );
      when(
        () => downloadSharedFile.execute('report.pdf'),
      ).thenAnswer((_) async => downloaded);

      final cubit = buildCubit();
      await cubit.downloadSharedFile('report.pdf');

      verify(
        () => historyRepository.addFile(
          any(
            that: isA<HistoryFile>().having(
              (f) => f.kind,
              'kind',
              HistoryFileKind.downloaded,
            ),
          ),
        ),
      ).called(1);
    });
  });
}
