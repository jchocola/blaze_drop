import 'package:file_picker/file_picker.dart';

import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/host_publish_file.dart';

/// Abstraction over the host-side file picker (mockable in tests).
abstract interface class HostFilePicker {
  /// Opens the native picker (multi-select) and returns staged files.
  Future<List<HostPublishFile>> pickFiles();
}

/// Concrete [HostFilePicker] backed by `file_picker`
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
}
