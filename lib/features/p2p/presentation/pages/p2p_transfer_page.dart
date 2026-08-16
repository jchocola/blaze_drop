import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/peer_device.dart';
import '../../domain/entities/transfer_session.dart';
import '../cubit/p2p_cubit.dart';
import '../cubit/p2p_state.dart';
import '../widgets/file_type_ui.dart';
import '../widgets/gradient_progress_bar.dart';
import '../widgets/incoming_request_overlay.dart';
import '../widgets/peer_avatar.dart';
import '../widgets/speedometer_gauge.dart';

/// Nominal LAN throughput used to estimate transfer time before sending.
const double _nominalMbps = 40 * 1024 * 1024; // 40 MB/s

/// Target-acquisition + payload-staging screen (FUNCTIONALITY.md §4.3,
/// mock "TARGET ACQUIRED"). Drives file selection, the "BLAZE SEND" action
/// and the live progress gauge.
class P2pTransferPage extends StatelessWidget {
  const P2pTransferPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            BlocBuilder<P2pCubit, P2pState>(
              buildWhen: (previous, current) =>
                  previous.connectedPeer != current.connectedPeer ||
                  previous.selectedFiles != current.selectedFiles ||
                  previous.transfer != current.transfer ||
                  previous.isSending != current.isSending ||
                  previous.error != current.error,
              builder: (context, state) {
                final peer = state.connectedPeer;
                if (peer == null) {
                  return _NoTarget();
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(peer: peer),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppConstants.screenMargin,
                          vertical: AppConstants.unit,
                        ),
                        children: [
                          _TargetCard(peer: peer),
                          const SizedBox(height: 16),
                          _PayloadSection(state: state),
                        ],
                      ),
                    ),
                    _BottomBar(state: state),
                  ],
                );
              },
            ),
            const IncomingRequestOverlay(),
          ],
        ),
      ),
    );
  }
}

