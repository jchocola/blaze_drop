import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_logo.dart';
import '../../../../core/widgets/section_label.dart';

/// Mode-selection landing screen (FUNCTIONALITY.md §4/§5, mock "SELECT MODE").
///
/// Module A guarantees the node is initialized; this screen lets the user pick
/// between the two transfer modes. Module B (P2P) and Module C (Server) are
/// both wired. HOME and SETTINGS are tabs of the router shell
/// (`app_shell.dart`); this page is the HOME branch.
class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _Header(),
            const Divider(thickness: 1, color: AppColors.outlineVariant),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppConstants.screenMargin,
                AppConstants.unit * 3,
                AppConstants.screenMargin,
                AppConstants.unit,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionLabel(
                    text: 'SYS.INIT // PROTOCOL SELECTION',
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'SELECT MODE',
                    style: AppTextStyles.headlineLg.copyWith(
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.screenMargin,
                  vertical: AppConstants.unit * 2,
                ),
                children: const [
                  _ModeCard.p2p(),
                  SizedBox(height: 12),
                  _ModeCard.server(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenMargin,
        AppConstants.unit * 4,
        AppConstants.screenMargin,
        AppConstants.unit * 2,
      ),
      child: Row(
        children: [
          const BlazeLogo(size: 40),
          const SizedBox(width: 12),
          Text(
            'BLAZEDROP',
            style: AppTextStyles.headlineMd.copyWith(
              color: AppColors.primaryContainer,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.0,
            ),
          ),
          const Spacer(),
          const Icon(
            Icons.wifi_tethering_outlined,
            size: 20,
            color: AppColors.tertiaryContainer,
          ),
          const SizedBox(width: 8),
          const Icon(
            Icons.bolt_outlined,
            size: 20,
            color: AppColors.primaryContainer,
          ),
        ],
      ),
    );
  }
}

/// A selectable protocol mode card (P2P / Server).
class _ModeCard extends StatelessWidget {
  const _ModeCard.p2p()
    : title = 'P2P MODE',
      description =
          'Direct device-to-device encrypted tunnel. High speed, local range.',
      icon = Icons.sensors_outlined,
      accent = AppColors.primaryContainer,
      onTap = _ModeCard._goP2p,
      comingSoon = false;

  const _ModeCard.server()
    : title = 'SERVER MODE',
      description =
          'Establish local relay hub. Multi-device support via IP/QR.',
      icon = Icons.dns_outlined,
      accent = AppColors.secondaryContainer,
      onTap = _ModeCard._openServer,
      comingSoon = false;

  final String title;
  final String description;
  final IconData icon;
  final Color accent;
  final void Function(BuildContext) onTap;
  final bool comingSoon;

  static void _goP2p(BuildContext context) =>
      context.push(AppConstants.p2pPath);

  static void _openServer(BuildContext context) =>
      context.push(AppConstants.serverPath);

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surfaceContainer,
      child: InkWell(
        onTap: () => onTap(context),
        splashColor: accent.withValues(alpha: 0.10),
        child: Container(
          padding: const EdgeInsets.all(AppConstants.cardPadding),
          decoration: BoxDecoration(
            border: Border.all(
              color: comingSoon
                  ? AppColors.outlineVariant
                  : accent.withValues(alpha: 0.6),
              width: 1,
            ),
            borderRadius: AppTheme.sharp,
          ),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  border: Border.all(color: accent, width: 1),
                  borderRadius: AppTheme.sharp,
                ),
                child: Icon(icon, size: 26, color: accent),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: AppTextStyles.headlineMd.copyWith(
                              color: comingSoon
                                  ? AppColors.onSurfaceVariant
                                  : accent,
                            ),
                          ),
                        ),
                        if (comingSoon)
                          SectionLabel(
                            text: 'SOON',
                            color: AppColors.onSurfaceVariant,
                            showBar: false,
                          )
                        else
                          SectionLabel(
                            text: 'ENTER',
                            color: accent,
                            showBar: false,
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: AppTextStyles.bodySm.copyWith(
                        color: AppColors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
