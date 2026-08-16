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
/// splash → permission check → (granted OR already completed) home |
/// (pending) educational screen.
///
/// Onboarding is **non-blocking**: the user is never stuck on first entry.
/// If every mandatory permission was not granted they may still continue via
/// [finishOnboarding]; missing permissions are re-requested at point of use
/// (e.g. the P2P nearby gate). The cubit contains no business logic — it
/// delegates to use cases and maps results into immutable [OnboardingState]s
/// (RULE.md §2).
class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit({
    required this.checkPermissionsUseCase,
    required this.requestPermissionsUseCase,
    required this.openAppSettingsUseCase,
    required this.completeOnboardingUseCase,
    required this.getOnboardingCompletionUseCase,
    this.splashDelay = AppConstants.splashDuration,
  }) : super(const OnboardingState());

  final CheckPermissionsUseCase checkPermissionsUseCase;
  final RequestPermissionsUseCase requestPermissionsUseCase;
  final OpenAppSettingsUseCase openAppSettingsUseCase;
  final CompleteOnboardingUseCase completeOnboardingUseCase;
  final GetOnboardingCompletionUseCase getOnboardingCompletionUseCase;

  /// Splash hold time before the initial permission check. Injectable for
  /// faster tests.
  final Duration splashDelay;

  /// Runs the splash timer, then performs the initial permission check.
  ///
  /// If onboarding was already finished on a previous launch, the app goes
  /// straight to Home even when some permission is missing.
  Future<void> initialize() async {
    await Future<void>.delayed(splashDelay);
    try {
      final completed =
          await getOnboardingCompletionUseCase.execute();
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

  /// Requests every required permission from the OS.
  ///
  /// When the request ends with every mandatory permission granted, onboarding
  /// is automatically marked complete so later launches skip this screen.
  Future<void> requestPermissions() async {
    emit(state.copyWith(isRequesting: true, error: null));
    try {
      final permissions = await requestPermissionsUseCase.execute();
      var completed = state.completed;
      if (permissions.every((p) => !p.isMandatory || p.isGranted)) {
        completed = true;
        await completeOnboardingUseCase.execute();
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

  /// Re-checks the current permission statuses **without prompting** the user.
  ///
  /// Used by the SYSTEM CONFIG permissions panel so it stays in sync with the
  /// OS (e.g. after the user changes a permission in system settings).
  Future<void> refreshPermissions() async {
    if (isClosed) {
      return;
    }
    try {
      final permissions = await checkPermissionsUseCase.execute();
      if (!isClosed) {
        emit(state.copyWith(permissions: permissions, error: null));
      }
      AppLogger.debug(
        'Permissions refreshed: ${permissions.map((p) => '${p.id}=${p.status.name}').join(', ')}',
      );
    } catch (e, st) {
      AppLogger.error('Permission refresh failed', e, st);
      if (!isClosed) {
        emit(state.copyWith(error: 'Failed to refresh permissions'));
      }
    }
  }

  /// Marks onboarding as finished and lets the user continue without granting
  /// every permission. Missing permissions are re-requested at point of use.
  Future<void> finishOnboarding() async {
    emit(state.copyWith(isRequesting: true, error: null));
    try {
      await completeOnboardingUseCase.execute();
      emit(state.copyWith(isRequesting: false, completed: true));
      AppLogger.debug('Onboarding finished by user (skip).');
    } catch (e, st) {
      AppLogger.error('Failed to complete onboarding', e, st);
      emit(state.copyWith(isRequesting: false, completed: true));
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
