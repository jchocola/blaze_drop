import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/file_item.dart';
import 'gallery_picker_data_source.dart';

/// Concrete [GalleryPickerDataSource] backed by `image_picker`.
///
/// Uses the system photo picker (PHPicker on iOS / Photo Picker on Android),
/// so no runtime permission is required on modern platforms.
class SystemGalleryPicker implements GalleryPickerDataSource {
  const SystemGalleryPicker();

  @override
  Future<List<FileItem>> pickPhotos() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isEmpty) {
      return const [];
    }
    final items = <FileItem>[];
    for (final photo in picked) {
      final path = photo.path;
      if (path.isEmpty) {
        continue;
      }
      // XFile.name can be empty on some hosts; fall back to a timestamped
      // name so the item always has a valid file name for transfer/history.
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
        FileItem(
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
