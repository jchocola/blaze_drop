import '../repositories/permission_repository.dart';

/// Opens the OS settings page for this app.
class OpenAppSettingsUseCase {
  const OpenAppSettingsUseCase(this._repository);

  final PermissionRepository _repository;

  Future<void> execute() async => _repository.openAppSettings();
}
