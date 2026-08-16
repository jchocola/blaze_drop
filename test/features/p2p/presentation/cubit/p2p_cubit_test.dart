import 'dart:async';

import 'package:blaze_drop/features/p2p/domain/entities/file_item.dart';
import 'package:blaze_drop/features/p2p/domain/entities/incoming_connection_request.dart';
import 'package:blaze_drop/features/p2p/domain/entities/peer_device.dart';
import 'package:blaze_drop/features/p2p/domain/entities/transfer_session.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/ensure_nearby_permission_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/get_local_node_name_use_case.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/open_nearby_settings_use_case.dart';
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
import 'package:blaze_drop/features/p2p/presentation/cubit/p2p_state.dart';
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

class _MockSendFiles extends Mock implements SendFilesUseCase {}

class _MockRespondToRequest extends Mock implements RespondToRequestUseCase {}

class _MockEnsureNearbyPermission extends Mock
    implements EnsureNearbyPermissionUseCase {}

class _MockOpenNearbySettings extends Mock implements OpenNearbySettingsUseCase {}

const _peer = PeerDevice(
  id: 'node-1',
  name: 'ONYX_RIG',
  ipAddress: '192.168.1.45',
  servicePort: 43211,
  platform: PeerPlatform.windows,
  signalStrength: 74,
);

const _fileA = FileItem(name: 'a.zip', path: '/a.zip', size: 10);
const _fileB = FileItem(name: 'b.zip', path: '/b.zip', size: 20);
const _photo = FileItem(
  name: 'photo_001.jpg',
  path: '/tmp/photo_001.jpg',
  size: 2048,
  mimeType: 'image/jpeg',
);

