import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/section_label.dart';

/// PROFILE tab placeholder.
///
/// Device identity (persisted node name/id) is already exposed via the P2P
/// node store; a richer profile surface is outside the current MVP scope.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
                      text: 'PROFILE',
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
                      Icons.person_outline,
                      size: 40,
                      color: AppColors.primaryContainer,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'NODE PROFILE PENDING',
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
                        'Device identity, storage usage and security keys '
                        'will be surfaced here.',
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
