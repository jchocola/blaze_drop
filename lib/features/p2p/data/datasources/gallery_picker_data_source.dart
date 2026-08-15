import '../../domain/entities/file_item.dart';

/// Abstraction over the device photo gallery picker (mockable in tests).
///
/// Mirrors [FilePickerDataSource] but targets the system photo library
/// (FUNCTIONALITY.md §4.3 "photos from gallery").
abstract interface class GalleryPickerDataSource {
  /// Opens the native photo-library picker (multi-select) and returns the
  /// chosen photos as [FileItem]s.
  Future<List<FileItem>> pickPhotos();
}
