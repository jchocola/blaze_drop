import '../repositories/nearby_permission_repository.dart';

/// Ensures the Android "Nearby devices" runtime permission is granted before
/// discovery starts. Returns `false` when the user denied access.
class EnsureNearbyPermissionUseCase {
  const EnsureNearbyPermissionUseCase(this._repository);

  final NearbyPermissionRepository _repository;

  Future<bool> execute() => _repository.ensureNearbyPermission();
}
