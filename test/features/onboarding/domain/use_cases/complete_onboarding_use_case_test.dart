import 'package:blaze_drop/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/complete_onboarding_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOnboardingRepository extends Mock
    implements OnboardingRepository {}

void main() {
  group('CompleteOnboardingUseCase', () {
    late _MockOnboardingRepository repository;
    late CompleteOnboardingUseCase useCase;

    setUp(() {
      repository = _MockOnboardingRepository();
      useCase = CompleteOnboardingUseCase(repository);
    });

    test('delegates to the repository', () async {
      when(() => repository.markCompleted()).thenAnswer((_) async {});

      await useCase.execute();

      verify(() => repository.markCompleted()).called(1);
    });
  });
}
