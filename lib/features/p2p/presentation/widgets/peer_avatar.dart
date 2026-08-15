import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/peer_device.dart';
import 'peer_platform_ui.dart';

/// Generated initials avatar with the device's platform icon overlaid.
///
/// Sharp square, dark fill, cyan stroke (DESIGN.md "luminance & stroke").
class PeerAvatar extends StatelessWidget {
  const PeerAvatar({super.key, required this.peer, this.size = 44});

  final PeerDevice peer;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border.all(color: AppColors.primaryContainer, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      child: Stack(
        children: [
          Center(
            child: Text(
              peer.initials,
              style: AppTextStyles.labelCaps.copyWith(
                fontSize: size * 0.3,
                color: AppColors.primaryContainer,
              ),
            ),
          ),
          Positioned(
            right: 2,
            bottom: 2,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerHigh,
                border: Border.all(
                  color: AppColors.outlineVariant,
                  width: 0.5,
                ),
                borderRadius: AppTheme.sharp,
              ),
              child: Icon(
                peer.platform.icon,
                size: size * 0.2,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
