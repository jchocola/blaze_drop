import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../../../onboarding/domain/entities/permission_requirement.dart';
import '../../../onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../../onboarding/presentation/cubit/onboarding_state.dart';
import '../../domain/entities/app_version.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/config_toggle_tile.dart';
import '../widgets/legal_link_tile.dart';

/// "SYSTEM CONFIG" screen (FUNCTIONALITY.md mock): manages connection
/// protocols, the security matrix and interface preferences.
class SystemConfigPage extends StatefulWidget {
  const SystemConfigPage({super.key});

  @override
  State<SystemConfigPage> createState() => _SystemConfigPageState();
}

class _SystemConfigPageState extends State<SystemConfigPage> {
  @override
  void initState() {
    super.initState();
    context.read<SettingsCubit>().load();
    // Keep the permissions panel in sync with the OS on every visit.
    context.read<OnboardingCubit>().refreshPermissions();
  }

  void _onSaved(BuildContext context, SettingsState state) {
    if (!state.saved) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('CONFIG COMMITTED // SECURE')),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<SettingsCubit, SettingsState>(
          listener: _onSaved,
          builder: (context, state) {
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(saved: state.saved),
                const Divider(thickness: 1, color: AppColors.outlineVariant),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(AppConstants.screenMargin),
                    children: [
                      const _PermissionsSection(),
                      const SizedBox(height: 16),
                      _ProtocolSection(state: state),
                      const SizedBox(height: 16),
                      _SecuritySection(state: state),
                      const SizedBox(height: 16),
                      _InterfaceSection(state: state),
                      const SizedBox(height: 16),
                      const _LegalSection(),
                      const SizedBox(height: 16),
                      _VersionSection(version: state.version),
                    ],
                  ),
                ),
                _ActionBar(state: state),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.saved});

  final bool saved;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenMargin,
        AppConstants.unit * 3,
        AppConstants.screenMargin,
        AppConstants.unit * 2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: SectionLabel(
                  text: 'SYS.CFG',
                  color: AppColors.primaryContainer,
                ),
              ),
              SectionLabel(
                text: saved ? 'COMMITTED' : 'UNSAVED',
                color: saved
                    ? AppColors.tertiaryContainer
                    : AppColors.onSurfaceVariant,
                showBar: false,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'SYSTEM CONFIG',
            style: AppTextStyles.headlineLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            'Manage security and connection protocols.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConfigSection extends StatelessWidget {
  const _ConfigSection({required this.title, required this.children});

  final String title;
  final List<Widget> children;

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
            child: SectionLabel(
              text: title,
              color: AppColors.primaryContainer,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.cardPadding,
            ),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }
}

/// Live runtime-permission overview (Module A). Reads the app-scoped
/// [OnboardingCubit] so the panel shares the exact same permission state as
/// onboarding and shows at a glance what is granted and what is missing, with
/// quick actions to request missing access or open OS settings.
class _PermissionsSection extends StatelessWidget {
  const _PermissionsSection();

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<OnboardingCubit>();
    return BlocBuilder<OnboardingCubit, OnboardingState>(
      buildWhen: (previous, current) =>
          previous.permissions != current.permissions ||
          previous.isRequesting != current.isRequesting,
      builder: (context, state) {
        final permissions = state.permissions;
        final granted = permissions.where((p) => p.isGranted).length;
        return _ConfigSection(
          title: 'ACCESS PERMISSIONS',
          children: [
            _PermissionSummary(
              granted: granted,
              total: permissions.length,
              allGranted: permissions.isNotEmpty && state.allMandatoryGranted,
            ),
            if (permissions.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  'No permission data yet — press REFRESH STATUS.',
                  style: AppTextStyles.bodySm,
                ),
              )
            else
              for (final requirement in permissions)
                _PermissionTile(requirement: requirement),
            if (state.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  state.error!,
                  style: AppTextStyles.bodySm.copyWith(
                    color: AppColors.error,
                  ),
                ),
              ),
            if (state.hasPendingPermission) ...[
              const SizedBox(height: 10),
              BlazeButton(
                label: state.isRequesting
                    ? 'REQUESTING…'
                    : 'REQUEST ACCESS',
                variant: BlazeButtonVariant.cta,
                icon: Icons.shield_outlined,
                isLoading: state.isRequesting,
                onPressed: state.isRequesting
                    ? null
                    : cubit.requestPermissions,
              ),
            ],
            if (state.hasPermanentDenial) ...[
              const SizedBox(height: 10),
              BlazeButton(
                label: 'OPEN SETTINGS',
                variant: BlazeButtonVariant.ghost,
                icon: Icons.settings_outlined,
                onPressed: cubit.openSettings,
              ),
            ],
            const SizedBox(height: 10),
            BlazeButton(
              label: 'REFRESH STATUS',
              variant: BlazeButtonVariant.ghost,
              icon: Icons.refresh_outlined,
              isLoading: state.isRequesting,
              onPressed: state.isRequesting
                  ? null
                  : cubit.refreshPermissions,
            ),
          ],
        );
      },
    );
  }
}

