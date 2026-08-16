import 'package:equatable/equatable.dart';

import '../../domain/entities/file_item.dart';
import '../../domain/entities/incoming_connection_request.dart';
import '../../domain/entities/peer_device.dart';
import '../../domain/entities/transfer_session.dart';

/// Lifecycle of the discovery engine on this node.
enum P2pScanStatus {
  /// Not scanning.
  idle,

  /// Starting up (binding sockets, broadcasting).
  scanning,

  /// Actively discovering peers.
  active,
}

/// UI state for the Module B P2P flow (FUNCTIONALITY.md §4).
class P2pState extends Equatable {
  const P2pState({
    this.nodeName = '',
    this.scanStatus = P2pScanStatus.idle,
    this.peers = const [],
    this.connectedPeer,
    this.pendingRequest,
    this.selectedFiles = const [],
    this.transfer,
    this.isSending = false,
    this.nearbyPermissionDenied = false,
    this.error,
  });

  /// Advertised name of the local node.
  final String nodeName;

  final P2pScanStatus scanStatus;

  /// Currently discovered peers (sorted by signal strength).
  final List<PeerDevice> peers;

  /// The peer the user tapped as a transfer target.
  final PeerDevice? connectedPeer;

  /// Incoming connection request awaiting an accept/decline decision.
  final IncomingConnectionRequest? pendingRequest;

  /// Files staged for sending.
  final List<FileItem> selectedFiles;

  /// The active (or last completed) transfer session.
  final TransferSession? transfer;

  /// True while an outgoing transfer is in flight.
  final bool isSending;

  /// True when the Android "Nearby devices" permission was denied and
  /// discovery cannot run until the user grants it.
  final bool nearbyPermissionDenied;

  final String? error;

  /// Total size of the staged payload.
  int get payloadBytes => selectedFiles.fold(0, (sum, f) => sum + f.size);

  P2pState copyWith({
    String? nodeName,
    P2pScanStatus? scanStatus,
    List<PeerDevice>? peers,
    PeerDevice? connectedPeer,
    Object? pendingRequest = _unset,
    List<FileItem>? selectedFiles,
    TransferSession? transfer,
    Object? isSending = _unset,
    Object? nearbyPermissionDenied = _unset,
    Object? error = _unset,
  }) {
    return P2pState(
      nodeName: nodeName ?? this.nodeName,
      scanStatus: scanStatus ?? this.scanStatus,
      peers: peers ?? this.peers,
      connectedPeer: connectedPeer ?? this.connectedPeer,
      pendingRequest: identical(pendingRequest, _unset)
          ? this.pendingRequest
          : pendingRequest as IncomingConnectionRequest?,
      selectedFiles: selectedFiles ?? this.selectedFiles,
      transfer: transfer ?? this.transfer,
      isSending: identical(isSending, _unset)
          ? this.isSending
          : isSending as bool,
      nearbyPermissionDenied: identical(nearbyPermissionDenied, _unset)
          ? this.nearbyPermissionDenied
          : nearbyPermissionDenied as bool,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  static const _unset = Object();

  @override
  List<Object?> get props => [
    nodeName,
    scanStatus,
    peers,
    connectedPeer,
    pendingRequest,
    selectedFiles,
    transfer,
    isSending,
    nearbyPermissionDenied,
    error,
  ];
}
