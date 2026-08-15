import '../repositories/peer_repository.dart';

/// Reads the advertised name of the local node.
class GetLocalNodeNameUseCase {
  const GetLocalNodeNameUseCase(this._repository);

  final PeerRepository _repository;

  Future<String> execute() => _repository.getLocalNodeName();
}
