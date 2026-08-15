import '../repositories/peer_repository.dart';

/// Stops broadcasting + listening for peer beacons.
class StopDiscoveryUseCase {
  const StopDiscoveryUseCase(this._repository);

  final PeerRepository _repository;

  Future<void> execute() => _repository.stopDiscovery();
}
