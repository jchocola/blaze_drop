import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/core/config/settings_repository.dart';
import 'package:blaze_drop/features/settings/domain/entities/app_version.dart';
import 'package:blaze_drop/features/settings/domain/repositories/version_repository.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/get_version_info_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/load_config_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/reset_config_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/save_config_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSettingsRepository extends Mock implements SettingsRepository {}

class _MockVersionRepository extends Mock implements VersionRepository {}

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

    test('GetVersionInfoUseCase returns the repository version', () async {
      const version = AppVersion(
        version: '0.1.0',
        buildNumber: '7',
        packageName: 'com.example.blaze_drop',
      );
      final versionRepository = _MockVersionRepository();
      when(
        () => versionRepository.getVersionInfo(),
      ).thenAnswer((_) async => version);

      final result = await GetVersionInfoUseCase(versionRepository).execute();

      expect(result, version);
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
