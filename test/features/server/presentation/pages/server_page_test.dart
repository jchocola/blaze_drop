import 'dart:async';

import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/core/config/settings_repository.dart';
import 'package:blaze_drop/core/constants/constants.dart';
import 'package:blaze_drop/core/theme/theme.dart';
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
import 'package:blaze_drop/features/server/presentation/pages/server_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
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

const _sharedFile = ServerSharedFile(
  id: 'manifest.json',
  name: 'manifest.json',
  path: '/tmp/manifest.json',
  size: 2048,
);

void main() {
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
    clientsController = StreamController<List<ConnectedClient>>.broadcast();
    uploadsController = StreamController<ServerUploadEvent>.broadcast();

    when(
      () => settingsRepository.loadConfig(),
    ).thenAnswer((_) async => AppConfig.defaults);
    when(() => watchStatus.execute()).thenAnswer((_) => statusController.stream);
    when(
      () => watchClients.execute(),
    ).thenAnswer((_) => clientsController.stream);
    when(
      () => watchUploads.execute(),
    ).thenAnswer((_) => uploadsController.stream);
    when(
      () => startServer.execute(
        sessionTimeoutMinutes: any(named: 'sessionTimeoutMinutes'),
      ),
    ).thenAnswer((_) async => _activeSession);
    when(() => listFiles.execute()).thenAnswer((_) async => const [_sharedFile]);
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

  Widget buildApp(ServerCubit cubit) {
    // A fresh router per test: the app's global `appRouter` is a singleton and
    // would leak navigation state between tests.
    final router = GoRouter(
      initialLocation: AppConstants.serverPath,
      routes: [
        GoRoute(
          path: AppConstants.homePath,
          builder: (_, _) => const Scaffold(body: Center(child: Text('HOME'))),
        ),
        GoRoute(
          path: AppConstants.serverPath,
          builder: (_, _) => const ServerPage(),
        ),
      ],
    );
    return BlocProvider.value(
      value: cubit,
      child: MaterialApp.router(theme: AppTheme.dark, routerConfig: router),
    );
  }

  testWidgets('transitions to the SERVER ACTIVE hub view', (tester) async {
    final cubit = buildCubit();
    await tester.pumpWidget(buildApp(cubit));
    await tester.pump(); // init + start futures resolve
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('RELAY HUB'), findsOneWidget);
    expect(find.text('SERVER ACTIVE'), findsOneWidget);
    expect(find.text('LOCAL_BROADCAST_BEACON'), findsOneWidget);
    expect(find.text('STOP SERVER'), findsOneWidget);
    expect(find.text('tcp://192.168.1.10:8080'), findsOneWidget);

    await tester.scrollUntilVisible(
      find.text('manifest.json'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('manifest.json'), findsOneWidget);
  });

  testWidgets('renders connected guests in ACTIVE_CONNECTIONS', (tester) async {
    final cubit = buildCubit();
    await tester.pumpWidget(buildApp(cubit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    clientsController.add(
      const [ConnectedClient(id: 'x', name: 'NODE-X', ipAddress: '10.0.0.5')],
    );
    await tester.pump();

    await tester.scrollUntilVisible(
      find.text('NODE-X'),
      120,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('NODE-X'), findsOneWidget);
    expect(find.text('10.0.0.5'), findsOneWidget);
  });

  testWidgets('STOP SERVER calls the stop flow', (tester) async {
    when(() => stopServer.execute()).thenAnswer((_) async {});
    final cubit = buildCubit();
    await tester.pumpWidget(buildApp(cubit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.tap(find.text('STOP SERVER'));
    await tester.pump();

    verify(() => stopServer.execute()).called(1);
  });
}
