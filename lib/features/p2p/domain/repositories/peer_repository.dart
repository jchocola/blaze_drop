import '../entities/file_item.dart';
import '../entities/incoming_connection_request.dart';
import '../entities/peer_device.dart';
import '../entities/transfer_session.dart';

/// Abstraction over the P2P transport (FUNCTIONALITY.md §4).
///
/// The domain layer only sees this interface; concrete implementations live
/// in the data layer and may use UDP/TCP sockets, WiFi Direct, mDNS or any
/// other transport. Use cases and cubits depend on this interface alone.
abstract interface class PeerRepository {
  /// Name advertised for this node (persisted across restarts).
  Future<String> getLocalNodeName();

  /// Starts LAN discovery and returns a stream of the current peer list.
  ///
  /// The stream re-emits on every auto-refresh (every 5s) and prunes peers
  /// that stopped responding (10s timeout).
  Stream<List<PeerDevice>> watchDiscoveredPeers();

  /// Begins broadcasting + listening for beacons. Idempotent.
  Future<void> startDiscovery();

  /// Stops broadcasting + listening. Idempotent.
  Future<void> stopDiscovery();

  /// Responds to the currently pending incoming request.
  Future<void> respondToRequest({required bool accept});

  /// Stream of incoming connection requests (each must be answered).
  Stream<IncomingConnectionRequest> watchIncomingRequests();

  /// Stream of live transfer updates (progress, completion, failure).
  Stream<TransferSession> watchTransferUpdates();

  /// Opens the system file picker (multi-select).
  Future<List<FileItem>> pickFiles();

  /// Opens the device photo gallery (multi-select) and returns photos staged
  /// for transfer.
  Future<List<FileItem>> pickGalleryPhotos();

  /// Opens the system camera for a single shot and returns it staged for
  /// transfer (an empty list when the shot is cancelled).
  Future<List<FileItem>> capturePhoto();

  /// Sends [files] to [peer] using the established socket. Reports progress
  /// via [onProgress] (transferredBytes, totalBytes) and resolves with the
  /// final session.
  Future<TransferSession> sendFiles(
    PeerDevice peer,
    List<FileItem> files, {
    void Function(int transferred, int total)? onProgress,
  });

  /// Directory where received files are stored (e.g. `Documents/BlazeDrop`).
  Future<String> getInboxDirectory();
}
