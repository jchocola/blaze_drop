/// Tracks whether the user has finished (or skipped) the onboarding flow.
///
/// Used to decide splash routing: a user who already completed onboarding is
/// sent straight to Home even if some non-essential permission is missing —
/// those are re-requested at point of use instead.
abstract interface class OnboardingRepository {
  /// True when onboarding was previously completed or explicitly skipped.
  Future<bool> hasCompleted();

  /// Marks onboarding as completed (granted all, or skipped via CONTINUE).
  Future<void> markCompleted();
}
