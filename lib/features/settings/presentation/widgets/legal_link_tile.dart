import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme/theme.dart';

/// A tappable legal link row (e.g. Privacy Policy / Terms of Service).
///
/// Opens [url] in an external browser via `url_launcher`. If [url] is empty
/// (placeholder not configured yet), tapping surfaces a snackbar instead of
/// attempting to launch an invalid URI.
class LegalLinkTile extends StatelessWidget {
  const LegalLinkTile({
    super.key,
    required this.title,
    required this.description,
    required this.url,
    this.icon,
  });

  final String title;
  final String description;
  final String url;
  final IconData? icon;

  Future<void> _open(BuildContext context) async {
    if (url.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('LINK NOT CONFIGURED // URL PENDING')),
        );
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('LAUNCH FAILED // CHECK LINK')),
          );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => _open(context),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(
            bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
          ),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, size: 20, color: AppColors.primaryContainer),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.bodyMd.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.open_in_new,
              size: 18,
              color: url.isEmpty
                  ? AppColors.onSurfaceVariant
                  : AppColors.primaryContainer,
            ),
          ],
        ),
      ),
    );
  }
}
