import 'dart:async';

import 'package:blaze_drop/core/theme/theme.dart';
import 'package:blaze_drop/features/p2p/domain/entities/file_item.dart';
import 'package:blaze_drop/features/p2p/domain/entities/incoming_connection_request.dart';
import 'package:blaze_drop/features/p2p/domain/entities/peer_device.dart';
import 'package:blaze_drop/features/p2p/domain/entities/transfer_session.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/capture_photo_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/get_local_node_name_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/pick_files_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/pick_gallery_photos_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/respond_to_request_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/send_files_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/start_discovery_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/stop_discovery_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/watch_discovered_peers_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/watch_incoming_requests_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/watch_transfer_updates_use_case.dart';
import 'package:blaze_drop/features/p2p/presentation/cubit/p2p_cubit.dart';
import 'package:blaze_drop/features/p2p/presentation/pages/p2p_discovery_page.dart';
import 'package:blaze_drop/features/p2p/presentation/pages/p2p_transfer_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockGetLocalNodeName extends Mock implements GetLocalNodeNameUseCase {}

class _MockStartDiscovery extends Mock implements StartDiscoveryUseCase {}

class _MockStopDiscovery extends Mock implements StopDiscoveryUseCase {}

class _MockWatchPeers extends Mock implements WatchDiscoveredPeersUseCase {}

class _MockWatchIncoming extends Mock implements WatchIncomingRequestsUseCase {}

class _MockWatchTransfers extends Mock implements WatchTransferUpdatesUseCase {}

class _MockPickFiles extends Mock implements PickFilesUseCase {}

class _MockPickGalleryPhotos extends Mock implements PickGalleryPhotosUseCase {}

class _MockCapturePhoto extends Mock implements CapturePhotoUseCase {}

class _MockSendFiles extends Mock implements SendFilesUseCase {}

class _MockRespondToRequest extends Mock implements RespondToRequestUseCase {}

const _peer = PeerDevice(
  id: 'node-1',
  name: 'ONYX_RIG',
  ipAddress: '192.168.1.45',
  servicePort: 43211,
  platform: PeerPlatform.windows,
  signalStrength: 74,
);

const _file = FileItem(
  name: 'system_override.zip',
  path: '/tmp/system_override.zip',
  size: 420 * 1024 * 1024,
);

