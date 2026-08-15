import '../../../../core/constants/constants.dart';
import '../../domain/entities/connected_client.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/server_shared_file.dart';
import '../../domain/entities/server_upload_event.dart';
import '../../domain/repositories/server_repository.dart';
import '../datasources/web_server_transport.dart';

/// Concrete [ServerRepository] backed by [WebServerTransport].
class ServerRepositoryImpl implements ServerRepository {
  const ServerRepositoryImpl({required WebServerTransport transport})
    : _transport = transport;

  final WebServerTransport _transport;

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
  Future<String> getLocalIp() => _transport.getLocalIp();

  @override
  Future<String> getSharedDirectory() => _transport.getSharedDirectory();
}
