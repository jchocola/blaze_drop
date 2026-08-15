import 'package:flutter/material.dart';

import '../../../../core/theme/theme.dart';
import '../../domain/entities/server_shared_file.dart';

/// A file row in the "AVAILABLE ON SERVER" list (FUNCTIONALITY.md §5.3).
///
/// [onDownload] lets the host pull a copy of the file into its local
/// received folder (FUNCTIONALITY.md §5.4 host download).
class StorageTile extends StatelessWidget {
  const StorageTile({super.key, required this.file, this.onDownload});

  final ServerSharedFile file;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 20,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.codeSm.copyWith(
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${file.sizeLabel} • ${(file.mimeType ?? 'FILE').toUpperCase()}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (onDownload == null)
            Text(
              'SHARED',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.tertiaryContainer,
              ),
            )
          else
            InkWell(
              onTap: onDownload,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(
                    color: AppColors.primaryContainer,
                    width: 1,
                  ),
                  borderRadius: AppTheme.sharp,
                ),
                child: Text(
                  'GET',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.primaryContainer,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
