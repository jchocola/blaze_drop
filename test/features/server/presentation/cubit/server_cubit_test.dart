import 'dart:async';

import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/core/config/settings_repository.dart';
import 'package:blaze_drop/features/server/domain/entities/connected_client.dart';
import 'package:blaze_drop/features/server/domain/entities/server_session.dart';
import 'package:blaze_drop/features/server/domain/entities/server_shared_file.dart';
import 'package:blaze_drop/features/server/domain/entities/server_upload_event.dart';
import 'package:blaze_drop/features/server/domain/use_cases/list_shared_files_use_case.dart';
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

class _MockSettingsRepository extends Mock implements SettingsRepository {}

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

void main() {
  group('ServerCubit', () {
    late _MockStartServer startServer;
    late _MockStopServer stopServer;
    late _MockRefreshServer refreshServer;
    late _MockWatchStatus watchStatus;
    late _MockWatchClients watchClients;
    late _MockWatchUploads watchUploads;
    late _MockListFiles listFiles;
    late _MockSettingsRepository settingsRepository;
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
      settingsRepository = _MockSettingsRepository();
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
        settingsRepository: settingsRepository,
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
      'upload events are prepended newest-first',
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
      ],
    );
  });
}
