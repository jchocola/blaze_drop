import 'package:blaze_drop/features/p2p/domain/repositories/nearby_permission_repository.dart';
import 'package:blaze_drop/features/p2p/domain/use_cases/open_nearby_settings_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockNearbyPermissionRepository extends Mock
    implements NearbyPermissionRepository {}

void main() {
  group('OpenNearbySettingsUseCase', () {
    late _MockNearbyPermissionRepository repository;
    late OpenNearbySettingsUseCase useCase;

    setUp(() {
      repository = _MockNearbyPermissionRepository();
      useCase = OpenNearbySettingsUseCase(repository);
    });

    test('delegates to the repository openSettings', () async {
      when(() => repository.openSettings()).thenAnswer((_) async {});

      await useCase.execute();

      verify(() => repository.openSettings()).called(1);
    });
  });
}
