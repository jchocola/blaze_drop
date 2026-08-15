import 'package:blaze_drop/features/onboarding/domain/entities/permission_requirement.dart';
import 'package:blaze_drop/features/onboarding/domain/repositories/permission_repository.dart';
import 'package:blaze_drop/features/onboarding/domain/use_cases/request_permissions_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockPermissionRepository extends Mock implements PermissionRepository {}

void main() {
  group('RequestPermissionsUseCase', () {
    late _MockPermissionRepository repository;
    late RequestPermissionsUseCase useCase;

    setUp(() {
      repository = _MockPermissionRepository();
      useCase = RequestPermissionsUseCase(repository);
    });

    test('delegates to the repository and returns updated statuses', () async {
      final granted = <PermissionRequirement>[
        const PermissionRequirement(
          id: 'notifications',
          category: PermissionCategory.notifications,
          title: 'Notifications',
          description: 'Alerts.',
          status: PermissionStatusType.granted,
        ),
      ];
      when(
        () => repository.requestRequiredPermissions(),
      ).thenAnswer((_) async => granted);

      final result = await useCase.execute();

      expect(result, granted);
      verify(() => repository.requestRequiredPermissions()).called(1);
    });
  });
}
