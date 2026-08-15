import '../../domain/entities/app_version.dart';
import '../../domain/repositories/version_repository.dart';
import '../datasources/version_package_data_source.dart';

/// Concrete [VersionRepository] backed by [VersionPackageDataSource].
class VersionRepositoryImpl implements VersionRepository {
  const VersionRepositoryImpl(this._dataSource);

  final VersionPackageDataSource _dataSource;

  @override
  Future<AppVersion> getVersionInfo() => _dataSource.getVersionInfo();
}
