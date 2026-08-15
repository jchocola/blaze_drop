import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/use_cases/check_permissions_use_case.dart';
import '../../domain/use_cases/open_app_settings_use_case.dart';
import '../../domain/use_cases/request_permissions_use_case.dart';
import 'onboarding_state.dart';

/// Orchestrates the Module A onboarding flow:
///
/// splash → permission check → (granted) home | (pending) educational screen.
///
/// The cubit contains no business logic — it delegates to use cases and maps
/// results into immutable [OnboardingState]s (RULE.md §2).
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required this.checkPermissionsUseCase,
    required this.requestPermissionsUseCase,
    required this.openAppSettingsUseCase,
    this.splashDelay = AppConstants.splashDuration,
  }) : super(const OnboardingState());

  final CheckPermissionsUseCase checkPermissionsUseCase;
  final RequestPermissionsUseCase requestPermissionsUseCase;
  final OpenAppSettingsUseCase openAppSettingsUseCase;

  /// Splash hold time before the initial permission check. Injectable for
  /// faster tests.
  final Duration splashDelay;

  /// Runs the splash timer, then performs the initial permission check.
  Future<void> initialize() async {
    await Future<void>.delayed(splashDelay);
    try {
      final permissions = await checkPermissionsUseCase.execute();
      emit(OnboardingState(permissions: permissions, isInitialized: true));
      AppLogger.debug(
        'Permissions checked: ${permissions.map((p) => '${p.id}=${p.status.name}').join(', ')}',
      );
    } catch (e, st) {
      AppLogger.error('Initial permission check failed', e, st);
      emit(
        const OnboardingState(
          isInitialized: true,
          error: 'Permission check failed',
        ),
      );
    }
  }

  /// Requests every required permission from the OS.
  Future<void> requestPermissions() async {
    emit(state.copyWith(isRequesting: true, error: null));
    try {
      final permissions = await requestPermissionsUseCase.execute();
      emit(state.copyWith(permissions: permissions, isRequesting: false));
      AppLogger.debug(
        'Permissions requested: ${permissions.map((p) => '${p.id}=${p.status.name}').join(', ')}',
      );
    } catch (e, st) {
      AppLogger.error('Permission request failed', e, st);
      emit(
        state.copyWith(
          isRequesting: false,
          error: 'Failed to request permissions',
        ),
      );
    }
  }

  /// Opens the OS settings page (used when a permission is permanently denied).
  Future<void> openSettings() async {
    try {
      await openAppSettingsUseCase.execute();
    } catch (e, st) {
      AppLogger.error('Failed to open app settings', e, st);
    }
  }
}
