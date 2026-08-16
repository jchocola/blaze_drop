import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/logger.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/incoming_connection_request.dart';
import '../../domain/entities/peer_device.dart';
import '../../domain/entities/transfer_session.dart';
import '../../domain/use_cases/ensure_nearby_permission_use_case.dart';
import '../../domain/use_cases/get_local_node_name_use_case.dart';
import '../../domain/use_cases/open_nearby_settings_use_case.dart';
import '../../domain/use_cases/pick_files_use_case.dart';
import '../../domain/use_cases/pick_gallery_photos_use_case.dart';
import '../../domain/use_cases/respond_to_request_use_case.dart';
import '../../domain/use_cases/send_files_use_case.dart';
import '../../domain/use_cases/start_discovery_use_case.dart';
import '../../domain/use_cases/stop_discovery_use_case.dart';
import '../../domain/use_cases/watch_discovered_peers_use_case.dart';
import '../../domain/use_cases/watch_incoming_requests_use_case.dart';
import '../../domain/use_cases/watch_transfer_updates_use_case.dart';
import 'p2p_state.dart';

/// Orchestrates the Module B P2P flow (FUNCTIONALITY.md §4):
///
/// discovery → target selection → payload staging → BLAZE SEND, and the
/// mirrored receive path (incoming request overlay → accept → receive).
///
/// The cubit contains no business logic — it delegates to use cases and maps
/// results into immutable [P2pState]s (RULE.md §2).
class P2pCubit extends Cubit<P2pState> {
  P2pCubit({
    required this.getLocalNodeNameUseCase,
    required this.startDiscoveryUseCase,
    required this.stopDiscoveryUseCase,
    required this.watchDiscoveredPeersUseCase,
    required this.watchIncomingRequestsUseCase,
    required this.watchTransferUpdatesUseCase,
    required this.pickFilesUseCase,
    required this.pickGalleryPhotosUseCase,
    required this.sendFilesUseCase,
    required this.respondToRequestUseCase,
    required this.ensureNearbyPermissionUseCase,
    required this.openNearbySettingsUseCase,
  }) : super(const P2pState());

  final GetLocalNodeNameUseCase getLocalNodeNameUseCase;
  final StartDiscoveryUseCase startDiscoveryUseCase;
  final StopDiscoveryUseCase stopDiscoveryUseCase;
  final WatchDiscoveredPeersUseCase watchDiscoveredPeersUseCase;
  final WatchIncomingRequestsUseCase watchIncomingRequestsUseCase;
  final WatchTransferUpdatesUseCase watchTransferUpdatesUseCase;
  final PickGalleryPhotosUseCase pickGalleryPhotosUseCase;
  final PickFilesUseCase pickFilesUseCase;
  final SendFilesUseCase sendFilesUseCase;
  final RespondToRequestUseCase respondToRequestUseCase;

  /// Gates discovery behind the Android "Nearby devices" runtime permission.
  final EnsureNearbyPermissionUseCase ensureNearbyPermissionUseCase;
  final OpenNearbySettingsUseCase openNearbySettingsUseCase;

  StreamSubscription<List<PeerDevice>>? _peersSub;
  StreamSubscription<IncomingConnectionRequest>? _incomingSub;
  StreamSubscription<TransferSession>? _transferSub;
  bool _initialized = false;

