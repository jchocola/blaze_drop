import '../../../../core/config/app_config.dart';
import '../../../../core/config/settings_repository.dart';

/// Loads the persisted system configuration.
class LoadConfigUseCase {
  const LoadConfigUseCase(this._repository);

  final SettingsRepository _repository;

  Future<AppConfig> execute() => _repository.loadConfig();
}
