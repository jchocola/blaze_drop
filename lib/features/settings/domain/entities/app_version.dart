import 'package:equatable/equatable.dart';

/// Immutable version/build metadata of the running app
/// (sourced from `package_info_plus`).
class AppVersion extends Equatable {
  const AppVersion({
    required this.version,
    required this.buildNumber,
    required this.packageName,
    this.appName,
    this.buildSignature,
    this.installerStore,
  });

  /// Human-readable version, e.g. `0.1.0`.
  final String version;

  /// Build number, e.g. `1`.
  final String buildNumber;

  /// Bundle / application id, e.g. `com.example.blaze_drop`.
  final String packageName;

  /// Display name of the app (may be empty on some platforms).
  final String? appName;

  /// Build signature (Android only).
  final String? buildSignature;

  /// Installer store (Android only), e.g. `play`, `amazon`.
  final String? installerStore;

  /// Fallback used before the platform package info is resolved.
  static const AppVersion unknown = AppVersion(
    version: '--',
    buildNumber: '--',
    packageName: '--',
  );

  @override
  List<Object?> get props => [
    version,
    buildNumber,
    packageName,
    appName,
    buildSignature,
    installerStore,
  ];
}
