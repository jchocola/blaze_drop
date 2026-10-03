import '../entities/connected_client.dart';
import '../entities/downloaded_file.dart';
import '../entities/host_publish_file.dart';
import '../entities/server_session.dart';
import '../entities/server_shared_file.dart';
import '../entities/server_upload_event.dart';

/// Abstraction over the local HTTP relay hub (FUNCTIONALITY.md §5).
///
/// The domain layer only sees this interface; the data layer implements it
/// with a `shelf` server plus the embedded web client. Use cases and cubits
/// depend on this interface alone.
abstract interface class ServerRepository {
  /// Activates the hub on a free port (tries [AppConstants.serverDefaultPort]
  /// upward, then falls back to an OS-assigned port) and resolves the local
  /// IP. [sessionTimeoutMinutes] feeds the guest-pruning timeout.
  Future<ServerSession> startServer({int sessionTimeoutMinutes = 15});

  /// Terminates the hub and clears the connected-client list.
  Future<void> stopServer();

  /// Restarts the hub, typically on a fresh port (QR/URL change).
  Future<void> refreshServer();

  /// Live hub status (active / port / URL changes).
  Stream<ServerSession> watchStatus();

  /// Live list of connected guest devices (pruned by the session timeout).
  Stream<List<ConnectedClient>> watchConnectedClients();

  /// Live incoming-upload events (progress + completion/failure).
  Stream<ServerUploadEvent> watchUploads();

  /// Files currently shareable on the hub.
  Future<List<ServerSharedFile>> listSharedFiles();

  /// Opens the host file picker and returns files staged for publication.
  Future<List<HostPublishFile>> pickHostFiles();

  /// Opens the host device photo gallery and returns photos staged for
  /// publication.
  Future<List<HostPublishFile>> pickHostGalleryPhotos();

  /// Opens the host device camera for a single shot and returns it staged for
  /// publication (an empty list when the shot is cancelled).
  Future<List<HostPublishFile>> pickHostCameraPhoto();

  /// Copies [files] from the host device into the hub's shared storage so
  /// guests can download them. Returns the resulting shareable files.
  Future<List<ServerSharedFile>> publishFiles(List<HostPublishFile> files);

  /// Pulls a copy of a hub file to this device: photos are imported into the
  /// photo gallery, every other file is copied into the documents folder.
  /// Returns where it landed, or null when the file no longer exists.
  Future<DownloadedFile?> downloadSharedFile(String fileId);

  /// Local IPv4 address of this host.
  Future<String> getLocalIp();

  /// Directory where uploaded files are persisted (the "BlazeDrop" folder).
  Future<String> getSharedDirectory();
}
