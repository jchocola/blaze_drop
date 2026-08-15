import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';
import '../widgets/config_toggle_tile.dart';

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
                      _ProtocolSection(state: state),
                      const SizedBox(height: 16),
                      _SecuritySection(state: state),
                      const SizedBox(height: 16),
                      _InterfaceSection(state: state),
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
        ConfigToggleTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          description: 'Enforced by system protocol.',
          value: config.darkMode,
          enabled: false,
          onChanged: (_) {},
        ),
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
