import '../../../../core/config/app_config.dart';
import '../../../../core/config/settings_repository.dart';
import '../datasources/settings_local_data_source.dart';

/// Concrete [SettingsRepository] backed by [SettingsLocalDataSource].
class SettingsRepositoryImpl implements SettingsRepository {
  const SettingsRepositoryImpl(this._dataSource);

  final SettingsLocalDataSource _dataSource;

  @override
  Future<AppConfig> loadConfig() => _dataSource.load();

  @override
  Future<void> saveConfig(AppConfig config) => _dataSource.save(config);

  @override
  Future<void> resetConfig() => _dataSource.reset();
}
