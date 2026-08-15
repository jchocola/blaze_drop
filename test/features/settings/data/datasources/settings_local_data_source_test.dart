import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsLocalDataSource', () {
    Future<SettingsLocalDataSource> buildSource() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return SettingsLocalDataSource(prefs);
    }

    test('load falls back to defaults when nothing is persisted', () async {
      final source = await buildSource();
      expect(await source.load(), AppConfig.defaults);
    });

    test('save + load round-trips every field', () async {
      final source = await buildSource();
      const config = AppConfig(
        autoAcceptIncoming: true,
        networkDiscovery: true,
        e2eEncryption: false,
        sessionTimeoutMinutes: 30,
        darkMode: true,
        showHudLogs: false,
      );

      await source.save(config);

      expect(await source.load(), config);
    });

    test('reset restores the defaults', () async {
      final source = await buildSource();
      const config = AppConfig(sessionTimeoutMinutes: 45);
      await source.save(config);

      await source.reset();

      expect(await source.load(), AppConfig.defaults);
    });
  });
}
