import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/connected_client.dart';

/// A single guest row in the "ACTIVE_CONNECTIONS" list
/// (FUNCTIONALITY.md §5.4, mock "NODE-ALPHA-9 … IDLE").
class ConnectionTile extends StatelessWidget {
  const ConnectionTile({super.key, required this.client});

  final ConnectedClient client;

  @override
  Widget build(BuildContext context) {
    final syncing = client.state == ClientConnectionState.syncing;
    final statusColor = syncing
        ? AppColors.secondaryContainer
        : AppColors.tertiaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Icon(
            syncing ? Icons.sync : Icons.language_outlined,
            size: 20,
            color: syncing
                ? AppColors.secondaryContainer
                : AppColors.primaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name.isEmpty ? 'GUEST' : client.name,
                  style: AppTextStyles.codeSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  client.ipAddress,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          SectionLabel(
            text: syncing ? 'SYNCING…' : 'IDLE',
            color: statusColor,
            showBar: false,
          ),
        ],
      ),
    );
  }
}
