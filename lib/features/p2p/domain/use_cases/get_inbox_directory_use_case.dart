import '../repositories/peer_repository.dart';

/// Directory where received files are stored.
class GetInboxDirectoryUseCase {
  const GetInboxDirectoryUseCase(this._repository);

  final PeerRepository _repository;

  Future<String> execute() => _repository.getInboxDirectory();
}
