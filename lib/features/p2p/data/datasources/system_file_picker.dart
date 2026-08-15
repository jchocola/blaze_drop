import 'package:file_picker/file_picker.dart';

import '../../../../core/utils/file_utils.dart';
import '../../domain/entities/file_item.dart';
import 'file_picker_data_source.dart';

/// Concrete [FilePickerDataSource] backed by `file_picker`
/// (FUNCTIONALITY.md §4.3).
class SystemFilePicker implements FilePickerDataSource {
  const SystemFilePicker();

  @override
  Future<List<FileItem>> pickFiles() async {
    final picked = await FilePicker.pickFiles();
    if (picked.isEmpty) {
      return const [];
    }
    final items = <FileItem>[];
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
        FileItem(
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
