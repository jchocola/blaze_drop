import '../entities/peer_device.dart';
import '../repositories/peer_repository.dart';

/// Live stream of the discovered peer list.
class WatchDiscoveredPeersUseCase {
  const WatchDiscoveredPeersUseCase(this._repository);

  final PeerRepository _repository;

  Stream<List<PeerDevice>> execute() => _repository.watchDiscoveredPeers();
}
