import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/server_upload_event.dart';

/// A single row in the host HUD transfer log (FUNCTIONALITY.md §5.4
/// "Incoming Files").
class UploadLogTile extends StatelessWidget {
  const UploadLogTile({super.key, required this.event});

  final ServerUploadEvent event;

  @override
  Widget build(BuildContext context) {
    final (statusColor, statusText) = switch (event.status) {
      ServerUploadStatus.receiving => (
        AppColors.secondaryContainer,
        'RECEIVING',
      ),
      ServerUploadStatus.completed => (
        AppColors.tertiaryContainer,
        'DONE',
      ),
      ServerUploadStatus.failed => (AppColors.error, 'FAILED'),
    };
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  event.fileName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.codeSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
              ),
              SectionLabel(
                text: statusText,
                color: statusColor,
                showBar: false,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Text(
                event.sizeLabel,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const Spacer(),
              if (event.totalBytes > 0)
                Text(
                  '${(event.progress * 100).round()}%',
                  style: AppTextStyles.codeSm.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRect(
            child: LinearProgressIndicator(
              value: event.progress,
              minHeight: 8,
              color: statusColor,
              backgroundColor: AppColors.surfaceContainerHighest,
            ),
          ),
        ],
      ),
    );
  }
}
