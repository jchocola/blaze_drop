import '../../../../core/config/app_config.dart';
import '../../../../core/config/settings_repository.dart';

/// Persists the system configuration.
class SaveConfigUseCase {
  const SaveConfigUseCase(this._repository);

  final SettingsRepository _repository;

  Future<void> execute(AppConfig config) => _repository.saveConfig(config);
}
