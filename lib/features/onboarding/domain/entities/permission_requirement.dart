import 'package:equatable/equatable.dart';

/// Logical categories of permissions required by BlazeDrop.
enum PermissionCategory {
  /// Location — required by Android for Wi-Fi Direct / network scanning.
  location,

  /// Nearby Wi-Fi devices (Android 13+).
  nearbyWifi,

  /// Local notifications (transfer completion, incoming requests).
  notifications,

  /// Storage access (reading / writing files).
  storage,

  /// iOS local network (Bonjour) — configured via Info.plist.
  localNetwork,
}

/// Platform-agnostic status of a single permission.
enum PermissionStatusType {
  unknown,
  granted,
  limited,
  denied,
  permanentlyDenied,
  restricted,
}

/// A single permission the app requires, with its current status.
///
/// This is the domain-level model; it does not depend on any plugin.
class PermissionRequirement extends Equatable {
  const PermissionRequirement({
    required this.id,
    required this.category,
    required this.title,
    required this.description,
    this.isMandatory = true,
    this.status = PermissionStatusType.unknown,
  });

  /// Stable identifier (e.g. `location`, `notifications`).
  final String id;

  final PermissionCategory category;
  final String title;
  final String description;

  /// Whether the app refuses to continue without this permission.
  final bool isMandatory;

  final PermissionStatusType status;

  bool get isGranted =>
      status == PermissionStatusType.granted ||
      status == PermissionStatusType.limited;

  bool get isDenied =>
      status == PermissionStatusType.denied ||
      status == PermissionStatusType.permanentlyDenied ||
      status == PermissionStatusType.restricted;

  bool get isPermanentlyDenied =>
      status == PermissionStatusType.permanentlyDenied;

  PermissionRequirement copyWith({PermissionStatusType? status}) {
    return PermissionRequirement(
      id: id,
      category: category,
      title: title,
      description: description,
      isMandatory: isMandatory,
      status: status ?? this.status,
    );
  }

  @override
  List<Object?> get props => [
    id,
    category,
    title,
    description,
    isMandatory,
    status,
  ];
}
