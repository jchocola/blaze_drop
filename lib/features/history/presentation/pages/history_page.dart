import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/history/session_record.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../cubit/history_cubit.dart';
import '../cubit/history_state.dart';
import '../widgets/session_tile.dart';

/// TRANSFER HISTORY tab (FUNCTIONALITY.md mock "HISTORY").
///
/// Shows the files from the most-recent server sessions (capped at
/// [AppConstants.maxHistorySessions]) with a retention notice and a
/// CLEAR HISTORY action.
class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  @override
  void initState() {
    super.initState();
    context.read<HistoryCubit>().initialize();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocBuilder<HistoryCubit, HistoryState>(
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const _Header(),
                const Divider(thickness: 1, color: AppColors.outlineVariant),
                const _RetentionNotice(),
                Expanded(
                  child: _buildBody(state),
                ),
                _ClearBar(
                  hasSessions: state.sessions.isNotEmpty,
                  isClearing: state.isClearing,
                  onClear: () => context.read<HistoryCubit>().clearHistory(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBody(HistoryState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.error != null) {
      return _MessageState(
        icon: Icons.error_outline,
        title: 'HISTORY UNAVAILABLE',
        message: state.error!,
      );
    }
    if (state.sessions.isEmpty) {
      return const _MessageState(
        icon: Icons.history_outlined,
        title: 'NO SESSIONS RECORDED',
        message: 'Start the server and share files — the most recent '
            'sessions will be archived here.',
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(AppConstants.screenMargin),
      itemCount: state.sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final SessionRecord session = state.sessions[index];
        return SessionTile(session: session);
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header();

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
          const SectionLabel(
            text: 'TRANSFER LOG // ARCHIVE',
            color: AppColors.primaryContainer,
          ),
          const SizedBox(height: 6),
          Text(
            'TRANSFER HISTORY',
            style: AppTextStyles.headlineLg.copyWith(
              color: AppColors.onSurface,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Files from the most recent server sessions.',
            style: AppTextStyles.bodyMd.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// Informs the user that only the last [AppConstants.maxHistorySessions]
/// sessions are retained.
class _RetentionNotice extends StatelessWidget {
  const _RetentionNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppConstants.screenMargin),
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.cardPadding,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      child: Row(
        children: [
          const Icon(
            Icons.hourglass_bottom,
            size: 18,
            color: AppColors.primaryContainer,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'STORING LAST ${AppConstants.maxHistorySessions} SESSIONS — '
              'older archives are auto-pruned.',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.primaryContainer,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: AppColors.primaryContainer),
            const SizedBox(height: 16),
            Text(
              title,
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
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.bodySm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClearBar extends StatelessWidget {
  const _ClearBar({
    required this.hasSessions,
    required this.isClearing,
    required this.onClear,
  });

  final bool hasSessions;
  final bool isClearing;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
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
      child: BlazeButton(
        label: isClearing ? 'CLEARING…' : 'CLEAR HISTORY',
        icon: Icons.delete_outline,
        variant: BlazeButtonVariant.ghost,
        isLoading: isClearing,
        enabled: hasSessions && !isClearing,
        onPressed: hasSessions && !isClearing ? onClear : null,
      ),
    );
  }
}
