import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/host_publish_file.dart';

/// Abstraction over the host-side file picker (mockable in tests).
abstract interface class HostFilePicker {
  /// Opens the native picker (multi-select) and returns staged files.
  Future<List<HostPublishFile>> pickFiles();

  /// Opens the system photo-library picker (multi-select) and returns the
  /// chosen photos staged for publication.
  Future<List<HostPublishFile>> pickGalleryPhotos();
}

/// Concrete [HostFilePicker] backed by `file_picker` + `image_picker`
/// (FUNCTIONALITY.md §5.4 host upload).
class SystemHostFilePicker implements HostFilePicker {
  const SystemHostFilePicker();

  @override
  Future<List<HostPublishFile>> pickFiles() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) {
      return const [];
    }
    final items = <HostPublishFile>[];
    for (final file in picked) {
      final path = file.path;
      if (path == null) {
        continue;
      }
      var size = 0;
      try {
        size = await file.length();
      } catch (_) {
        size = 0;
      }
      items.add(
        HostPublishFile(
          name: file.name,
          path: path,
          size: size,
          mimeType: FileUtils.mimeTypeForName(file.name),
        ),
      );
    }
    return items;
  }

  @override
  Future<List<HostPublishFile>> pickGalleryPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) {
      return const [];
    }
    final items = <HostPublishFile>[];
    for (final photo in picked) {
      final path = photo.path;
      if (path.isEmpty) {
        continue;
      }
      // XFile.name can be empty on some hosts; fall back to a timestamped
      // name so the item always has a valid file name for publication.
      final name = photo.name.isEmpty
          ? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg'
          : photo.name;
      var size = 0;
      try {
        size = await photo.length();
      } catch (_) {
        size = 0;
      }
      items.add(
        HostPublishFile(
          name: name,
          path: path,
          size: size,
          mimeType: FileUtils.mimeTypeForName(name),
        ),
      );
    }
    return items;
  }
}
