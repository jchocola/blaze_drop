import '../../domain/entities/connected_client.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/server_shared_file.dart';
import '../../domain/entities/server_upload_event.dart';

/// Abstraction over the raw HTTP relay transport (shelf server + web client).
///
/// The repository delegates to this interface; implementations can swap the
/// underlying stack (shelf, dart:io HttpServer, …) without touching the
/// domain layer.
abstract interface class WebServerTransport {
  /// Binds the hub. Tries [preferredPort] upward, then an OS-assigned port.
  /// [sessionTimeoutMinutes] controls guest pruning.
  Future<ServerSession> start({
    required int preferredPort,
    required int sessionTimeoutMinutes,
  });

  /// Unbinds the hub and clears all state.
  Future<void> stop();

  /// Restarts the hub, usually on a fresh port.
  Future<void> refresh();

  /// Live hub status.
  Stream<ServerSession> watchStatus();

  /// Live connected-guest list.
  Stream<List<ConnectedClient>> watchClients();

  /// Live incoming-upload events.
  Stream<ServerUploadEvent> watchUploads();

  /// Files currently shareable on the hub.
  Future<List<ServerSharedFile>> listFiles();

  /// Local IPv4 address.
  Future<String> getLocalIp();

  /// Directory where uploads are persisted.
  Future<String> getSharedDirectory();

  /// Releases sockets and timers.
  Future<void> dispose();
}
