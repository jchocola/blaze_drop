import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/section_label.dart';

/// TRANSFER HISTORY tab placeholder.
///
/// Transfer-history persistence (sqflite) is outside the current MVP scope
/// (FUNCTIONALITY.md §2 / §12); this screen documents the future surface.
class HistoryPage extends StatelessWidget {
  const HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenMargin,
                AppConstants.unit * 3,
                AppConstants.screenMargin,
                AppConstants.unit * 2,
              ),
              child: Row(
                children: [
                  InkWell(
                    onTap: () => context.pop(),
                    child: const Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Icon(
                        Icons.arrow_back,
                        color: AppColors.primaryContainer,
                        size: 22,
                      ),
                    ),
                  ),
                  const Expanded(
                    child: SectionLabel(
                      text: 'HISTORY',
                      color: AppColors.primaryContainer,
                    ),
                  ),
                ],
              ),
            ),
            const Divider(thickness: 1, color: AppColors.outlineVariant),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.history_outlined,
                      size: 40,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NO TRANSFERS LOGGED',
                      style: AppTextStyles.headlineMd.copyWith(
                        color: AppColors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppConstants.unit * 8,
                      ),
                      child: Text(
                        'Completed P2P and Server transfers will be indexed '
                        'here with resume support.',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.bodySm.copyWith(
                          color: AppColors.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
