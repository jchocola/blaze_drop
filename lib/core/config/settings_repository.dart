import 'app_config.dart';

/// Persistence boundary for the application configuration.
///
/// Declared in `core` so both the settings feature (edit UI) and the server
/// feature (reads connection/security preferences) depend only on core
/// (RULE.md §1.2).
abstract interface class SettingsRepository {
  /// Loads the persisted [AppConfig] (falling back to defaults).
  Future<AppConfig> loadConfig();

  /// Persists [config].
  Future<void> saveConfig(AppConfig config);

  /// Restores the default configuration.
  Future<void> resetConfig();
}
