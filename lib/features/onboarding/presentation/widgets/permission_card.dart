import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/permission_requirement.dart';

extension PermissionCategoryUi on PermissionCategory {
  IconData get icon => switch (this) {
    PermissionCategory.location => Icons.location_on_outlined,
    PermissionCategory.nearbyWifi => Icons.wifi_tethering_outlined,
    PermissionCategory.notifications => Icons.notifications_none,
    PermissionCategory.storage => Icons.folder_open_outlined,
    PermissionCategory.localNetwork => Icons.lan_outlined,
  };
}

/// A single permission row: icon, explanation and a status tag.
///
/// Sharp corners, 1px stroke, "label-caps" metadata (DESIGN.md).
class PermissionCard extends StatelessWidget {
  const PermissionCard({super.key, required this.requirement});

  final PermissionRequirement requirement;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon block.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLowest,
              border: Border.all(color: AppColors.outlineVariant, width: 1),
              borderRadius: AppTheme.sharp,
            ),
            child: Icon(
              requirement.category.icon,
              size: 22,
              color: _accentForStatus(requirement.status),
            ),
          ),
          const SizedBox(width: 12),
          // Title + description.
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        requirement.title.toUpperCase(),
                        style: AppTextStyles.labelCaps.copyWith(
                          color: AppColors.onSurface,
                        ),
                      ),
                    ),
                    _StatusTag(status: requirement.status),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  requirement.description,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _accentForStatus(PermissionStatusType status) {
    return switch (status) {
      PermissionStatusType.granted ||
      PermissionStatusType.limited => AppColors.tertiaryContainer,
      PermissionStatusType.permanentlyDenied ||
      PermissionStatusType.restricted => AppColors.secondaryContainer,
      PermissionStatusType.denied => AppColors.error,
      PermissionStatusType.unknown => AppColors.onSurfaceVariant,
    };
  }
}

class _StatusTag extends StatelessWidget {
  const _StatusTag({required this.status});

  final PermissionStatusType status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      PermissionStatusType.granted || PermissionStatusType.limited => (
        status == PermissionStatusType.limited ? 'LIMITED' : 'GRANTED',
        AppColors.tertiaryContainer,
        AppColors.onTertiary,
      ),
      PermissionStatusType.permanentlyDenied => (
        'BLOCKED',
        AppColors.secondaryContainer,
        AppColors.onSecondary,
      ),
      PermissionStatusType.restricted => (
        'RESTRICTED',
        AppColors.secondaryContainer,
        AppColors.onSecondary,
      ),
      PermissionStatusType.denied => (
        'DENIED',
        AppColors.errorContainer,
        AppColors.onErrorContainer,
      ),
      PermissionStatusType.unknown => (
        'PENDING',
        AppColors.surfaceContainerHighest,
        AppColors.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppTheme.sharp,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          fontSize: 10,
          letterSpacing: 1.0,
          color: foreground,
        ),
      ),
    );
  }
}
