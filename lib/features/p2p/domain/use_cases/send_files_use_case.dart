import '../entities/file_item.dart';
import '../entities/peer_device.dart';
import '../entities/transfer_session.dart';
import '../repositories/peer_repository.dart';

/// Sends [files] to [peer] over the established P2P socket.
class SendFilesUseCase {
  const SendFilesUseCase(this._repository);

  final PeerRepository _repository;

  Future<TransferSession> execute(
    PeerDevice peer,
    List<FileItem> files, {
    void Function(int transferred, int total)? onProgress,
  }) {
    return _repository.sendFiles(peer, files, onProgress: onProgress);
  }
}
