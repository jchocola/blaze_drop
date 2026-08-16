import 'package:equatable/equatable.dart';

import '../../domain/entities/permission_requirement.dart';

/// UI state for the Module A onboarding flow.
class OnboardingState extends Equatable {
  const OnboardingState({
    this.permissions = const [],
    this.isInitialized = false,
    this.isRequesting = false,
    this.error,
  });

  /// Status of every required permission.
  final List<PermissionRequirement> permissions;

  /// True once the splash timer has elapsed and the initial check completed.
  final bool isInitialized;

  /// True while a permission request is in flight.
  final bool isRequesting;

  final String? error;

  /// True when every mandatory permission has been granted.
  bool get allMandatoryGranted =>
      permissions.every((p) => !p.isMandatory || p.isGranted);

  /// True when at least one permission is permanently denied (needs settings).
  bool get hasPermanentDenial => permissions.any((p) => p.isPermanentlyDenied);

  /// True when at least one mandatory permission is still pending.
  bool get hasPendingPermission =>
      permissions.any((p) => p.isMandatory && !p.isGranted);

  OnboardingState copyWith({
    List<PermissionRequirement>? permissions,
    bool? isInitialized,
    bool? isRequesting,
    String? error,
  }) {
    return OnboardingState(
      permissions: permissions ?? this.permissions,
      isInitialized: isInitialized ?? this.isInitialized,
      isRequesting: isRequesting ?? this.isRequesting,
      error: error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [permissions, isInitialized, isRequesting, error];
}
