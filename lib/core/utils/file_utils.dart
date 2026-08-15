import 'dart:io';

/// File helpers used across features (RULE.md §1.2 / §8).
///
/// Centralizes MIME sniffing, path-traversal sanitization and name-conflict
/// resolution so that every writer of received files behaves identically.
abstract final class FileUtils {
  static const Map<String, String> _mimeByExtension = {
    'pdf': 'application/pdf',
    'zip': 'application/zip',
    'gz': 'application/gzip',
    'tar': 'application/x-tar',
    'json': 'application/json',
    'yaml': 'application/yaml',
    'yml': 'application/yaml',
    'xml': 'application/xml',
    'txt': 'text/plain',
    'md': 'text/markdown',
    'csv': 'text/csv',
    'html': 'text/html',
    'htm': 'text/html',
    'css': 'text/css',
    'js': 'text/javascript',
    'png': 'image/png',
    'jpg': 'image/jpeg',
    'jpeg': 'image/jpeg',
    'gif': 'image/gif',
    'webp': 'image/webp',
    'svg': 'image/svg+xml',
    'bmp': 'image/bmp',
    'ico': 'image/x-icon',
    'heic': 'image/heic',
    'mp3': 'audio/mpeg',
    'wav': 'audio/wav',
    'aac': 'audio/aac',
    'flac': 'audio/flac',
    'ogg': 'audio/ogg',
    'm4a': 'audio/mp4',
    'mp4': 'video/mp4',
    'mov': 'video/quicktime',
    'avi': 'video/x-msvideo',
    'mkv': 'video/x-matroska',
    'webm': 'video/webm',
    '3gp': 'video/3gpp',
    'apk': 'application/vnd.android.package-archive',
    'doc': 'application/msword',
    'docx':
        'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
    'xls': 'application/vnd.ms-excel',
    'xlsx':
        'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
    'ppt': 'application/vnd.ms-powerpoint',
    'pptx':
        'application/vnd.openxmlformats-officedocument.presentationml.presentation',
    'key': 'application/pgp-keys',
    'pem': 'application/x-pem-file',
    'crt': 'application/x-x509-ca-cert',
    'p12': 'application/x-pkcs12',
    'h5': 'application/x-hdf5',
    'bin': 'application/octet-stream',
    'dat': 'application/octet-stream',
    'deb': 'application/vnd.debian.binary-package',
  };

  /// Best-effort MIME type derived from the file extension.
  static String mimeTypeForName(String name) {
    final dot = name.lastIndexOf('.');
    if (dot < 0 || dot == name.length - 1) {
      return 'application/octet-stream';
    }
    final ext = name.substring(dot + 1).toLowerCase();
    return _mimeByExtension[ext] ?? 'application/octet-stream';
  }

  /// Sanitizes an incoming file name to prevent path-traversal attacks
  /// (FUNCTIONALITY.md §7): replaces directory separators and `..` with `_`.
  static String sanitizeFileName(String name) {
    var safe = name.replaceAll(RegExp(r'[/\\]'), '_');
    safe = safe.replaceAll('..', '_');
    safe = safe.replaceAll(RegExp(r'[\x00-\x1F]'), '_');
    safe = safe.trim();
    return safe.isEmpty ? 'unnamed_file' : safe;
  }

  /// Resolves a write path in [directory] that does not collide with an
  /// existing file: `file.zip` → `file (1).zip` (FUNCTIONALITY.md §4.4).
  ///
  /// Never overwrites without asking.
  static Future<String> resolveUniquePath(String directory, String name) async {
    final safe = sanitizeFileName(name);
    final dir = Directory(directory);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    var candidate = '$directory${Platform.pathSeparator}$safe';
    var counter = 1;
    final dot = safe.lastIndexOf('.');
    final base = dot > 0 ? safe.substring(0, dot) : safe;
    final ext = dot > 0 ? safe.substring(dot) : '';
    while (await File(candidate).exists()) {
      candidate = '$directory${Platform.pathSeparator}$base ($counter)$ext';
      counter++;
    }
    return candidate;
  }
}
