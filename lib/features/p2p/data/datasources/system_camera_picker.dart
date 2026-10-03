import 'package:image_picker/image_picker.dart';

import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/file_item.dart';
import 'camera_picker_data_source.dart';

/// Concrete [CameraPickerDataSource] backed by `image_picker`.
///
/// Uses the platform camera intent (Android) / UIImagePickerController (iOS),
/// so the shot lands in the app cache and no storage permission is required.
class SystemCameraPicker implements CameraPickerDataSource {
  const SystemCameraPicker();

  @override
  Future<FileItem?> capturePhoto() async {
    final shot = await ImagePicker().pickImage(source: ImageSource.camera);
    if (shot == null) {
      return null;
    }
    final path = shot.path;
    if (path.isEmpty) {
      return null;
    }
    // XFile.name can be empty on some hosts; fall back to a timestamped name
    // so the item always has a valid file name for transfer/history.
    final name = shot.name.isEmpty
        ? 'photo_${DateTime.now().millisecondsSinceEpoch}.jpg'
        : shot.name;
    var size = 0;
    try {
      size = await shot.length();
    } catch (_) {
      size = 0;
    }
    return FileItem(
      name: name,
      path: path,
      size: size,
      mimeType: FileUtils.mimeTypeForName(name),
    );
  }
}
