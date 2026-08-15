import 'package:flutter/material.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/history/history_file.dart';
import '../../../../core/history/session_record.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/utils/format_bytes.dart';

/// A single server-session card in the TRANSFER HISTORY tab
/// (FUNCTIONALITY.md mock "HISTORY"): session meta + the files that passed
/// through it.
class SessionTile extends StatelessWidget {
  const SessionTile({super.key, required this.session});

  final SessionRecord session;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.cardPadding,
              vertical: 10,
            ),
            color: AppColors.surfaceContainerHigh,
            child: Row(
              children: [
                const Icon(
                  Icons.dns_outlined,
                  size: 16,
                  color: AppColors.primaryContainer,
                ),
                const SizedBox(width: 8),
                Text(
                  _shortId(session.id),
                  style: AppTextStyles.codeSm.copyWith(
                    color: AppColors.onSurface,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                Text(
                  session.isActive ? 'ACTIVE' : _duration(session),
                  style: AppTextStyles.labelCaps.copyWith(
                    color: session.isActive
                        ? AppColors.tertiaryContainer
                        : AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_clock(session.startedAt)} — '
                  '${session.endedAt == null ? 'ONLINE' : _clock(session.endedAt!)}',
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                if (session.files.isEmpty)
                  Text(
                    'NO FILES THIS SESSION',
                    style: AppTextStyles.codeSm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  )
                else
                  for (final file in session.files) _FileRow(file: file),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _shortId(String id) {
    final parts = id.split('-');
    return parts.length >= 2 ? parts.last : id;
  }

  String _clock(DateTime time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _duration(SessionRecord session) {
    final end = session.endedAt ?? session.startedAt;
    final d = end.difference(session.startedAt);
    if (d.inSeconds < 60) {
      return '${d.inSeconds}s';
    }
    if (d.inMinutes < 60) {
      return '${d.inMinutes}m ${d.inSeconds % 60}s';
    }
    return '${d.inHours}h ${d.inMinutes % 60}m';
  }
}

class _FileRow extends StatelessWidget {
  const _FileRow({required this.file});

  final HistoryFile file;

  @override
  Widget build(BuildContext context) {
    final (color, label) = switch (file.kind) {
      HistoryFileKind.received => (
        AppColors.tertiaryContainer,
        'RECEIVED',
      ),
      HistoryFileKind.published => (
        AppColors.primaryContainer,
        'PUBLISHED',
      ),
      HistoryFileKind.downloaded => (
        AppColors.secondaryContainer,
        'DOWNLOADED',
      ),
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          const Icon(
            Icons.insert_drive_file_outlined,
            size: 16,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.codeSm.copyWith(color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formatBytes(file.size),
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: AppTextStyles.labelCaps.copyWith(
              color: color,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
