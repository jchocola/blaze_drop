import '../repositories/onboarding_repository.dart';

/// Marks onboarding as completed so it is not shown on subsequent launches.
class CompleteOnboardingUseCase {
  const CompleteOnboardingUseCase(this._repository);

  final OnboardingRepository _repository;

  Future<void> execute() => _repository.markCompleted();
}
