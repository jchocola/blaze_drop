import 'package:blaze_drop/core/config/app_config.dart';
import 'package:blaze_drop/features/settings/domain/entities/app_version.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/get_version_info_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/load_config_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/reset_config_use_case.dart';
import 'package:blaze_drop/features/settings/domain/use_cases/save_config_use_case.dart';
import 'package:blaze_drop/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:blaze_drop/features/settings/presentation/cubit/settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockLoadConfig extends Mock implements LoadConfigUseCase {}

class _MockSaveConfig extends Mock implements SaveConfigUseCase {}

class _MockResetConfig extends Mock implements ResetConfigUseCase {}

class _MockGetVersionInfo extends Mock implements GetVersionInfoUseCase {}

const _testVersion = AppVersion(
  version: '0.1.0',
  buildNumber: '7',
  packageName: 'com.example.blaze_drop',
);

void main() {
  setUpAll(() {
    registerFallbackValue(AppConfig.defaults);
  });

  group('SettingsCubit', () {
    late _MockLoadConfig load;
    late _MockSaveConfig save;
    late _MockResetConfig reset;
    late _MockGetVersionInfo version;

    setUp(() {
      load = _MockLoadConfig();
      save = _MockSaveConfig();
      reset = _MockResetConfig();
      version = _MockGetVersionInfo();
      when(() => version.execute()).thenAnswer((_) async => _testVersion);
    });

    SettingsCubit buildCubit() {
      return SettingsCubit(
        loadConfigUseCase: load,
        saveConfigUseCase: save,
        resetConfigUseCase: reset,
        getVersionInfoUseCase: version,
      );
    }

    test('initial state uses defaults and is loading', () {
      final cubit = buildCubit();
      expect(cubit.state.config, AppConfig.defaults);
      expect(cubit.state.version, AppVersion.unknown);
      expect(cubit.state.isLoading, isTrue);
      expect(cubit.state.dirty, isFalse);
    });

    blocTest<SettingsCubit, SettingsState>(
      'load populates the persisted config and version',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      setUp: () {
        when(
          () => load.execute(),
        ).thenAnswer((_) async => const AppConfig(autoAcceptIncoming: true));
      },
      expect: () => [
        const SettingsState(
          config: AppConfig(autoAcceptIncoming: true),
          version: _testVersion,
          isLoading: false,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'load falls back to unknown version when resolution fails',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      setUp: () {
        when(
          () => load.execute(),
        ).thenAnswer((_) async => const AppConfig(autoAcceptIncoming: true));
        when(() => version.execute()).thenThrow(Exception('no package info'));
      },
      expect: () => [
        const SettingsState(
          config: AppConfig(autoAcceptIncoming: true),
          isLoading: false,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'load surfaces an error when the repository fails',
      build: buildCubit,
      act: (cubit) => cubit.load(),
      setUp: () {
        when(() => load.execute()).thenThrow(Exception('boom'));
      },
      expect: () => [
        const SettingsState(
          isLoading: false,
          error: 'Failed to load config',
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'update marks the working copy dirty',
      build: buildCubit,
      seed: () => const SettingsState(isLoading: false),
      act: (cubit) => cubit.update(autoAcceptIncoming: true),
      expect: () => [
        const SettingsState(
          config: AppConfig(autoAcceptIncoming: true),
          isLoading: false,
          dirty: true,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'save persists and clears the dirty flag',
      build: buildCubit,
      seed: () => const SettingsState(
        config: AppConfig(autoAcceptIncoming: true),
        isLoading: false,
        dirty: true,
      ),
      act: (cubit) => cubit.save(),
      setUp: () {
        when(() => save.execute(any())).thenAnswer((_) async {});
      },
      expect: () => [
        const SettingsState(
          config: AppConfig(autoAcceptIncoming: true),
          isLoading: false,
          isSaving: true,
          dirty: true,
        ),
        const SettingsState(
          config: AppConfig(autoAcceptIncoming: true),
          isLoading: false,
          dirty: false,
          saved: true,
        ),
      ],
    );

    blocTest<SettingsCubit, SettingsState>(
      'reset restores and persists the defaults',
      build: buildCubit,
      seed: () => const SettingsState(
        config: AppConfig(sessionTimeoutMinutes: 45),
        isLoading: false,
      ),
      act: (cubit) => cubit.reset(),
      setUp: () {
        when(() => reset.execute()).thenAnswer((_) async {});
      },
      expect: () => [
        const SettingsState(
          config: AppConfig(sessionTimeoutMinutes: 45),
          isLoading: false,
          isSaving: true,
        ),
        const SettingsState(
          config: AppConfig.defaults,
          isLoading: false,
          dirty: false,
          saved: true,
        ),
      ],
    );
  });
}
