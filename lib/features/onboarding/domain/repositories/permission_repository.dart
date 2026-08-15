import '../entities/permission_requirement.dart';

/// Abstraction over the platform permission service (RULE.md §1.1).
///
/// Implementations live in the data layer and may use plugins such as
/// `permission_handler`; the domain layer only sees this interface.
abstract interface class PermissionRepository {
  /// Returns the required permissions together with their current status
  /// (does not prompt the user).
  Future<List<PermissionRequirement>> getRequiredPermissions();

  /// Requests all required permissions from the OS and returns the updated
  /// statuses.
  Future<List<PermissionRequirement>> requestRequiredPermissions();

  /// Opens the OS settings page for this app.
  ///
  /// Used when a permission is permanently denied.
  Future<void> openAppSettings();
}
