/// Gate for the Android "Nearby devices" runtime permission used by P2P
/// discovery. Lives in the P2P feature so discovery can self-gate without
/// depending on the onboarding feature.
abstract class NearbyPermissionRepository {
  /// Ensures the "Nearby devices" permission is granted (Android 13+),
  /// requesting it from the OS when needed. Returns `false` when the user
  /// denied access and discovery must not start.
  Future<bool> ensureNearbyPermission();

  /// Opens the OS settings page for this app (permanent denials).
  Future<void> openSettings();
}
