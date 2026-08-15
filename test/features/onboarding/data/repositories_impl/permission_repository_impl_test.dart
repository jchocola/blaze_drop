import 'package:blaze_drop/features/onboarding/data/datasources/permission_local_data_source.dart';
import 'package:blaze_drop/features/onboarding/data/repositories_impl/permission_repository_impl.dart';
import 'package:blaze_drop/features/onboarding/domain/entities/permission_requirement.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:permission_handler/permission_handler.dart' as ph;

class _MockPermissionLocalDataSource extends Mock
    implements PermissionLocalDataSource {}

void main() {
  group('PermissionRepositoryImpl', () {
    late _MockPermissionLocalDataSource dataSource;
    late PermissionRepositoryImpl repository;

    setUpAll(() {
      registerFallbackValue(ph.Permission.locationWhenInUse);
    });

    setUp(() {
      dataSource = _MockPermissionLocalDataSource();
      repository = PermissionRepositoryImpl(dataSource);
    });

    tearDown(() {
      debugDefaultTargetPlatformOverride = null;
    });

    test(
      'returns all mandatory Android permissions with mapped statuses',
      () async {
        debugDefaultTargetPlatformOverride = TargetPlatform.android;
        when(
          () => dataSource.getStatus(any()),
        ).thenAnswer((_) async => PermissionStatusType.denied);

        final result = await repository.getRequiredPermissions();

        expect(result, hasLength(4));
        expect(
          result.map((p) => p.category),
          containsAll([
            PermissionCategory.location,
            PermissionCategory.nearbyWifi,
            PermissionCategory.notifications,
            PermissionCategory.storage,
          ]),
        );
        expect(result.every((p) => p.isMandatory), isTrue);
        expect(
          result.every((p) => p.status == PermissionStatusType.denied),
          isTrue,
        );
        verify(() => dataSource.getStatus(any())).called(4);
      },
    );

    test('requests every Android permission via the data source', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      when(
        () => dataSource.request(any()),
      ).thenAnswer((_) async => PermissionStatusType.granted);

      final result = await repository.requestRequiredPermissions();

      expect(result, hasLength(4));
      expect(result.every((p) => p.isGranted), isTrue);
      verify(() => dataSource.request(any())).called(4);
    });

    test('iOS returns a single granted local-network requirement', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;

      final result = await repository.getRequiredPermissions();

      expect(result, hasLength(1));
      expect(result.single.category, PermissionCategory.localNetwork);
      expect(result.single.isGranted, isTrue);
      verifyNever(() => dataSource.getStatus(any()));
    });

    test('openAppSettings delegates to the data source', () async {
      when(
        () => dataSource.openAppSettings(),
      ).thenAnswer((_) => Future<void>.value());

      await repository.openAppSettings();

      verify(() => dataSource.openAppSettings()).called(1);
    });
  });
}
