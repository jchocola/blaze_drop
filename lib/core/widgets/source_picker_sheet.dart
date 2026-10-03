import 'package:flutter/material.dart';

import '../constants/constants.dart';
import '../theme/theme.dart';
import 'section_label.dart';

/// Where staged payload comes from — the options offered by
/// [showSourcePickerSheet] (FUNCTIONALITY.md §4.3 / §5.4).
enum FilePickSource {
  /// Device file system (`file_picker`).
  files,

  /// System photo library (`image_picker` multipick).
  gallery,

  /// System camera, single shot (`image_picker` capture).
  camera,
}

/// Presents the "choose a source" action sheet and resolves to the tapped
/// option, or `null` when the sheet is dismissed without a choice.
Future<FilePickSource?> showSourcePickerSheet(
  BuildContext context, {
  required String title,
}) {
  return showModalBottomSheet<FilePickSource>(
    context: context,
    backgroundColor: AppColors.surfaceContainer,
    shape: const RoundedRectangleBorder(borderRadius: AppTheme.sharp),
    builder: (_) => _SourcePickerSheet(title: title),
  );
}

/// Sharp-cornered sheet listing the three staging sources.
class _SourcePickerSheet extends StatelessWidget {
  const _SourcePickerSheet({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.cardPadding,
              vertical: 10,
            ),
            color: AppColors.surfaceContainerHigh,
            child: SectionLabel(
              text: title,
              color: AppColors.primaryContainer,
            ),
          ),
          _SourceTile(
            icon: Icons.folder_open,
            label: 'FILES',
            hint: 'Browse device storage',
            source: FilePickSource.files,
          ),
          _SourceTile(
            icon: Icons.photo_library_outlined,
            label: 'GALLERY',
            hint: 'Pick photos from the library',
            source: FilePickSource.gallery,
          ),
          _SourceTile(
            icon: Icons.photo_camera_outlined,
            label: 'CAMERA',
            hint: 'Capture a new photo',
            source: FilePickSource.camera,
          ),
          SizedBox(height: AppConstants.unit * 2),
        ],
      ),
    );
  }
}

/// A single tappable source row; pops the sheet with its [source].
class _SourceTile extends StatelessWidget {
  const _SourceTile({
    required this.icon,
    required this.label,
    required this.hint,
    required this.source,
  });

  final IconData icon;
  final String label;
  final String hint;
  final FilePickSource source;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => Navigator.of(context).pop(source),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppConstants.screenMargin,
          vertical: 14,
        ),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: AppColors.primaryContainer),
            SizedBox(width: AppConstants.cardPadding),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  SizedBox(height: AppConstants.unit / 2),
                  Text(
                    hint,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 18,
              color: AppColors.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}
