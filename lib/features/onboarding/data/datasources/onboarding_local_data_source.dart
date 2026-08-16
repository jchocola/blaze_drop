import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/constants.dart';

/// Persists whether the user has finished (or skipped) the onboarding flow.
///
/// Stored in `SharedPreferences` so that a user who did not grant every
/// permission on first launch is not blocked again on subsequent launches —
/// missing permissions are then requested at point of use instead.
class OnboardingLocalDataSource {
  OnboardingLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  /// True when onboarding was previously completed or explicitly skipped.
  Future<bool> hasCompleted() async =>
      _prefs.getBool(StorageKeys.onboardingComplete) ?? false;

  /// Marks onboarding as completed (granted all, or skipped via CONTINUE).
  Future<void> markCompleted() =>
      _prefs.setBool(StorageKeys.onboardingComplete, true);
}
