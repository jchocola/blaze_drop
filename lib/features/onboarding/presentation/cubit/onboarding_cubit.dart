import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/use_cases/check_permissions_use_case.dart';
import '../../domain/use_cases/complete_onboarding_use_case.dart';
import '../../domain/use_cases/get_onboarding_completion_use_case.dart';
import '../../domain/use_cases/open_app_settings_use_case.dart';
import '../../domain/use_cases/request_permissions_use_case.dart';
import 'onboarding_state.dart';

/// Orchestrates the Module A onboarding flow:
///
/// splash → permission check → (granted or previously completed) home |
/// (pending) educational screen.
///
/// Onboarding is **never a hard gate**: if the user skips it, they still enter
/// Home and the missing permissions are re-requested at point of use.
///
/// The cubit contains no business logic — it delegates to use cases and maps
/// results into immutable [OnboardingState]s (RULE.md §2).
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required this.checkPermissionsUseCase,
    required this.requestPermissionsUseCase,
    required this.openAppSettingsUseCase,
    required this.getOnboardingCompletionUseCase,
    required this.completeOnboardingUseCase,
    this.splashDelay = AppConstants.splashDuration,
  }) : super(const OnboardingState());

  final CheckPermissionsUseCase checkPermissionsUseCase;
  final RequestPermissionsUseCase requestPermissionsUseCase;
  final OpenAppSettingsUseCase openAppSettingsUseCase;
  final GetOnboardingCompletionUseCase getOnboardingCompletionUseCase;
  final CompleteOnboardingUseCase completeOnboardingUseCase;

  /// Splash hold time before the initial permission check. Injectable for
  /// faster tests.
  final Duration splashDelay;

  /// Runs the splash timer, then performs the initial permission check and
  /// loads whether onboarding was previously completed/skipped.
  Future<void> initialize() async {
    await Future<void>.delayed(splashDelay);
    try {
      final completed = await getOnboardingCompletionUseCase.execute();
      final permissions = await checkPermissionsUseCase.execute();
      emit(OnboardingState(
        permissions: permissions,
        isInitialized: true,
        completed: completed,
      ));
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

  /// Requests every required permission from the OS. When all mandatory
  /// permissions end up granted, onboarding is marked as completed.
  Future<void> requestPermissions() async {
    emit(state.copyWith(isRequesting: true, error: null));
    try {
      final permissions = await requestPermissionsUseCase.execute();
      var completed = state.completed;
      if (permissions.every((p) => !p.isMandatory || p.isGranted)) {
        await _persistCompleted();
        completed = true;
      }
      emit(state.copyWith(
        permissions: permissions,
        isRequesting: false,
        completed: completed,
      ));
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

  /// Lets the user into the app without granting every permission. Missing
  /// permissions are re-requested at point of use. Persisted so onboarding is
  /// not shown again on subsequent launches.
  Future<void> finishOnboarding() async {
    await _persistCompleted();
    if (!isClosed) {
      emit(state.copyWith(completed: true));
    }
  }

  Future<void> _persistCompleted() async {
    try {
      await completeOnboardingUseCase.execute();
    } catch (e, st) {
      AppLogger.error('Failed to persist onboarding completion', e, st);
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
