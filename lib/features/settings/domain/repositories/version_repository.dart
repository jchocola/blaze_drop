import '../entities/app_version.dart';

/// Boundary for reading the running app's version/build metadata.
abstract interface class VersionRepository {
  /// Resolves the current [AppVersion] from the platform.
  Future<AppVersion> getVersionInfo();
}
