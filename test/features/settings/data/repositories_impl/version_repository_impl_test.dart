import 'package:blaze_drop/features/settings/data/datasources/version_package_data_source.dart';
import 'package:blaze_drop/features/settings/data/repositories_impl/version_repository_impl.dart';
import 'package:blaze_drop/features/settings/domain/entities/app_version.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockVersionDataSource extends Mock implements VersionPackageDataSource {}

void main() {
  group('VersionRepositoryImpl', () {
    test('delegates getVersionInfo to the package data source', () async {
      const version = AppVersion(
        version: '0.1.0',
        buildNumber: '7',
        packageName: 'com.example.blaze_drop',
      );
      final dataSource = _MockVersionDataSource();
      when(
        () => dataSource.getVersionInfo(),
      ).thenAnswer((_) async => version);

      final result = await VersionRepositoryImpl(dataSource).getVersionInfo();

      expect(result, version);
      verify(() => dataSource.getVersionInfo()).called(1);
    });
  });
}