/// Compact "granted / total" summary with an overall status pill.
class _PermissionSummary extends StatelessWidget {
  const _PermissionSummary({
    required this.granted,
    required this.total,
    required this.allGranted,
  });

  final int granted;
  final int total;
  final bool allGranted;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = allGranted
        ? (
            'ALL ACCESS GRANTED',
            AppColors.tertiaryContainer,
            AppColors.onTertiary,
          )
        : total == 0
        ? (
            'UNKNOWN',
            AppColors.surfaceContainerHighest,
            AppColors.onSurfaceVariant,
          )
        : (
            'SOME ACCESS MISSING',
            AppColors.errorContainer,
            AppColors.onErrorContainer,
          );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          bottom: BorderSide(color: AppColors.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                Text(
                  '$granted / $total',
                  style: AppTextStyles.headlineLg.copyWith(
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  'GRANTED',
                  style: AppTextStyles.labelCaps.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: background,
              borderRadius: AppTheme.sharp,
            ),
            child: Text(
              label,
              style: AppTextStyles.labelCaps.copyWith(
                fontSize: 10,
                letterSpacing: 1.0,
                color: foreground,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A single permission row: icon, title and a status tag.
class _PermissionTile extends StatelessWidget {
  const _PermissionTile({required this.requirement});

  final PermissionRequirement requirement;

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
          Icon(
            _iconFor(requirement.category),
            size: 20,
            color: _accentForStatus(requirement.status),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              requirement.title.toUpperCase(),
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.onSurface,
              ),
            ),
          ),
          _PermissionStatusTag(status: requirement.status),
        ],
      ),
    );
  }

  IconData _iconFor(PermissionCategory category) {
    return switch (category) {
      PermissionCategory.location => Icons.location_on_outlined,
      PermissionCategory.nearbyWifi => Icons.wifi_tethering_outlined,
      PermissionCategory.notifications => Icons.notifications_none,
      PermissionCategory.storage => Icons.photo_library_outlined,
      PermissionCategory.localNetwork => Icons.lan_outlined,
    };
  }

  Color _accentForStatus(PermissionStatusType status) {
    return switch (status) {
      PermissionStatusType.granted ||
      PermissionStatusType.limited => AppColors.tertiaryContainer,
      PermissionStatusType.permanentlyDenied ||
      PermissionStatusType.restricted => AppColors.secondaryContainer,
      PermissionStatusType.denied => AppColors.error,
      PermissionStatusType.unknown => AppColors.onSurfaceVariant,
    };
  }
}

class _PermissionStatusTag extends StatelessWidget {
  const _PermissionStatusTag({required this.status});

  final PermissionStatusType status;

  @override
  Widget build(BuildContext context) {
    final (label, background, foreground) = switch (status) {
      PermissionStatusType.granted || PermissionStatusType.limited => (
        status == PermissionStatusType.limited ? 'LIMITED' : 'GRANTED',
        AppColors.tertiaryContainer,
        AppColors.onTertiary,
      ),
      PermissionStatusType.permanentlyDenied => (
        'BLOCKED',
        AppColors.secondaryContainer,
        AppColors.onSecondary,
      ),
      PermissionStatusType.restricted => (
        'RESTRICTED',
        AppColors.secondaryContainer,
        AppColors.onSecondary,
      ),
      PermissionStatusType.denied => (
        'DENIED',
        AppColors.errorContainer,
        AppColors.onErrorContainer,
      ),
      PermissionStatusType.unknown => (
        'PENDING',
        AppColors.surfaceContainerHighest,
        AppColors.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: AppTheme.sharp,
      ),
      child: Text(
        label,
        style: AppTextStyles.labelCaps.copyWith(
          fontSize: 10,
          letterSpacing: 1.0,
          color: foreground,
        ),
      ),
    );
  }
}

