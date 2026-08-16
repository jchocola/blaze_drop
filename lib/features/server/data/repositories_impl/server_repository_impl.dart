import '../../../../core/constants/constants.dart';
import '../../domain/entities/connected_client.dart';
import '../../domain/entities/downloaded_file.dart';
import '../../domain/entities/host_publish_file.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/server_shared_file.dart';
import '../../domain/entities/server_upload_event.dart';
import '../../domain/repositories/server_repository.dart';
import '../datasources/host_file_picker.dart';
import '../datasources/web_server_transport.dart';

/// Concrete [ServerRepository] backed by [WebServerTransport] and the host
/// file picker.
class ServerRepositoryImpl implements ServerRepository {
  const ServerRepositoryImpl({
    required WebServerTransport transport,
    required HostFilePicker filePicker,
  }) : _transport = transport,
       _filePicker = filePicker;

  final WebServerTransport _transport;
  final HostFilePicker _filePicker;

  @override
  Future<ServerSession> startServer({int sessionTimeoutMinutes = 15}) {
    return _transport.start(
      preferredPort: AppConstants.serverDefaultPort,
      sessionTimeoutMinutes: sessionTimeoutMinutes,
    );
  }

  @override
  Future<void> stopServer() => _transport.stop();

  @override
  Future<void> refreshServer() => _transport.refresh();

  @override
  Stream<ServerSession> watchStatus() => _transport.watchStatus();

  @override
  Stream<List<ConnectedClient>> watchConnectedClients() =>
      _transport.watchClients();

  @override
  Stream<ServerUploadEvent> watchUploads() => _transport.watchUploads();

  @override
  Future<List<ServerSharedFile>> listSharedFiles() =>
      _transport.listFiles();

  @override
  Future<List<HostPublishFile>> pickHostFiles() => _filePicker.pickFiles();

  @override
  Future<List<HostPublishFile>> pickHostGalleryPhotos() =>
      _filePicker.pickGalleryPhotos();

  @override
  Future<List<ServerSharedFile>> publishFiles(
    List<HostPublishFile> files,
  ) => _transport.publishFiles(files);

  @override
  Future<DownloadedFile?> downloadSharedFile(String fileId) =>
      _transport.downloadSharedFile(fileId);

  @override
  Future<String> getLocalIp() => _transport.getLocalIp();

  @override
  Future<String> getSharedDirectory() => _transport.getSharedDirectory();
}
