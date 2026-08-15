import '../../domain/entities/file_item.dart';

/// Abstraction over the system file picker (mockable in tests).
abstract interface class FilePickerDataSource {
  /// Opens the native picker (multi-select) and returns chosen files.
  Future<List<FileItem>> pickFiles();
}
