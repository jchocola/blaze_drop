import '../repositories/nearby_permission_repository.dart';

/// Opens the OS settings page so the user can re-enable a permanently
/// denied "Nearby devices" permission.
class OpenNearbySettingsUseCase {
  const OpenNearbySettingsUseCase(this._repository);

  final NearbyPermissionRepository _repository;

  Future<void> execute() => _repository.openSettings();
}
