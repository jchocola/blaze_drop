import '../../domain/repositories/onboarding_repository.dart';
import '../datasources/onboarding_local_data_source.dart';

/// Concrete [OnboardingRepository] backed by `SharedPreferences`.
class OnboardingRepositoryImpl implements OnboardingRepository {
  const OnboardingRepositoryImpl(this._dataSource);

  final OnboardingLocalDataSource _dataSource;

  @override
  Future<bool> hasCompleted() => _dataSource.hasCompleted();

  @override
  Future<void> markCompleted() => _dataSource.markCompleted();
}
