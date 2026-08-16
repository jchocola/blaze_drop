import 'package:permission_handler/permission_handler.dart' as ph;

import '../../domain/entities/permission_requirement.dart';

/// Describes a platform permission and how it maps to the domain model.
class PermissionDefinition {
  const PermissionDefinition({
    required this.permission,
    required this.category,
    required this.title,
    required this.description,
    this.isMandatory = true,
  });

  final ph.Permission permission;
  final PermissionCategory category;
  final String title;
  final String description;
  final bool isMandatory;

  PermissionRequirement toRequirement(PermissionStatusType status) {
    return PermissionRequirement(
      id: category.name,
      category: category,
      title: title,
      description: description,
      isMandatory: isMandatory,
      status: status,
    );
  }
}

/// Platform-specific permission sets (RULE.md §1.1).
abstract final class PermissionDefinitions {
  /// Mandatory permissions on Android.
  static const List<PermissionDefinition> android = [
    PermissionDefinition(
      permission: ph.Permission.locationWhenInUse,
      category: PermissionCategory.location,
      title: 'Location Access',
      description:
          'Android requires location permission for Wi-Fi Direct discovery and '
          'local network scanning. BlazeDrop never uploads your location.',
    ),
    PermissionDefinition(
      permission: ph.Permission.nearbyWifiDevices,
      category: PermissionCategory.nearbyWifi,
      title: 'Nearby Devices',
      description:
          'Discover and connect to other nodes on your local network — '
          'no internet connection needed.',
    ),
    PermissionDefinition(
      permission: ph.Permission.notification,
      category: PermissionCategory.notifications,
      title: 'Notifications',
      description:
          'Transfer completion alerts and incoming connection requests, even '
          'when the app is in the background.',
    ),
    PermissionDefinition(
      // Maps to READ_MEDIA_IMAGES on Android 13+ and READ_EXTERNAL_STORAGE on
      // older versions — this is what the app actually needs (saving received
      // photos to the gallery). Using Permission.storage here reports "denied"
      // forever on Android 13+ and spams
      // "No permissions found in manifest for: ...".
      permission: ph.Permission.photos,
      category: PermissionCategory.storage,
      title: 'Storage Access',
      description:
          'Access your device photos and media so received files can be saved '
          'to the gallery. App-internal transfers never need this.',
    ),
  ];

  /// iOS grants local-network access automatically via Info.plist
  /// (`NSBonjourServices` / `NSLocalNetworkUsageDescription`); there is no
  /// runtime prompt, so the requirement is reported as already granted.
  static const PermissionRequirement iosLocalNetwork = PermissionRequirement(
    id: 'local_network',
    category: PermissionCategory.localNetwork,
    title: 'Local Network',
    description:
        'BlazeDrop uses Bonjour to discover nearby devices. Access is enabled '
        'through your iOS settings.',
    isMandatory: true,
    status: PermissionStatusType.granted,
  );
}
