import '../entities/permission_requirement.dart';
import '../repositories/permission_repository.dart';

/// Reads the current state of every required permission without prompting.
class CheckPermissionsUseCase {
  const CheckPermissionsUseCase(this._repository);

  final PermissionRepository _repository;

  Future<List<PermissionRequirement>> execute() async =>
      _repository.getRequiredPermissions();
}
