import 'package:blaze_drop/features/onboarding/data/datasources/onboarding_local_data_source.dart';
import 'package:blaze_drop/features/onboarding/data/repositories_impl/onboarding_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('OnboardingRepositoryImpl', () {
    Future<OnboardingRepositoryImpl> buildRepository() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      return OnboardingRepositoryImpl(OnboardingLocalDataSource(prefs));
    }

    test('hasCompleted is false when nothing was persisted', () async {
      final repository = await buildRepository();
      expect(await repository.hasCompleted(), isFalse);
    });

    test('markCompleted then hasCompleted returns true', () async {
      final repository = await buildRepository();
      await repository.markCompleted();
      expect(await repository.hasCompleted(), isTrue);
    });

    test('completion survives a fresh instance (persisted)', () async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final first =
          OnboardingRepositoryImpl(OnboardingLocalDataSource(prefs));
      await first.markCompleted();

      final second =
          OnboardingRepositoryImpl(OnboardingLocalDataSource(prefs));
      expect(await second.hasCompleted(), isTrue);
    });
  });
}
