import '../repositories/peer_repository.dart';

/// Starts broadcasting + listening for peer beacons on the local network.
class StartDiscoveryUseCase {
  const StartDiscoveryUseCase(this._repository);

  final PeerRepository _repository;

  Future<void> execute() => _repository.startDiscovery();
}
