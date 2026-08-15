import 'package:flutter/foundation.dart';

import '../../domain/entities/permission_requirement.dart';
import '../../domain/repositories/permission_repository.dart';
import '../datasources/permission_local_data_source.dart';
import '../models/permission_definitions.dart';

/// Concrete [PermissionRepository] backed by `permission_handler`.
class PermissionRepositoryImpl implements PermissionRepository {
  const PermissionRepositoryImpl(this._dataSource);

  final PermissionLocalDataSource _dataSource;

  @override
  Future<List<PermissionRequirement>> getRequiredPermissions() async {
    final definitions = _definitionsForPlatform();
    if (definitions == null) {
      return const [PermissionDefinitions.iosLocalNetwork];
    }
    final requirements = <PermissionRequirement>[];
    for (final definition in definitions) {
      requirements.add(
        definition.toRequirement(
          await _dataSource.getStatus(definition.permission),
        ),
      );
    }
    return requirements;
  }

  @override
  Future<List<PermissionRequirement>> requestRequiredPermissions() async {
    final definitions = _definitionsForPlatform();
    if (definitions == null) {
      return const [PermissionDefinitions.iosLocalNetwork];
    }
    final requirements = <PermissionRequirement>[];
    for (final definition in definitions) {
      requirements.add(
        definition.toRequirement(
          await _dataSource.request(definition.permission),
        ),
      );
    }
    return requirements;
  }

  @override
  Future<void> openAppSettings() => _dataSource.openAppSettings();

  /// Returns the platform permission set, or `null` for platforms that expose
  /// no runtime permissions (desktop / web / iOS).
  List<PermissionDefinition>? _definitionsForPlatform() {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return PermissionDefinitions.android;
      case TargetPlatform.iOS:
        return null; // handled by Info.plist configuration.
      default:
        return null; // no runtime permissions on desktop / web.
    }
  }
}