class _NoTarget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.my_location_outlined,
            size: 44,
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          const Text(
            'NO TARGET ACQUIRED',
            style: AppTextStyles.headlineMd,
          ),
          const SizedBox(height: 12),
          BlazeButton(
            label: 'BACK TO GRID',
            variant: BlazeButtonVariant.outline,
            compact: true,
            onPressed: () => context.pop(),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.peer});

  final PeerDevice peer;

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
                onTap: () {
                  context.read<P2pCubit>().clearTarget();
                  context.pop();
                },
                child: const Padding(
                  padding: EdgeInsets.only(right: 8),
                  child: Icon(
                    Icons.arrow_back,
                    color: AppColors.primaryContainer,
                    size: 22,
                  ),
                ),
              ),
              const SectionLabel(
                text: 'TARGET ACQUIRED',
                color: AppColors.primaryContainer,
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.tertiaryContainer,
                  borderRadius: AppTheme.sharp,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: const BoxDecoration(
                        color: AppColors.onTertiary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      'SECURE LINK',
                      style: AppTextStyles.labelCaps.copyWith(
                        fontSize: 9,
                        color: AppColors.onTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'TARGET ACQUIRED',
            style: AppTextStyles.headlineLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 4),
          Text(
            'Direct encrypted tunnel to ${peer.name}.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _TargetCard extends StatelessWidget {
  const _TargetCard({required this.peer});

  final PeerDevice peer;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      child: Row(
        children: [
          PeerAvatar(peer: peer),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  peer.name.toUpperCase(),
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.primaryContainer,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${peer.ipAddress} (Local)',
                  style: AppTextStyles.codeSm.copyWith(
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LINK ${peer.signalStrength}%',
                style: AppTextStyles.labelCaps.copyWith(
                  fontSize: 10,
                  color: AppColors.tertiaryContainer,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PayloadSection extends StatelessWidget {
  const _PayloadSection({required this.state});

  final P2pState state;

  @override
  Widget build(BuildContext context) {
    final files = state.selectedFiles;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: SectionLabel(
                text: 'PAYLOAD DATA',
                color: AppColors.primaryContainer,
              ),
            ),
            InkWell(
              onTap: state.isSending ? null : () => context.read<P2pCubit>().pickFiles(),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  border: Border.all(
                    color: AppColors.primaryContainer,
                    width: 1,
                  ),
                  borderRadius: AppTheme.sharp,
                ),
                child: const Icon(
                  Icons.add,
                  size: 18,
                  color: AppColors.primaryContainer,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          _DropZone()
        else
          ...files.map(
            (file) => _PayloadRow(
              file: file,
              onRemove: state.isSending
                  ? null
                  : () => context.read<P2pCubit>().removeFile(file),
            ),
          ),
      ],
    );
  }
}

class _DropZone extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.read<P2pCubit>().pickFiles(),
      child: Container(
        height: 110,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerLowest,
          border: Border.all(
            color: AppColors.primaryContainer.withValues(alpha: 0.6),
            width: 2,
          ),
          borderRadius: AppTheme.sharp,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.cloud_upload_outlined,
              size: 30,
              color: AppColors.primaryContainer,
            ),
            const SizedBox(height: 8),
            Text(
              'TAP OR DRAG FILES HERE',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Multiple files supported',
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayloadRow extends StatelessWidget {
  const _PayloadRow({required this.file, this.onRemove});

  final FileItem file;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      child: Row(
        children: [
          Icon(file.icon, size: 20, color: AppColors.primaryContainer),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              file.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.onSurface),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            file.sizeLabel,
            style: AppTextStyles.labelCaps.copyWith(
              fontSize: 10,
              color: AppColors.onSurfaceVariant,
            ),
          ),
          if (onRemove != null) ...[
            const SizedBox(width: 6),
            InkWell(
              onTap: onRemove,
              child: const Icon(
                Icons.close,
                size: 16,
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.state});

  final P2pState state;

  @override
  Widget build(BuildContext context) {
    final transfer = state.transfer;
    final sending = state.isSending;

    // Live progress view while an outgoing transfer is in flight.
    if (sending || (transfer?.direction == TransferDirection.outgoing &&
        transfer?.status == TransferStatus.transferring)) {
      return _TransferPanel(
        transfer: transfer ??
            TransferSession(
              sessionId: '',
              peer: state.connectedPeer!,
              direction: TransferDirection.outgoing,
              status: TransferStatus.transferring,
            ),
      );
    }

    // Completed outgoing transfer.
    if (transfer?.direction == TransferDirection.outgoing &&
        transfer?.status == TransferStatus.completed) {
      return _DonePanel(transfer: transfer!);
    }

    // Failed / declined.
    if (transfer?.status == TransferStatus.failed ||
        state.error != null) {
      return _ErrorPanel(
        message: state.error ??
            transfer?.error ??
            'Transfer failed',
        onRetry: state.selectedFiles.isEmpty ? null : () => context.read<P2pCubit>().sendFiles(),
      );
    }

    final total = state.payloadBytes;
    final estSeconds = total <= 0 ? 0 : (total / _nominalMbps).ceil();
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
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StatBlock(label: 'TOTAL SIZE', value: formatBytes(total)),
              const Spacer(),
              _StatBlock(
                label: 'EST. TIME',
                value: estSeconds <= 0 ? '—' : '< ${estSeconds + 1}s',
              ),
            ],
          ),
          const SizedBox(height: 12),
          BlazeButton(
            label: 'BLAZE SEND',
            variant: BlazeButtonVariant.cta,
            icon: Icons.bolt_outlined,
            enabled: state.selectedFiles.isNotEmpty,
            onPressed: state.selectedFiles.isEmpty
                ? null
                : () => context.read<P2pCubit>().sendFiles(),
          ),
        ],
      ),
    );
  }
}

class _StatBlock extends StatelessWidget {
  const _StatBlock({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelCaps.copyWith(
            fontSize: 10,
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTextStyles.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}

class _TransferPanel extends StatelessWidget {
  const _TransferPanel({required this.transfer});

  final TransferSession transfer;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SpeedometerGauge(progress: transfer.progress, size: 180),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatBlock(
                  label: 'UPLOAD SPEED',
                  value: transfer.speedBytesPerSecond > 0
                      ? transfer.speedLabel
                      : 'CONNECTING…',
                ),
              ),
              Expanded(
                child: _StatBlock(
                  label: 'REMAINING TIME',
                  value: transfer.estimatedSecondsRemaining > 0
                      ? '${transfer.estimatedSecondsRemaining}s'
                      : '…',
                ),
              ),
              Expanded(
                child: _StatBlock(
                  label: 'TRANSFERRED',
                  value:
                      '${formatBytes(transfer.bytesTransferred)} / ${formatBytes(transfer.bytesTotal)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          GradientProgressBar(progress: transfer.progress, height: 10),
        ],
      ),
    );
  }
}

class _DonePanel extends StatelessWidget {
  const _DonePanel({required this.transfer});

  final TransferSession transfer;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(
                Icons.check_circle_outline,
                size: 26,
                color: AppColors.tertiaryContainer,
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PAYLOAD DELIVERED',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.tertiaryContainer,
                    ),
                  ),
                  Text(
                    '${transfer.files.length} file(s) • ${formatBytes(transfer.bytesTransferred)}',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              BlazeButton(
                label: 'BACK TO GRID',
                variant: BlazeButtonVariant.outline,
                compact: true,
                onPressed: () {
                  context.read<P2pCubit>().clearTarget();
                  context.pop();
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorPanel extends StatelessWidget {
  const _ErrorPanel({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
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
          ),
          const SizedBox(height: 12),
          BlazeButton(
            label: 'RETRY SEND',
            variant: BlazeButtonVariant.cta,
            icon: Icons.refresh,
            enabled: onRetry != null,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
