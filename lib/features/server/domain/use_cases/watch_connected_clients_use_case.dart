import '../entities/connected_client.dart';
import '../repositories/server_repository.dart';

/// Streams the live list of connected guest devices.
class WatchConnectedClientsUseCase {
  const WatchConnectedClientsUseCase(this._repository);

  final ServerRepository _repository;

  Stream<List<ConnectedClient>> execute() => _repository.watchConnectedClients();
}