void main() {
  late _MockGetLocalNodeName getLocalNodeName;
  late _MockStartDiscovery startDiscovery;
  late _MockStopDiscovery stopDiscovery;
  late _MockWatchPeers watchPeers;
  late _MockWatchIncoming watchIncoming;
  late _MockWatchTransfers watchTransfers;
  late _MockPickFiles pickFiles;
  late _MockPickGalleryPhotos pickGalleryPhotos;
  late _MockSendFiles sendFiles;
  late _MockRespondToRequest respondToRequest;
  late _MockEnsureNearbyPermission ensureNearbyPermission;
  late _MockOpenNearbySettings openNearbySettings;
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
    getLocalNodeName = _MockGetLocalNodeName();
    startDiscovery = _MockStartDiscovery();
    stopDiscovery = _MockStopDiscovery();
    watchPeers = _MockWatchPeers();
    watchIncoming = _MockWatchIncoming();
    watchTransfers = _MockWatchTransfers();
    pickFiles = _MockPickFiles();
    pickGalleryPhotos = _MockPickGalleryPhotos();
    sendFiles = _MockSendFiles();
    respondToRequest = _MockRespondToRequest();
    ensureNearbyPermission = _MockEnsureNearbyPermission();
    openNearbySettings = _MockOpenNearbySettings();

    peersController = StreamController<List<PeerDevice>>.broadcast();
    incomingController =
        StreamController<IncomingConnectionRequest>.broadcast();
    transfersController = StreamController<TransferSession>.broadcast();

    when(() => getLocalNodeName.execute()).thenAnswer((_) async => 'NODE-TEST');
    when(() => startDiscovery.execute()).thenAnswer((_) async {});
    when(() => stopDiscovery.execute()).thenAnswer((_) async {});
    when(() => ensureNearbyPermission.execute()).thenAnswer((_) async => true);
    when(() => openNearbySettings.execute()).thenAnswer((_) async {});
    when(() => watchPeers.execute()).thenAnswer((_) => peersController.stream);
    when(
      () => watchIncoming.execute(),
    ).thenAnswer((_) => incomingController.stream);
    when(
      () => watchTransfers.execute(),
    ).thenAnswer((_) => transfersController.stream);
  });

  tearDown(() async {
    await peersController.close();
    await incomingController.close();
    await transfersController.close();
  });

  P2pCubit buildCubit() {
    return P2pCubit(
      getLocalNodeNameUseCase: getLocalNodeName,
      startDiscoveryUseCase: startDiscovery,
      stopDiscoveryUseCase: stopDiscovery,
      watchDiscoveredPeersUseCase: watchPeers,
      watchIncomingRequestsUseCase: watchIncoming,
      watchTransferUpdatesUseCase: watchTransfers,
      pickFilesUseCase: pickFiles,
      pickGalleryPhotosUseCase: pickGalleryPhotos,
      sendFilesUseCase: sendFiles,
      respondToRequestUseCase: respondToRequest,
      ensureNearbyPermissionUseCase: ensureNearbyPermission,
      openNearbySettingsUseCase: openNearbySettings,
    );
  }

  group('P2pCubit.initialize', () {
    test('loads node name and starts discovery', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      expect(cubit.state.nodeName, 'NODE-TEST');
      expect(cubit.state.scanStatus, P2pScanStatus.active);
      verify(() => getLocalNodeName.execute()).called(1);
      verify(() => startDiscovery.execute()).called(1);

      await cubit.close();
    });

    test(
      'is idempotent — second initialize does not restart discovery',
      () async {
        final cubit = buildCubit();
        await cubit.initialize();
        await cubit.initialize();
        verify(() => startDiscovery.execute()).called(1);
        await cubit.close();
      },
    );
  });

  group('P2pCubit discovery stream', () {
    test('applies discovered peers to the state', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      peersController.add(const [_peer]);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.peers, const [_peer]);

      peersController.add(const []);
      await Future<void>.delayed(Duration.zero);
      expect(cubit.state.peers, isEmpty);

      await cubit.close();
    });
  });

  group('P2pCubit nearby permission gate', () {
    test('blocks discovery when nearby access is denied', () async {
      final cubit = buildCubit();
      when(
        () => ensureNearbyPermission.execute(),
      ).thenAnswer((_) async => false);

      await cubit.startScan();

      expect(cubit.state.nearbyPermissionDenied, isTrue);
      expect(cubit.state.scanStatus, P2pScanStatus.idle);
      verifyNever(() => startDiscovery.execute());

      await cubit.close();
    });

    test('recovers and scans once access is granted on rescan', () async {
      final cubit = buildCubit();
      when(
        () => ensureNearbyPermission.execute(),
      ).thenAnswer((_) async => false);
      await cubit.startScan();
      expect(cubit.state.nearbyPermissionDenied, isTrue);

      when(
        () => ensureNearbyPermission.execute(),
      ).thenAnswer((_) async => true);
      await cubit.startScan();

      expect(cubit.state.nearbyPermissionDenied, isFalse);
      expect(cubit.state.scanStatus, P2pScanStatus.active);
      verify(() => startDiscovery.execute()).called(1);

      await cubit.close();
    });

    test('openNearbySettings delegates to the use case', () async {
      final cubit = buildCubit();
      await cubit.openNearbySettings();
      verify(() => openNearbySettings.execute()).called(1);
      await cubit.close();
    });
  });

  group('P2pCubit target + payload', () {
    test('selectTarget sets the connected peer and clears payload', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      when(() => pickFiles.execute()).thenAnswer((_) async => const [_fileA]);
      await cubit.pickFiles();
      expect(cubit.state.selectedFiles, hasLength(1));

      cubit.selectTarget(_peer);
      expect(cubit.state.connectedPeer, _peer);
      expect(cubit.state.selectedFiles, isEmpty);
      expect(cubit.state.transfer, isNull);

      await cubit.close();
    });

    test('pickFiles merges staged files without duplicates', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      when(() => pickFiles.execute()).thenAnswer((_) async => const [_fileA]);
      await cubit.pickFiles();
      when(
        () => pickFiles.execute(),
      ).thenAnswer((_) async => const [_fileA, _fileB]);
      await cubit.pickFiles();

      expect(cubit.state.selectedFiles, const [_fileA, _fileB]);

      await cubit.close();
    });

    test('removeFile drops a staged file', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      when(
        () => pickFiles.execute(),
      ).thenAnswer((_) async => const [_fileA, _fileB]);
      await cubit.pickFiles();
      cubit.removeFile(_fileA);

      expect(cubit.state.selectedFiles, const [_fileB]);

      await cubit.close();
    });

    test('clearPayload resets the staged payload', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      when(() => pickFiles.execute()).thenAnswer((_) async => const [_fileA]);
      await cubit.pickFiles();
      cubit.clearPayload();

      expect(cubit.state.selectedFiles, isEmpty);

      await cubit.close();
    });

    test('pickGalleryPhotos stages photos into the payload', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      when(
        () => pickGalleryPhotos.execute(),
      ).thenAnswer((_) async => const [_photo]);
      await cubit.pickGalleryPhotos();

      expect(cubit.state.selectedFiles, const [_photo]);

      await cubit.close();
    });

    test('pickGalleryPhotos merges with files without duplicates', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      when(() => pickFiles.execute()).thenAnswer((_) async => const [_fileA]);
      await cubit.pickFiles();
      when(
        () => pickGalleryPhotos.execute(),
      ).thenAnswer((_) async => const [_photo]);
      await cubit.pickGalleryPhotos();

      expect(cubit.state.selectedFiles, const [_fileA, _photo]);

      await cubit.close();
    });

    test('pickGalleryPhotos surfaces a picker error', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      when(
        () => pickGalleryPhotos.execute(),
      ).thenThrow(Exception('gallery denied'));
      await cubit.pickGalleryPhotos();

      expect(cubit.state.error, isNotNull);

      await cubit.close();
    });
  });

  group('P2pCubit send flow', () {
    test('sendFiles drives sending → completed via transfer stream', () async {
      final cubit = buildCubit();
      await cubit.initialize();
      cubit.selectTarget(_peer);
      when(() => pickFiles.execute()).thenAnswer((_) async => const [_fileA]);
      await cubit.pickFiles();

      const completed = TransferSession(
        sessionId: 's-1',
        peer: _peer,
        direction: TransferDirection.outgoing,
        files: [_fileA],
        status: TransferStatus.completed,
        progress: 1,
        bytesTotal: 10,
        bytesTransferred: 10,
      );
      when(() => sendFiles.execute(any(), any())).thenAnswer((_) async {
        transfersController.add(completed);
        return completed;
      });

      await cubit.sendFiles();
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.transfer?.status, TransferStatus.completed);
      expect(cubit.state.isSending, isFalse);
      verify(() => sendFiles.execute(_peer, const [_fileA])).called(1);

      await cubit.close();
    });

    test('sendFiles surfaces failures via error state', () async {
      final cubit = buildCubit();
      await cubit.initialize();
      cubit.selectTarget(_peer);
      when(() => pickFiles.execute()).thenAnswer((_) async => const [_fileA]);
      await cubit.pickFiles();

      when(
        () => sendFiles.execute(any(), any()),
      ).thenThrow(Exception('Connection declined by peer'));

      await cubit.sendFiles();

      expect(cubit.state.isSending, isFalse);
      expect(cubit.state.error, isNotNull);

      await cubit.close();
    });
  });

  group('P2pCubit incoming requests', () {
    test('incoming request sets pendingRequest', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      final request = IncomingConnectionRequest(
        requestId: 'req-1',
        sender: _peer,
        files: const [_fileA, _fileB],
      );
      incomingController.add(request);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.pendingRequest?.requestId, 'req-1');
      expect(cubit.state.pendingRequest?.totalBytes, 30);

      await cubit.close();
    });

    test('acceptRequest clears the request and responds', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      incomingController.add(
        IncomingConnectionRequest(requestId: 'req-2', sender: _peer),
      );
      await Future<void>.delayed(Duration.zero);
      when(
        () => respondToRequest.execute(accept: true),
      ).thenAnswer((_) async {});

      await cubit.acceptRequest();

      expect(cubit.state.pendingRequest, isNull);
      verify(() => respondToRequest.execute(accept: true)).called(1);

      await cubit.close();
    });

    test('declineRequest clears the request and responds', () async {
      final cubit = buildCubit();
      await cubit.initialize();

      incomingController.add(
        IncomingConnectionRequest(requestId: 'req-3', sender: _peer),
      );
      await Future<void>.delayed(Duration.zero);
      when(
        () => respondToRequest.execute(accept: false),
      ).thenAnswer((_) async {});

      await cubit.declineRequest();

      expect(cubit.state.pendingRequest, isNull);
      verify(() => respondToRequest.execute(accept: false)).called(1);

      await cubit.close();
    });
  });
}
