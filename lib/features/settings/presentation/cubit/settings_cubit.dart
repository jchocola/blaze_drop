import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/app_version.dart';
import '../../domain/use_cases/get_version_info_use_case.dart';
import '../../domain/use_cases/load_config_use_case.dart';
import '../../domain/use_cases/reset_config_use_case.dart';
import '../../domain/use_cases/save_config_use_case.dart';
import 'settings_state.dart';

/// Orchestrates the "SYSTEM CONFIG" screen (FUNCTIONALITY.md mock).
///
/// Loads the persisted config, tracks a dirty working copy as the user flips
/// toggles, and persists it on [save] / [reset]. No business logic here —
/// all persistence is delegated to use cases (RULE.md §2).
class SettingsCubit extends Cubit<SettingsState> {
  SettingsCubit({
    required this.loadConfigUseCase,
    required this.saveConfigUseCase,
    required this.resetConfigUseCase,
    required this.getVersionInfoUseCase,
  }) : super(const SettingsState());

  final LoadConfigUseCase loadConfigUseCase;
  final SaveConfigUseCase saveConfigUseCase;
  final ResetConfigUseCase resetConfigUseCase;
  final GetVersionInfoUseCase getVersionInfoUseCase;

  /// Loads the persisted configuration and app version metadata into the
  /// editable state.
  Future<void> load() async {
    try {
      final config = await loadConfigUseCase.execute();
      var version = AppVersion.unknown;
      try {
        version = await getVersionInfoUseCase.execute();
      } catch (error) {
        // Version resolution is non-critical — keep the UI usable.
        AppLogger.warning('Failed to load version info: $error');
      }
      if (!isClosed) {
        emit(state.copyWith(config: config, version: version, isLoading: false));
      }
    } catch (error, stack) {
      AppLogger.error('Failed to load system config', error, stack);
      if (!isClosed) {
        emit(state.copyWith(isLoading: false, error: 'Failed to load config'));
      }
    }
  }

  /// Updates a single field of the working copy (marks it dirty).
  void update({
    bool? autoAcceptIncoming,
    bool? networkDiscovery,
    bool? e2eEncryption,
    int? sessionTimeoutMinutes,
    bool? showHudLogs,
  }) {
    if (isClosed) {
      return;
    }
    emit(
      state.copyWith(
        config: state.config.copyWith(
          autoAcceptIncoming: autoAcceptIncoming,
          networkDiscovery: networkDiscovery,
          e2eEncryption: e2eEncryption,
          sessionTimeoutMinutes: sessionTimeoutMinutes,
          showHudLogs: showHudLogs,
        ),
        dirty: true,
        saved: false,
        error: null,
      ),
    );
  }

  /// Persists the working copy.
  Future<void> save() async {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(isSaving: true, error: null));
    try {
      await saveConfigUseCase.execute(state.config);
      if (!isClosed) {
        emit(
          state.copyWith(isSaving: false, dirty: false, saved: true),
        );
      }
      AppLogger.info('System config saved');
    } catch (error, stack) {
      AppLogger.error('Failed to save system config', error, stack);
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, error: 'Failed to save config'));
      }
    }
  }

  /// Restores and persists the default configuration.
  Future<void> reset() async {
    if (isClosed) {
      return;
    }
    emit(state.copyWith(isSaving: true, error: null));
    try {
      await resetConfigUseCase.execute();
      if (!isClosed) {
        emit(
          state.copyWith(
            config: AppConfig.defaults,
            isSaving: false,
            dirty: false,
            saved: true,
          ),
        );
      }
      AppLogger.info('System config reset to defaults');
    } catch (error, stack) {
      AppLogger.error('Failed to reset system config', error, stack);
      if (!isClosed) {
        emit(state.copyWith(isSaving: false, error: 'Failed to reset config'));
      }
    }
  }
}
