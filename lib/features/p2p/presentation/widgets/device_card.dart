import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/peer_device.dart';
import 'peer_avatar.dart';
import 'peer_platform_ui.dart';
import 'signal_meter.dart';

/// A discovered device row (FUNCTIONALITY.md §4.1):
/// avatar + name + platform/IP + signal strength + status tag.
class DeviceCard extends StatelessWidget {
  const DeviceCard({
    super.key,
    required this.peer,
    this.onTap,
    this.trailing,
  });

  final PeerDevice peer;
  final VoidCallback? onTap;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      child: InkWell(
        onTap: onTap,
        splashColor: AppColors.primaryContainer.withValues(alpha: 0.10),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(
              color: peer.isConnected
                  ? AppColors.tertiaryContainer.withValues(alpha: 0.6)
                  : AppColors.outlineVariant,
              width: 1,
            ),
            borderRadius: AppTheme.sharp,
          ),
          child: Row(
            children: [
              PeerAvatar(peer: peer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            peer.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelCaps.copyWith(
                              color: AppColors.onSurface,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (peer.isConnected) _StatusPill.secure(),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      '${peer.platform.label} • ${peer.ipAddress}',
                      style: AppTextStyles.codeSm.copyWith(
                        fontSize: 11,
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              SignalMeter(strength: peer.signalStrength),
              if (trailing != null) ...[
                const SizedBox(width: 8),
                trailing!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Small status pill ("SECURE LINK") shown for connected nodes.
class _StatusPill extends StatelessWidget {
  const _StatusPill();

  static Widget secure() => const _StatusPill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.tertiaryContainer,
        borderRadius: AppTheme.sharp,
      ),
      child: Text(
        'SECURE LINK',
        style: AppTextStyles.labelCaps.copyWith(
          fontSize: 9,
          letterSpacing: 0.8,
          color: AppColors.onTertiary,
        ),
      ),
    );
  }
}
