import 'package:flutter/material.dart';

import '../../domain/entities/file_item.dart';

/// UI mapping for a [FileItem] (icon + accent) based on its MIME type.
extension FileTypeUi on FileItem {
  IconData get icon {
    final mime = mimeType ?? '';
    if (mime.startsWith('image/')) {
      return Icons.image_outlined;
    }
    if (mime.startsWith('video/')) {
      return Icons.videocam_outlined;
    }
    if (mime.startsWith('audio/')) {
      return Icons.music_note_outlined;
    }
    if (mime.contains('pdf')) {
      return Icons.picture_as_pdf_outlined;
    }
    if (mime.contains('zip') ||
        mime.contains('tar') ||
        mime.contains('gzip') ||
        mime.contains('compressed')) {
      return Icons.archive_outlined;
    }
    if (mime.contains('json') ||
        mime.contains('yaml') ||
        mime.contains('xml') ||
        mime.contains('text')) {
      return Icons.description_outlined;
    }
    if (mime.contains('key') ||
        mime.contains('pem') ||
        mime.contains('crt') ||
        mime.contains('p12')) {
      return Icons.key_outlined;
    }
    if (mime.contains('apk')) {
      return Icons.android_outlined;
    }
    return Icons.insert_drive_file_outlined;
  }
}
