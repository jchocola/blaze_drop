import 'package:blaze_drop/features/p2p/domain/repositories/nearby_permission_repository.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/ensure_nearby_permission_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNearbyPermissionRepository extends Mock
    implements NearbyPermissionRepository {}

void main() {
  group('EnsureNearbyPermissionUseCase', () {
    late _MockNearbyPermissionRepository repository;
    late EnsureNearbyPermissionUseCase useCase;

    setUp(() {
      repository = _MockNearbyPermissionRepository();
      useCase = EnsureNearbyPermissionUseCase(repository);
    });

    test('returns true when the repository grants access', () async {
      when(
        () => repository.ensureNearbyPermission(),
      ).thenAnswer((_) async => true);

      final result = await useCase.execute();

      expect(result, isTrue);
      verify(() => repository.ensureNearbyPermission()).called(1);
    });

    test('returns false when access is denied', () async {
      when(
        () => repository.ensureNearbyPermission(),
      ).thenAnswer((_) async => false);

      final result = await useCase.execute();

      expect(result, isFalse);
      verify(() => repository.ensureNearbyPermission()).called(1);
    });
  });
}
