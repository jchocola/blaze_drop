import '../entities/transfer_session.dart';
import '../repositories/peer_repository.dart';

/// Stream of live transfer updates (progress / completion / failure).
class WatchTransferUpdatesUseCase {
  const WatchTransferUpdatesUseCase(this._repository);

  final PeerRepository _repository;

  Stream<TransferSession> execute() => _repository.watchTransferUpdates();
}
