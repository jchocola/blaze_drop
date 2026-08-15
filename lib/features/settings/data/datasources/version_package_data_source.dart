import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../../../../core/constants/constants.dart';
import '../../domain/entities/app_version.dart';

/// `package_info_plus`-backed source of version/build metadata.
///
/// Falls back to compile-time [AppConstants] values when the platform channel
/// is unavailable (e.g. a stale build where the native plugin is not yet
/// registered, widget tests, or hosts without native plugin support), so the
/// UI always shows a real version instead of surfacing `MissingPluginException`
/// / unknown placeholders.
class VersionPackageDataSource {
  /// Resolves [AppVersion] from the platform package info.
  Future<AppVersion> getVersionInfo() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return AppVersion(
        version: info.version,
        buildNumber: info.buildNumber,
        packageName: info.packageName,
        appName: info.appName,
        buildSignature: info.buildSignature,
        installerStore: info.installerStore,
      );
    } on MissingPluginException {
      // Native channel not registered — use the compile-time fallback.
      return _compileTimeFallback;
    }
  }

  static const AppVersion _compileTimeFallback = AppVersion(
    version: AppConstants.appVersionFallback,
    buildNumber: AppConstants.appBuildNumberFallback,
    packageName: AppConstants.appPackageNameFallback,
  );
}