  /// Boots the node: reads identity, subscribes to transport streams and
  /// starts discovery. Idempotent.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    try {
      final name = await getLocalNodeNameUseCase.execute();
      if (!isClosed) {
        emit(state.copyWith(nodeName: name));
      }
    } catch (error, stack) {
      AppLogger.error('Failed to read node identity', error, stack);
    }
    _peersSub = watchDiscoveredPeersUseCase.execute().listen((peers) {
      if (!isClosed) {
        emit(state.copyWith(peers: peers));
      }
    }, onError: _onStreamError);
    _incomingSub = watchIncomingRequestsUseCase.execute().listen((request) {
      if (!isClosed) {
        emit(state.copyWith(pendingRequest: request));
      }
    }, onError: _onStreamError);
    _transferSub = watchTransferUpdatesUseCase.execute().listen((session) {
      if (isClosed) {
        return;
      }
      final sending =
          session.direction == TransferDirection.outgoing &&
          (session.status == TransferStatus.transferring ||
              session.status == TransferStatus.pending);
      emit(state.copyWith(transfer: session, isSending: sending));
    }, onError: _onStreamError);
    await startScan();
  }

  void _onStreamError(Object error, StackTrace stack) {
    AppLogger.error('P2P stream error', error, stack);
    if (!isClosed) {
      emit(state.copyWith(error: 'Peer stream error: $error'));
    }
  }

  /// (Re)starts the discovery engine. On Android this first ensures the
  /// "Nearby devices" runtime permission — if the user denies it, discovery
  /// is blocked and the UI shows a grant prompt instead.
  Future<void> startScan() async {
    emit(state.copyWith(
      scanStatus: P2pScanStatus.scanning,
      error: null,
      nearbyPermissionDenied: false,
    ));
    try {
      final allowed = await ensureNearbyPermissionUseCase.execute();
      if (!allowed) {
        AppLogger.warning(
          'Nearby devices access denied — P2P discovery blocked',
        );
        if (!isClosed) {
          emit(state.copyWith(
            scanStatus: P2pScanStatus.idle,
            nearbyPermissionDenied: true,
            error: 'Nearby access is required to discover devices',
          ));
        }
        return;
      }
      await startDiscoveryUseCase.execute();
      if (!isClosed) {
        emit(state.copyWith(scanStatus: P2pScanStatus.active));
      }
    } catch (error, stack) {
      AppLogger.error('Failed to start P2P scan', error, stack);
      if (!isClosed) {
        emit(
          state.copyWith(
            scanStatus: P2pScanStatus.idle,
            error: 'Discovery failed',
          ),
        );
      }
    }
  }

  /// Opens the OS settings page so the user can re-enable a permanently
  /// denied "Nearby devices" permission.
  Future<void> openNearbySettings() async {
    try {
      await openNearbySettingsUseCase.execute();
    } catch (error, stack) {
      AppLogger.error('Failed to open app settings', error, stack);
    }
  }

  /// Stops the discovery engine (called when leaving the grid screen).
  Future<void> stopScan() async {
    try {
      await stopDiscoveryUseCase.execute();
    } catch (error, stack) {
      AppLogger.error('Failed to stop P2P scan', error, stack);
    }
    if (!isClosed) {
      emit(state.copyWith(scanStatus: P2pScanStatus.idle));
    }
  }

  /// Marks [peer] as the transfer target (navigates to the transfer page).
  void selectTarget(PeerDevice peer) {
    emit(
      state.copyWith(
        connectedPeer: peer,
        selectedFiles: const [],
        transfer: null,
        error: null,
      ),
    );
  }

  /// Clears the current target (back to the grid).
  void clearTarget() {
    emit(state.copyWith(connectedPeer: null));
  }

  /// Opens the native file picker and stages the chosen files.
  Future<void> pickFiles() async {
    try {
      final picked = await pickFilesUseCase.execute();
      if (picked.isEmpty || isClosed) {
        return;
      }
      final existing = state.selectedFiles.map((f) => f.path).toSet();
      final merged = [
        ...state.selectedFiles,
        ...picked.where((f) => !existing.contains(f.path)),
      ];
      emit(state.copyWith(selectedFiles: merged, error: null));
      AppLogger.debug('Staged ${merged.length} file(s) for transfer');
    } catch (error, stack) {
      AppLogger.error('Failed to pick files', error, stack);
      if (!isClosed) {
        emit(state.copyWith(error: 'Failed to open file picker'));
      }
    }
  }

  /// Opens the device photo gallery and stages the chosen photos alongside
  /// any already-selected payload items.
  Future<void> pickGalleryPhotos() async {
    try {
      final picked = await pickGalleryPhotosUseCase.execute();
      if (picked.isEmpty || isClosed) {
        return;
      }
      final existing = state.selectedFiles.map((f) => f.path).toSet();
      final merged = [
        ...state.selectedFiles,
        ...picked.where((f) => !existing.contains(f.path)),
      ];
      emit(state.copyWith(selectedFiles: merged, error: null));
      AppLogger.debug(
        'Staged ${merged.length} file(s) from gallery for transfer',
      );
    } catch (error, stack) {
      AppLogger.error('Failed to pick gallery photos', error, stack);
      if (!isClosed) {
        emit(state.copyWith(error: 'Failed to open gallery picker'));
      }
    }
  }

  /// Removes [file] from the staged payload.
  void removeFile(FileItem file) {
    emit(
      state.copyWith(
        selectedFiles: state.selectedFiles
            .where((f) => f.path != file.path)
            .toList(),
      ),
    );
  }

  /// Clears the staged payload and any stale transfer.
  void clearPayload() {
    emit(state.copyWith(selectedFiles: const [], transfer: null, error: null));
  }

  /// Starts the chunked transfer of the staged payload to [connectedPeer].
  Future<void> sendFiles() async {
    final peer = state.connectedPeer;
    if (peer == null || state.selectedFiles.isEmpty || state.isSending) {
      return;
    }
    emit(state.copyWith(isSending: true, transfer: null, error: null));
    AppLogger.info(
      'Sending ${state.selectedFiles.length} file(s) to ${peer.name}',
    );
    try {
      await sendFilesUseCase.execute(peer, state.selectedFiles);
    } catch (error, stack) {
      AppLogger.error('Send failed', error, stack);
      if (!isClosed) {
        emit(state.copyWith(isSending: false, error: error.toString()));
      }
    }
  }

  /// Accepts the pending incoming connection request.
  Future<void> acceptRequest() async {
    final request = state.pendingRequest;
    if (request == null) {
      return;
    }
    emit(state.copyWith(pendingRequest: null));
    try {
      await respondToRequestUseCase.execute(accept: true);
    } catch (error, stack) {
      AppLogger.error('Failed to accept request', error, stack);
    }
  }

  /// Declines the pending incoming connection request.
  Future<void> declineRequest() async {
    final request = state.pendingRequest;
    if (request == null) {
      return;
    }
    emit(state.copyWith(pendingRequest: null));
    try {
      await respondToRequestUseCase.execute(accept: false);
    } catch (error, stack) {
      AppLogger.error('Failed to decline request', error, stack);
    }
  }

  @override
  Future<void> close() async {
    // Fire-and-forget the cleanup: awaiting subscription cancellations from
    // inside `close()` can deadlock the test binding's fake-async zone (the
    // bloc's `_stateController.close()` waits for all listeners to detach).
    unawaited(_peersSub?.cancel());
    unawaited(_incomingSub?.cancel());
    unawaited(_transferSub?.cancel());
    _peersSub = null;
    _incomingSub = null;
    _transferSub = null;
    unawaited(stopDiscoveryUseCase.execute().catchError((Object _) {}));
    await super.close();
  }
}