class _ProtocolSection extends StatelessWidget {
  const _ProtocolSection({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final config = state.config;
    return _ConfigSection(
      title: 'CONNECTION PROTOCOLS',
      children: [
        ConfigToggleTile(
          icon: Icons.bolt_outlined,
          title: 'Auto-Accept Incoming',
          description: 'Automatically receive files from known nodes.',
          value: config.autoAcceptIncoming,
          onChanged: (v) => cubit.update(autoAcceptIncoming: v),
        ),
        ConfigToggleTile(
          icon: Icons.radar_outlined,
          title: 'Network Discovery',
          description: 'Allow nearby devices to find your node.',
          value: config.networkDiscovery,
          onChanged: (v) => cubit.update(networkDiscovery: v),
        ),
      ],
    );
  }
}

class _SecuritySection extends StatelessWidget {
  const _SecuritySection({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final config = state.config;
    return _ConfigSection(
      title: 'SECURITY MATRIX',
      children: [
        ConfigToggleTile(
          icon: Icons.lock_outlined,
          title: 'E2E Encryption',
          description: 'Force AES-256 encryption on all transfers.',
          value: config.e2eEncryption,
          onChanged: (v) => cubit.update(e2eEncryption: v),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Session Timeout',
                style: AppTextStyles.bodyMd.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Inactivity before forced disconnect.',
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: Slider(
                      value: config.sessionTimeoutMinutes.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      activeColor: AppColors.secondaryContainer,
                      inactiveColor: AppColors.surfaceContainerHighest,
                      label: '${config.sessionTimeoutMinutes}',
                      onChanged: (v) =>
                          cubit.update(sessionTimeoutMinutes: v.round()),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${config.sessionTimeoutMinutes}',
                    style: AppTextStyles.codeSm.copyWith(
                      color: AppColors.secondaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    ' MIN',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InterfaceSection extends StatelessWidget {
  const _InterfaceSection({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    final config = state.config;
    return _ConfigSection(
      title: 'INTERFACE',
      children: [
        // ConfigToggleTile(
        //   icon: Icons.dark_mode_outlined,
        //   title: 'Dark Mode',
        //   description: 'Enforced by system protocol.',
        //   value: config.darkMode,
        //   enabled: false,
        //   onChanged: (_) {},
        // ),
        ConfigToggleTile(
          icon: Icons.terminal_outlined,
          title: 'Show HUD Logs',
          description: 'Display the live transfer log on server screens.',
          value: config.showHudLogs,
          onChanged: (v) => cubit.update(showHudLogs: v),
        ),
      ],
    );
  }
}

/// External legal links (Privacy Policy / Terms of Service) opened in the
/// system browser via `url_launcher` (URLs from [AppConstants]).
class _LegalSection extends StatelessWidget {
  const _LegalSection();

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'LEGAL & COMPLIANCE',
      children: [
        LegalLinkTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          description: 'How your data is collected and handled.',
          url: AppConstants.privacyPolicyUrl,
        ),
        LegalLinkTile(
          icon: Icons.description_outlined,
          title: 'Terms of Service',
          description: 'Agreement governing app usage.',
          url: AppConstants.termsOfServiceUrl,
        ),
      ],
    );
  }
}

/// Read-only build metadata (version, build number, package id) sourced from
/// `package_info_plus` via [SettingsCubit].
class _VersionSection extends StatelessWidget {
  const _VersionSection({required this.version});

  final AppVersion version;

  @override
  Widget build(BuildContext context) {
    return _ConfigSection(
      title: 'BUILD INFO',
      children: [
        _InfoRow(label: 'VERSION', value: version.version),
        _InfoRow(label: 'BUILD', value: version.buildNumber),
        if (version.appName != null && version.appName!.isNotEmpty)
          _InfoRow(label: 'APP', value: version.appName!),
       // _InfoRow(label: 'PACKAGE', value: version.packageName),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          SectionLabel(
            text: label,
            color: AppColors.onSurfaceVariant,
          ),
          //const Spacer(),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: AppTextStyles.codeSm.copyWith(
                color: AppColors.primaryContainer,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.state});

  final SettingsState state;

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<SettingsCubit>();
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppConstants.screenMargin,
        AppConstants.unit * 2,
        AppConstants.screenMargin,
        AppConstants.unit * 3,
      ),
      decoration: const BoxDecoration(
        color: AppColors.surfaceContainerLowest,
        border: Border(top: BorderSide(color: AppColors.outlineVariant, width: 1)),
      ),
      child: Column(
        children: [
          BlazeButton(
            label: 'SAVE CONFIG',
            icon: Icons.lock_outline,
            variant: BlazeButtonVariant.cta,
            isLoading: state.isSaving,
            onPressed: state.isSaving ? null : cubit.save,
          ),
          const SizedBox(height: 10),
          BlazeButton(
            label: 'RESET CONFIG',
            icon: Icons.restart_alt,
            variant: BlazeButtonVariant.ghost,
            enabled: !state.isSaving,
            onPressed: state.isSaving ? null : cubit.reset,
          ),
        ],
      ),
    );
  }
}
