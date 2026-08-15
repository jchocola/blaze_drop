import '../repositories/peer_repository.dart';

/// Answers the pending incoming connection request.
class RespondToRequestUseCase {
  const RespondToRequestUseCase(this._repository);

  final PeerRepository _repository;

  Future<void> execute({required bool accept}) =>
      _repository.respondToRequest(accept: accept);
}
