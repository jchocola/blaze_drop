import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';

/// Compact link-quality readout: 5 bars + percentage (FUNCTIONALITY.md §4.1).
class SignalMeter extends StatelessWidget {
  const SignalMeter({super.key, required this.strength, this.compact = false});

  /// 0..100.
  final int strength;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final filled = ((strength.clamp(0, 100)) / 20).ceil().clamp(0, 5);
    final color = _colorFor(strength);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(5, (index) {
            return Container(
              width: 4,
              height: 4 + index * 2,
              margin: const EdgeInsets.only(right: 2),
              color: index < filled
                  ? color
                  : AppColors.outlineVariant.withValues(alpha: 0.6),
            );
          }),
        ),
        if (!compact) ...[
          const SizedBox(width: 6),
          Text(
            '$strength%',
            style: AppTextStyles.labelCaps.copyWith(
              fontSize: 10,
              color: color,
            ),
          ),
        ],
      ],
    );
  }

  Color _colorFor(int strength) {
    if (strength >= 70) {
      return AppColors.tertiaryContainer;
    }
    if (strength >= 40) {
      return AppColors.primaryContainer;
    }
    return AppColors.secondaryContainer;
  }
}
