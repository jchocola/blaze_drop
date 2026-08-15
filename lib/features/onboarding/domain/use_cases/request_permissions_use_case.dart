import '../entities/permission_requirement.dart';
import '../repositories/permission_repository.dart';

/// Prompts the user for every required permission.
class RequestPermissionsUseCase {
  const RequestPermissionsUseCase(this._repository);

  final PermissionRepository _repository;

  Future<List<PermissionRequirement>> execute() async =>
      _repository.requestRequiredPermissions();
}
