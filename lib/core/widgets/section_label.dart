import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// A small uppercase technical label with a leading accent bar.
///
/// Used for metadata and section headers ("label-caps", DESIGN.md).
class SectionLabel extends StatelessWidget {
  const SectionLabel({
    super.key,
    required this.text,
    this.color = AppColors.onSurfaceVariant,
    this.showBar = true,
  });

  final String text;
  final Color color;
  final bool showBar;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showBar) ...[
          Container(width: 3, height: 12, color: color),
          const SizedBox(width: 6),
        ],
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: AppTextStyles.labelCaps.copyWith(color: color),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
