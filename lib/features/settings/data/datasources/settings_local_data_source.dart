import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/constants/constants.dart';

/// SharedPreferences-backed store for the "SYSTEM CONFIG" screen.
///
/// Missing keys fall back to [AppConfigDefaults] so older installs behave
/// identically to fresh ones.
class SettingsLocalDataSource {
  SettingsLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  Future<AppConfig> load() async {
    return AppConfig(
      autoAcceptIncoming:
          _prefs.getBool(StorageKeys.configAutoAccept) ??
          AppConfigDefaults.autoAcceptIncoming,
      networkDiscovery:
          _prefs.getBool(StorageKeys.configNetworkDiscovery) ??
          AppConfigDefaults.networkDiscovery,
      e2eEncryption:
          _prefs.getBool(StorageKeys.configE2eEncryption) ??
          AppConfigDefaults.e2eEncryption,
      sessionTimeoutMinutes:
          _prefs.getInt(StorageKeys.configSessionTimeout) ??
          AppConfigDefaults.sessionTimeoutMinutes,
      darkMode:
          _prefs.getBool(StorageKeys.configDarkMode) ??
          AppConfigDefaults.darkMode,
      showHudLogs:
          _prefs.getBool(StorageKeys.configShowHudLogs) ??
          AppConfigDefaults.showHudLogs,
    );
  }

  Future<void> save(AppConfig config) async {
    await _prefs.setBool(
      StorageKeys.configAutoAccept,
      config.autoAcceptIncoming,
    );
    await _prefs.setBool(
      StorageKeys.configNetworkDiscovery,
      config.networkDiscovery,
    );
    await _prefs.setBool(StorageKeys.configE2eEncryption, config.e2eEncryption);
    await _prefs.setInt(
      StorageKeys.configSessionTimeout,
      config.sessionTimeoutMinutes,
    );
    await _prefs.setBool(StorageKeys.configDarkMode, config.darkMode);
    await _prefs.setBool(StorageKeys.configShowHudLogs, config.showHudLogs);
  }

  Future<void> reset() => save(AppConfig.defaults);
}
