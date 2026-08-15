import '../entities/incoming_connection_request.dart';
import '../repositories/peer_repository.dart';

/// Stream of incoming connection requests.
class WatchIncomingRequestsUseCase {
  const WatchIncomingRequestsUseCase(this._repository);

  final PeerRepository _repository;

  Stream<IncomingConnectionRequest> execute() =>
      _repository.watchIncomingRequests();
}
