import '../repositories/onboarding_repository.dart';

/// Reads whether the user has already completed (or skipped) onboarding.
class GetOnboardingCompletionUseCase {
  const GetOnboardingCompletionUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<bool> execute() => _repository.hasCompleted();
}
