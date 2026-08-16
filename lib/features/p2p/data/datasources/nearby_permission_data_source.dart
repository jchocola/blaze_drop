import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

/// Low-level data source for the Android "Nearby devices" runtime permission
/// (`android.permission.NEARBY_WIFI_DEVICES`, API 33+).
///
/// On non-Android platforms there is no runtime prompt — the requirement is
/// treated as already satisfied so discovery can always proceed.
class NearbyPermissionDataSource {
  /// Ensures the "Nearby devices" permission is granted, requesting it from
  /// the OS when needed. Returns `true` when discovery may proceed.
  Future<bool> ensureNearbyPermission() async {
    if (!kIsWeb && defaultTargetPlatform != TargetPlatform.android) {
      return true;
    }
    final status = await ph.Permission.nearbyWifiDevices.status;
    if (status.isGranted || status.isLimited) {
      return true;
    }
    if (status.isPermanentlyDenied || status.isRestricted) {
      return false;
    }
    final result = await ph.Permission.nearbyWifiDevices.request();
    return result.isGranted || result.isLimited;
  }

  /// Opens the OS settings page for this app (used for permanent denials).
  Future<void> openSettings() => ph.openAppSettings();
}
