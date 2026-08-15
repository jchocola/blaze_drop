import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/features/settings/data/datasources/settings_local_data_source.dart';
import 'package:blaze_drop/features/settings/data/repositories_impl/settings_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SettingsRepositoryImpl', () {
    test('delegates load / save / reset to the local data source', () async {
      SharedPreferences.setMockInitialValues({});
      final repository = SettingsRepositoryImpl(
        SettingsLocalDataSource(await SharedPreferences.getInstance()),
      );

      const config = AppConfig(showHudLogs: false);
      await repository.saveConfig(config);
      expect(await repository.loadConfig(), config);

      await repository.resetConfig();
      expect(await repository.loadConfig(), AppConfig.defaults);
    });
  });
}
