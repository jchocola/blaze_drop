import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/core/config/settings_repository.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/load_config_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/reset_config_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/save_config_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

void main() {
  group('Settings use cases', () {
    late _MockSettingsRepository repository;

    setUp(() {
      repository = _MockSettingsRepository();
    });

    test('LoadConfigUseCase returns the repository config', () async {
      const config = AppConfig(autoAcceptIncoming: true);
      when(() => repository.loadConfig()).thenAnswer((_) async => config);

      final result = await LoadConfigUseCase(repository).execute();

      expect(result, config);
    });

    test('SaveConfigUseCase persists the given config', () async {
      const config = AppConfig(networkDiscovery: true);
      when(() => repository.saveConfig(config)).thenAnswer((_) async {});

      await SaveConfigUseCase(repository).execute(config);

      verify(() => repository.saveConfig(config)).called(1);
    });

    test('ResetConfigUseCase resets the config', () async {
      when(() => repository.resetConfig()).thenAnswer((_) async {});

      await ResetConfigUseCase(repository).execute();

      verify(() => repository.resetConfig()).called(1);
    });
  });
}
