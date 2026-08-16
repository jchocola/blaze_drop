import '../../domain/repositories/nearby_permission_repository.dart';
import '../datasources/nearby_permission_data_source.dart';

/// Concrete [NearbyPermissionRepository] backed by `permission_handler`.
class NearbyPermissionRepositoryImpl implements NearbyPermissionRepository {
  const NearbyPermissionRepositoryImpl(this._dataSource);

  final NearbyPermissionDataSource _dataSource;

  @override
  Future<bool> ensureNearbyPermission() =>
      _dataSource.ensureNearbyPermission();

  @override
  Future<void> openSettings() => _dataSource.openSettings();
}
