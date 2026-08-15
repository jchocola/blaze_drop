import '../../../../core/config/settings_repository.dart';

/// Restores the default system configuration.
class ResetConfigUseCase {
  const ResetConfigUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> execute() => _repository.resetConfig();
}
