import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves app-owned storage locations.
///
/// Kept in `core` so both the data layer (received files) and any feature can
/// share the same paths (RULE.md §1.2).
abstract final class StoragePaths {
  /// Root folder for files received via P2P / Server modes.
  ///
  /// Lives under the app documents directory so it works without extra
  /// permissions on every platform. (A production build may point this at the
  /// real public Downloads folder — see FUNCTIONALITY.md §4.4.)
  static Future<String> get inboxDirectory async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory('${docs.path}${Platform.pathSeparator}BlazeDrop');
    await dir.create(recursive: true);
    return dir.path;
  }

  /// Folder where the host pulls copies of hub files ("download" for the
  /// server, FUNCTIONALITY.md §5.4). Kept separate from [inboxDirectory] so
  /// hub staging and personally received files stay distinct.
  static Future<String> get receivedDirectory async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${docs.path}${Platform.pathSeparator}BlazeDrop'
      '${Platform.pathSeparator}Received',
    );
    await dir.create(recursive: true);
    return dir.path;
  }

  /// Hub staging cache for Server Mode uploads and host publications.
  ///
  /// Cleared on every server start (FUNCTIONALITY.md §7 auto-cleanup) so each
  /// session begins empty. Kept separate from [inboxDirectory] (P2P inbox)
  /// and [receivedDirectory] so clearing it never touches received files.
  static Future<String> get hubCacheDirectory async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${docs.path}${Platform.pathSeparator}BlazeDrop'
      '${Platform.pathSeparator}HubCache',
    );
    await dir.create(recursive: true);
    return dir.path;
  }

  /// Cache directory for the generated self-signed TLS identity
  /// (`Documents/BlazeDrop/tls`).
  static Future<Directory> get tlsDirectory async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(
      '${docs.path}${Platform.pathSeparator}BlazeDrop'
      '${Platform.pathSeparator}tls',
    );
    await dir.create(recursive: true);
    return dir;
  }
}
