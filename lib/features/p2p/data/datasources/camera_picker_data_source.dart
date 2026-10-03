import '../../domain/entities/file_item.dart';

/// Abstraction over the device camera (mockable in tests).
///
/// Mirrors [GalleryPickerDataSource] but captures a fresh single shot
/// (FUNCTIONALITY.md §4.3 "photo from camera").
abstract interface class CameraPickerDataSource {
  /// Opens the system camera for a single shot and returns it as a [FileItem],
  /// or null when the shot is cancelled.
  Future<FileItem?> capturePhoto();
}
