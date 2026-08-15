import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../theme/theme.dart';

/// Visual variant of [BlazeButton].
enum BlazeButtonVariant {
  /// Solid Electric Cyan fill (primary navigation / "active" actions).
  primary,

  /// Solid Vibrant Orange fill (critical CTAs such as "Upload" / "Send").
  cta,

  /// 2px stroke, no fill (secondary actions).
  outline,

  /// Ghost: no fill, thin outline (tertiary actions).
  ghost,
}

/// A sharp-cornered, uppercase command button matching DESIGN.md components.
class BlazeButton extends StatelessWidget {
  const BlazeButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.variant = BlazeButtonVariant.primary,
    this.isLoading = false,
    this.icon,
    this.enabled = true,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final BlazeButtonVariant variant;
  final bool isLoading;
  final IconData? icon;
  final bool enabled;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final canTap = enabled && !isLoading && onPressed != null;
    final (background, foreground, border) = _resolveColors();

    return SizedBox(
      width: double.infinity,
      height: compact ? 40 : AppConstants.buttonHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: background,
          border: border,
          borderRadius: AppTheme.sharp,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: canTap ? onPressed : null,
            splashColor: foreground.withValues(alpha: 0.18),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isLoading) ...[
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: foreground,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  if (!isLoading && icon != null) ...[
                    Icon(icon, size: 18, color: foreground),
                    const SizedBox(width: 8),
                  ],
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        label.toUpperCase(),
                        style: TextStyle(
                          fontFamily: AppTextStyles.monoFont,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.4,
                          color: foreground,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  (Color?, Color, BoxBorder?) _resolveColors() {
    switch (variant) {
      case BlazeButtonVariant.primary:
        return (
          enabled ? AppColors.primaryContainer : AppColors.surfaceContainerHigh,
          enabled ? AppColors.onPrimary : AppColors.onSurfaceVariant,
          null,
        );
      case BlazeButtonVariant.cta:
        return (
          enabled
              ? AppColors.secondaryContainer
              : AppColors.surfaceContainerHigh,
          enabled ? AppColors.onSecondary : AppColors.onSurfaceVariant,
          null,
        );
      case BlazeButtonVariant.outline:
        return (
          Colors.transparent,
          enabled ? AppColors.primaryContainer : AppColors.onSurfaceVariant,
          Border.all(
            color: enabled
                ? AppColors.primaryContainer
                : AppColors.outlineVariant,
            width: 2,
          ),
        );
      case BlazeButtonVariant.ghost:
        return (
          Colors.transparent,
          enabled ? AppColors.onSurface : AppColors.onSurfaceVariant,
          Border.all(color: AppColors.outlineVariant, width: 1),
        );
    }
  }
}