void main() {
  late StreamController<List<PeerDevice>> peersController;
  late StreamController<IncomingConnectionRequest> incomingController;
  late StreamController<TransferSession> transfersController;

  setUpAll(() {
    registerFallbackValue(
      const PeerDevice(
        id: 'fb',
        name: 'FALLBACK',
        ipAddress: '0.0.0.0',
        servicePort: 1,
      ),
    );
    registerFallbackValue(const <FileItem>[]);
  });

  setUp(() {
    peersController = StreamController<List<PeerDevice>>.broadcast();
    incomingController = StreamController<IncomingConnectionRequest>.broadcast();
    transfersController = StreamController<TransferSession>.broadcast();
  });

  tearDown(() async {
    await peersController.close();
    await incomingController.close();
    await transfersController.close();
  });

  P2pCubit buildCubit() {
    final getLocalNodeName = _MockGetLocalNodeName();
    final startDiscovery = _MockStartDiscovery();
    final stopDiscovery = _MockStopDiscovery();
    final watchPeers = _MockWatchPeers();
    final watchIncoming = _MockWatchIncoming();
    final watchTransfers = _MockWatchTransfers();
    final pickFiles = _MockPickFiles();
    final pickGalleryPhotos = _MockPickGalleryPhotos();
    final capturePhoto = _MockCapturePhoto();
    final sendFiles = _MockSendFiles();
    final respondToRequest = _MockRespondToRequest();

    when(() => getLocalNodeName.execute()).thenAnswer((_) async => 'NODE-TEST');
    when(() => startDiscovery.execute()).thenAnswer((_) async {});
    when(() => stopDiscovery.execute()).thenAnswer((_) async {});
    when(
      () => watchPeers.execute(),
    ).thenAnswer((_) => peersController.stream);
    when(
      () => watchIncoming.execute(),
    ).thenAnswer((_) => incomingController.stream);
    when(
      () => watchTransfers.execute(),
    ).thenAnswer((_) => transfersController.stream);
    when(() => pickFiles.execute()).thenAnswer((_) async => const [_file]);
    when(
      () => pickGalleryPhotos.execute(),
    ).thenAnswer((_) async => const [_file]);
    when(() => capturePhoto.execute()).thenAnswer((_) async => const [_file]);
    when(
      () => sendFiles.execute(any(), any()),
    ).thenAnswer((_) async {
      transfersController.add(
        const TransferSession(
          sessionId: 's-1',
          peer: _peer,
          direction: TransferDirection.outgoing,
          files: [_file],
          status: TransferStatus.completed,
          progress: 1,
          bytesTotal: 420 * 1024 * 1024,
          bytesTransferred: 420 * 1024 * 1024,
        ),
      );
      return const TransferSession(
        sessionId: 's-1',
        peer: _peer,
        direction: TransferDirection.outgoing,
        files: [_file],
        status: TransferStatus.completed,
        progress: 1,
        bytesTotal: 420 * 1024 * 1024,
        bytesTransferred: 420 * 1024 * 1024,
      );
    });

    return P2pCubit(
      getLocalNodeNameUseCase: getLocalNodeName,
      startDiscoveryUseCase: startDiscovery,
      stopDiscoveryUseCase: stopDiscovery,
      watchDiscoveredPeersUseCase: watchPeers,
      watchIncomingRequestsUseCase: watchIncoming,
      watchTransferUpdatesUseCase: watchTransfers,
      pickFilesUseCase: pickFiles,
      pickGalleryPhotosUseCase: pickGalleryPhotos,
      capturePhotoUseCase: capturePhoto,
      sendFilesUseCase: sendFiles,
      respondToRequestUseCase: respondToRequest,
    );
  }

  Widget wrap(P2pCubit cubit, Widget child) {
    // `.value` — the test owns the cubit lifecycle and closes it explicitly.
    return BlocProvider<P2pCubit>.value(
      value: cubit,
      child: MaterialApp(theme: AppTheme.dark, home: child),
    );
  }

  Future<void> pumpDiscovery(
    WidgetTester tester,
    P2pCubit cubit,
  ) async {
    await tester.pumpWidget(wrap(cubit, const P2pDiscoveryPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
  }

  testWidgets('discovery page renders header, radar prompt and peer list', (
    tester,
  ) async {
    final cubit = buildCubit();
    await pumpDiscovery(tester, cubit);

    expect(find.text('LOCAL NETWORK GRID'), findsWidgets);
    expect(find.textContaining('ANALYZING P2P SPECTRUM'), findsWidgets);

    // Push a discovered peer into the grid.
    peersController.add(const [_peer]);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('ONYX_RIG'), findsOneWidget);
    expect(find.textContaining('192.168.1.45'), findsOneWidget);
    expect(find.text('74%'), findsOneWidget);

    // Tear down the page (stops the radar ticker) before closing the cubit.
    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('incoming connection request overlay renders accept/decline', (
    tester,
  ) async {
    final cubit = buildCubit();
    await pumpDiscovery(tester, cubit);

    incomingController.add(
      IncomingConnectionRequest(
        requestId: 'req-1',
        sender: _peer,
        files: const [_file],
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('INCOMING CONNECTION REQUEST'), findsOneWidget);
    expect(find.text('ONYX_RIG'), findsWidgets);
    expect(find.text('PAYLOAD MANIFEST (1 ITEM)'), findsOneWidget);
    expect(find.text('system_override.zip'), findsOneWidget);
    expect(find.text('ACCEPT'), findsOneWidget);
    expect(find.text('DECLINE'), findsOneWidget);

    // Tapping ACCEPT answers the request.
    await tester.tap(find.text('ACCEPT'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(find.text('INCOMING CONNECTION REQUEST'), findsNothing);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('transfer page renders target, payload and BLAZE SEND', (
    tester,
  ) async {
    final cubit = buildCubit();
    await cubit.initialize();
    cubit.selectTarget(_peer);
    await cubit.pickFiles();

    await tester.pumpWidget(wrap(cubit, const P2pTransferPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('TARGET ACQUIRED'), findsWidgets);
    expect(find.text('ONYX_RIG'), findsWidgets);
    expect(find.text('system_override.zip'), findsOneWidget);
    expect(find.text('420 MB'), findsWidgets);
    expect(find.text('BLAZE SEND'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('transfer page source sheet stages gallery photos', (
    tester,
  ) async {
    final cubit = buildCubit();
    await cubit.initialize();
    cubit.selectTarget(_peer);

    await tester.pumpWidget(wrap(cubit, const P2pTransferPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    await tester.tap(find.text('TAP OR DRAG FILES HERE'));
    await tester.pumpAndSettle();

    expect(find.text('STAGE PAYLOAD FROM'), findsOneWidget);
    expect(find.text('GALLERY'), findsOneWidget);
    expect(find.text('CAMERA'), findsOneWidget);

    await tester.tap(find.text('GALLERY'));
    await tester.pumpAndSettle();

    expect(cubit.state.selectedFiles, const [_file]);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });

  testWidgets('transfer page shows the speedometer gauge while sending', (
    tester,
  ) async {
    final cubit = buildCubit();
    await cubit.initialize();
    cubit.selectTarget(_peer);
    await cubit.pickFiles();

    transfersController.add(
      const TransferSession(
        sessionId: 's-1',
        peer: _peer,
        direction: TransferDirection.outgoing,
        files: [_file],
        status: TransferStatus.transferring,
        progress: 0.5,
        bytesTotal: 420 * 1024 * 1024,
        bytesTransferred: 210 * 1024 * 1024,
        speedBytesPerSecond: 45 * 1024 * 1024,
      ),
    );
    await tester.pumpWidget(wrap(cubit, const P2pTransferPage()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    expect(find.text('50%'), findsOneWidget);
    expect(find.textContaining('UPLOAD SPEED'), findsOneWidget);
    expect(find.textContaining('45.0 MB/s'), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await cubit.close();
  });
}
