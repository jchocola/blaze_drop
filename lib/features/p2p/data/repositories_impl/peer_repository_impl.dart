import '../../../../core/utils/storage_paths.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/incoming_connection_request.dart';
import '../../domain/entities/peer_device.dart';
import '../../domain/entities/transfer_session.dart';
import '../../domain/repositories/peer_repository.dart';
import '../datasources/camera_picker_data_source.dart';
import '../datasources/file_picker_data_source.dart';
import '../datasources/gallery_picker_data_source.dart';
import '../datasources/node_identity_store.dart';
import '../datasources/peer_transport_data_source.dart';

/// Concrete [PeerRepository] backed by the socket transport + native pickers.
class PeerRepositoryImpl implements PeerRepository {
  const PeerRepositoryImpl({
    required PeerTransportDataSource transport,
    required NodeIdentityStore identityStore,
    required FilePickerDataSource filePicker,
    required GalleryPickerDataSource galleryPicker,
    required CameraPickerDataSource cameraPicker,
  }) : _transport = transport,
       _identityStore = identityStore,
       _filePicker = filePicker,
       _galleryPicker = galleryPicker,
       _cameraPicker = cameraPicker;

  final PeerTransportDataSource _transport;
  final NodeIdentityStore _identityStore;
  final FilePickerDataSource _filePicker;
  final GalleryPickerDataSource _galleryPicker;
  final CameraPickerDataSource _cameraPicker;

  @override
  Future<String> getLocalNodeName() => _identityStore.getNodeName();

  @override
  Future<String> getInboxDirectory() => StoragePaths.inboxDirectory;

  @override
  Future<List<FileItem>> pickFiles() => _filePicker.pickFiles();

  @override
  Future<List<FileItem>> pickGalleryPhotos() => _galleryPicker.pickPhotos();

  @override
  Future<List<FileItem>> capturePhoto() async {
    final shot = await _cameraPicker.capturePhoto();
    return shot == null ? const [] : [shot];
  }

  @override
  Future<void> respondToRequest({required bool accept}) =>
      _transport.respondToRequest(accept: accept);

  @override
  Future<TransferSession> sendFiles(
    PeerDevice peer,
    List<FileItem> files, {
    void Function(int transferred, int total)? onProgress,
  }) {
    return _transport.sendFiles(peer, files, onProgress: onProgress);
  }

  @override
  Future<void> startDiscovery() => _transport.startDiscovery();

  @override
  Future<void> stopDiscovery() => _transport.stopDiscovery();

  @override
  Stream<IncomingConnectionRequest> watchIncomingRequests() =>
      _transport.watchIncomingRequests();

  @override
  Stream<List<PeerDevice>> watchDiscoveredPeers() => _transport.watchPeers();

  @override
  Stream<TransferSession> watchTransferUpdates() =>
      _transport.watchTransferUpdates();
}
