import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../cubit/onboarding_cubit.dart';
import '../cubit/onboarding_state.dart';
import '../widgets/permission_card.dart';

/// Educational permission screen.
///
/// Explains *why* each mandatory permission is required and provides
/// "ENABLE ACCESS" / "RETRY ACCESS" / "OPEN SETTINGS" actions plus a
/// "CONTINUE ANYWAY" escape hatch. Onboarding is **non-blocking**: the user
/// is never stuck — missing permissions are re-requested at point of use
/// (FUNCTIONALITY.md §3).
class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stagger;

  @override
  void initState() {
    super.initState();
    _stagger = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..forward();
  }

  @override
  void dispose() {
    _stagger.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingCubit, OnboardingState>(
      listener: (context, state) {
        if (state.isInitialized &&
            !state.isRequesting &&
            state.shouldEnterHome) {
          context.go(AppConstants.homePath);
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: BlocBuilder<OnboardingCubit, OnboardingState>(
            buildWhen: (previous, current) =>
                previous.permissions != current.permissions ||
                previous.isRequesting != current.isRequesting ||
                previous.isInitialized != current.isInitialized ||
                previous.error != current.error,
            builder: (context, state) {
              if (!state.isInitialized) {
                return const Center(child: CircularProgressIndicator());
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _Header(),
                  Expanded(
                    child: _PermissionList(state: state, stagger: _stagger),
                  ),
                  _ActionBar(state: state),
                ],
              );
            },
          ),
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
        AppConstants.unit * 6,
        AppConstants.screenMargin,
        AppConstants.unit * 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionLabel(
            text: 'SYS.PERM // ACCESS GRANT CHECK',
            color: AppColors.primaryContainer,
          ),
          const SizedBox(height: 10),
          Text(
            'INITIALIZE NODE',
            style: AppTextStyles.headlineLg.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'BlazeDrop needs the following access to discover nearby devices '
            'and move files at maximum speed. Nothing ever leaves your local '
            'network.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionList extends StatelessWidget {
  const _PermissionList({required this.state, required this.stagger});

  final OnboardingState state;

  /// Master animation controller driving the staggered entrance.
  final Animation<double> stagger;

  @override
  Widget build(BuildContext context) {
    final items = state.permissions;
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenMargin,
        vertical: AppConstants.unit,
      ),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entrance = CurvedAnimation(
          parent: stagger,
          curve: Interval(index * 0.08, 1.0, curve: Curves.easeOutCubic),
        );
        return FadeTransition(
          opacity: entrance,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(entrance),
            child: PermissionCard(requirement: items[index]),
          ),
        );
      },
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state});

  final OnboardingState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    final pendingLabel = state.hasPendingPermission
        ? 'RETRY ACCESS'
        : 'ENABLE ACCESS';

    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenMargin,
        AppConstants.unit * 3,
        AppConstants.screenMargin,
        AppConstants.unit * 4,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(
          top: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (state.error != null) ...[
            _ErrorBanner(message: state.error!),
            const SizedBox(height: 12),
          ],
          if (state.hasPendingPermission && state.error == null) ...[
            _MissingNotice(),
            const SizedBox(height: 12),
          ],
          if (state.hasPermanentDenial) ...[
            BlazeButton(
              label: 'OPEN SETTINGS',
              variant: BlazeButtonVariant.cta,
              icon: Icons.settings_outlined,
              isLoading: state.isRequesting,
              onPressed: cubit.openSettings,
            ),
            const SizedBox(height: 10),
            BlazeButton(
              label: 'REQUEST AGAIN',
              variant: BlazeButtonVariant.ghost,
              isLoading: state.isRequesting,
              onPressed: state.isRequesting ? null : cubit.requestPermissions,
            ),
          ] else ...[
            BlazeButton(
              label: pendingLabel,
              variant: BlazeButtonVariant.cta,
              icon: Icons.shield_outlined,
              isLoading: state.isRequesting,
              enabled: !state.allMandatoryGranted,
              onPressed: state.isRequesting ? null : cubit.requestPermissions,
            ),
          ],
          if (state.hasPendingPermission) ...[
            const SizedBox(height: 10),
            BlazeButton(
              label: 'CONTINUE ANYWAY',
              variant: BlazeButtonVariant.outline,
              icon: Icons.arrow_forward_outlined,
              isLoading: state.isRequesting,
              onPressed: state.isRequesting ? null : cubit.finishOnboarding,
            ),
          ],
        ],
      ),
    );
  }
}

/// Tells the user the app is usable without every access and that missing
/// permissions will be re-requested when a feature needs them.
class _MissingNotice extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer.withValues(alpha: 0.08),
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'You can continue without granting every access. Missing '
              'permissions will be requested again when a feature needs them.',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.errorContainer,
        borderRadius: AppTheme.sharp,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.error_outline,
            size: 18,
            color: AppColors.onErrorContainer,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onErrorContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
