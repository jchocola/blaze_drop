import '../../domain/entities/file_item.dart';
import '../../domain/entities/incoming_connection_request.dart';
import '../../domain/entities/peer_device.dart';
import '../../domain/entities/transfer_session.dart';

/// Abstraction over the raw P2P transport (UDP discovery + TCP transfer).
///
/// The repository delegates to this interface; implementations may swap the
/// underlying mechanism (pure sockets, WiFi Direct, mDNS) without touching
/// the domain layer.
abstract interface class PeerTransportDataSource {
  /// Unique id of the local node.
  String get nodeId;

  /// Live list of discovered peers (re-emitted on every auto-refresh).
  Stream<List<PeerDevice>> watchPeers();

  /// Starts UDP beaconing + TCP listening. Idempotent.
  Future<void> startDiscovery();

  /// Stops beaconing + listening. Idempotent.
  Future<void> stopDiscovery();

  /// Answers the currently pending incoming connection request.
  Future<void> respondToRequest({required bool accept});

  /// Stream of incoming connection requests (one at a time).
  Stream<IncomingConnectionRequest> watchIncomingRequests();

  /// Stream of live transfer updates (both directions).
  Stream<TransferSession> watchTransferUpdates();

  /// Performs the full handshake + chunked transfer of [files] to [peer].
  Future<TransferSession> sendFiles(
    PeerDevice peer,
    List<FileItem> files, {
    void Function(int transferred, int total)? onProgress,
  });

  /// Releases all sockets and timers.
  Future<void> dispose();
}
