import 'package:blaze_drop/features/onboarding/domain/entities/permission_requirement.dart';
import 'package:blaze_drop/features/onboarding/domain/repositories/permission_repository.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/check_permissions_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPermissionRepository extends Mock implements PermissionRepository {}

void main() {
  group('CheckPermissionsUseCase', () {
    late _MockPermissionRepository repository;
    late CheckPermissionsUseCase useCase;

    setUp(() {
      repository = _MockPermissionRepository();
      useCase = CheckPermissionsUseCase(repository);
    });

    test('delegates to the repository', () async {
      final requirements = <PermissionRequirement>[
        const PermissionRequirement(
          id: 'location',
          category: PermissionCategory.location,
          title: 'Location Access',
          description: 'Required for discovery.',
          status: PermissionStatusType.granted,
        ),
      ];
      when(
        () => repository.getRequiredPermissions(),
      ).thenAnswer((_) async => requirements);

      final result = await useCase.execute();

      expect(result, requirements);
      verify(() => repository.getRequiredPermissions()).called(1);
    });

    test('propagates failures', () {
      when(
        () => repository.getRequiredPermissions(),
      ).thenThrow(Exception('boom'));

      expect(useCase.execute(), throwsException);
    });
  });
}
