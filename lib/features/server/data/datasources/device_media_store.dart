import 'dart:io';

import 'package:gal/gal.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;

import '../../../../core/utils/file_utils.dart';
import '../../../../core/utils/logger.dart';
import '../../../../core/utils/storage_paths.dart';
import '../../domain/entities/downloaded_file.dart';
import '../../domain/exceptions/server_transfer_exception.dart';
import 'media_store.dart';

/// [MediaStore] that saves photos into the device photo gallery via `gal` and
/// every other file into the documents folder (FUNCTIONALITY.md §5.4).
class DeviceMediaStore implements MediaStore {
  DeviceMediaStore({Future<String> Function()? documentsDirectoryProvider})
    : _documentsDirectoryProvider =
          documentsDirectoryProvider ?? (() => StoragePaths.receivedDirectory);

  final Future<String> Function() _documentsDirectoryProvider;

  @override
  Future<DownloadedFile> store({
    required String sourcePath,
    required String fileName,
  }) async {
    if (targetFor(fileName) == DownloadTarget.gallery) {
      return _storeToGallery(sourcePath, fileName);
    }
    return _storeToDocuments(sourcePath, fileName);
  }

  /// Pure routing decision based on the MIME type (photos → gallery).
  static DownloadTarget targetFor(String fileName) {
    final mimeType =
        lookupMimeType(fileName) ?? FileUtils.mimeTypeForName(fileName);
    return mimeType.startsWith('image/')
        ? DownloadTarget.gallery
        : DownloadTarget.documents;
  }

  Future<DownloadedFile> _storeToGallery(
    String sourcePath,
    String fileName,
  ) async {
    try {
      // iOS: request photo-library add permission before importing.
      if (!await Gal.hasAccess(toAlbum: true)) {
        await Gal.requestAccess(toAlbum: true);
      }
      await Gal.putImage(sourcePath);
      final size = await File(sourcePath).length();
      AppLogger.info('Saved $fileName to the photo gallery');
      return DownloadedFile(
        name: fileName,
        target: DownloadTarget.gallery,
        size: size,
      );
    } catch (error, stack) {
      AppLogger.error('Failed to save image to gallery', error, stack);
      throw ServerTransferException(
        'Photo-library permission is required to save pictures to the gallery',
      );
    }
  }

  Future<DownloadedFile> _storeToDocuments(
    String sourcePath,
    String fileName,
  ) async {
    final dir = await _documentsDirectoryProvider();
    final target = await FileUtils.resolveUniquePath(dir, fileName);
    await File(sourcePath).copy(target);
    final savedName = p.basename(target);
    final size = await File(target).length();
    AppLogger.info('Saved $savedName to documents');
    return DownloadedFile(
      name: savedName,
      target: DownloadTarget.documents,
      path: target,
      size: size,
    );
  }
}
