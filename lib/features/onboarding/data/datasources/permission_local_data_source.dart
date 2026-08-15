import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/entities/permission_requirement.dart';

/// Low-level data source that talks directly to the `permission_handler`
/// plugin. Normalizes platform statuses into domain enums.
class PermissionLocalDataSource {
  /// Reads the current status of [permission] without prompting.
  Future<PermissionStatusType> getStatus(ph.Permission permission) async =>
      _map(await permission.status);

  /// Requests [permission] from the OS and returns the resulting status.
  Future<PermissionStatusType> request(ph.Permission permission) async =>
      _map(await permission.request());

  /// Opens the OS settings page for this app.
  Future<void> openAppSettings() => ph.openAppSettings();

  PermissionStatusType _map(ph.PermissionStatus status) {
    if (status.isGranted) {
      return PermissionStatusType.granted;
    }
    if (status.isPermanentlyDenied) {
      return PermissionStatusType.permanentlyDenied;
    }
    if (status.isRestricted) {
      return PermissionStatusType.restricted;
    }
    if (status.isLimited) {
      return PermissionStatusType.limited;
    }
    if (status.isDenied) {
      return PermissionStatusType.denied;
    }
    return PermissionStatusType.unknown;
  }
}
