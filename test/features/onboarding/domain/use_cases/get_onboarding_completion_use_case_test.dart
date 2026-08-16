import 'package:blaze_drop/features/onboarding/domain/repositories/onboarding_repository.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/get_onboarding_completion_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockOnboardingRepository extends Mock
    implements OnboardingRepository {}

void main() {
  group('GetOnboardingCompletionUseCase', () {
    late _MockOnboardingRepository repository;
    late GetOnboardingCompletionUseCase useCase;

    setUp(() {
      repository = _MockOnboardingRepository();
      useCase = GetOnboardingCompletionUseCase(repository);
    });

    test('delegates to the repository', () async {
      when(() => repository.hasCompleted()).thenAnswer((_) async => true);

      final result = await useCase.execute();

      expect(result, isTrue);
      verify(() => repository.hasCompleted()).called(1);
    });
  });
}
