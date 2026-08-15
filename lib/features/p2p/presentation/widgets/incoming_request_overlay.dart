import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/file_item.dart';
import '../../domain/entities/incoming_connection_request.dart';
import '../cubit/p2p_cubit.dart';
import '../cubit/p2p_state.dart';
import '../widgets/file_type_ui.dart';
import '../widgets/peer_avatar.dart';

/// Full-screen overlay for an incoming connection request
/// (FUNCTIONALITY.md §4.2, mock "INCOMING CONNECTION REQUEST").
///
/// Renders nothing when there is no pending request. Auto-declines after the
/// request's timeout via a per-request countdown timer.
class IncomingRequestOverlay extends StatelessWidget {
  const IncomingRequestOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<P2pCubit, P2pState>(
      buildWhen: (previous, current) =>
          previous.pendingRequest != current.pendingRequest,
      builder: (context, state) {
        final request = state.pendingRequest;
        if (request == null) {
          return const SizedBox.shrink();
        }
        return _RequestModal(key: ValueKey(request.requestId), request: request);
      },
    );
  }
}

class _RequestModal extends StatefulWidget {
  const _RequestModal({super.key, required this.request});

  final IncomingConnectionRequest request;

  @override
  State<_RequestModal> createState() => _RequestModalState();
}

class _RequestModalState extends State<_RequestModal> {
  Timer? _ticker;
  late int _secondsLeft;

  @override
  void initState() {
    super.initState();
    _secondsLeft = widget.request.remainingSeconds;
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) {
        return;
      }
      final left = widget.request.remainingSeconds;
      setState(() => _secondsLeft = left);
      if (left <= 0) {
        _ticker?.cancel();
        context.read<P2pCubit>().declineRequest();
      }
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final request = widget.request;
    return Positioned.fill(
      child: Material(
        color: AppColors.surfaceContainerLowest.withValues(alpha: 0.88),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppConstants.gutter),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 440),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainer,
                  border: Border.all(
                    color: AppColors.primaryContainer,
                    width: 2,
                  ),
                  borderRadius: AppTheme.sharp,
                ),
                padding: const EdgeInsets.all(AppConstants.cardPadding),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Header(request: request, secondsLeft: _secondsLeft),
                    const SizedBox(height: 16),
                    _SenderIdentity(request: request),
                    const SizedBox(height: 16),
                    _Manifest(files: request.files),
                    const Divider(
                      color: AppColors.outlineVariant,
                      thickness: 1,
                    ),
                    _TotalRow(request: request),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: BlazeButton(
                            label: 'DECLINE',
                            variant: BlazeButtonVariant.ghost,
                            compact: true,
                            onPressed: () =>
                                context.read<P2pCubit>().declineRequest(),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: BlazeButton(
                            label: 'ACCEPT',
                            variant: BlazeButtonVariant.primary,
                            compact: true,
                            onPressed: () =>
                                context.read<P2pCubit>().acceptRequest(),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.request, required this.secondsLeft});

  final IncomingConnectionRequest request;
  final int secondsLeft;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(
          Icons.sensor_door_outlined,
          size: 22,
          color: AppColors.secondaryContainer,
        ),
        const SizedBox(width: 8),
        const Expanded(
          child: SectionLabel(
            text: 'INCOMING CONNECTION REQUEST',
            color: AppColors.secondaryContainer,
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            border: Border.all(color: AppColors.outlineVariant, width: 1),
          ),
          child: Text(
            '${secondsLeft}s',
            style: AppTextStyles.labelCaps.copyWith(
              color: secondsLeft <= 5
                  ? AppColors.secondaryContainer
                  : AppColors.onSurfaceVariant,
            ),
          ),
        ),
      ],
    );
  }
}

class _SenderIdentity extends StatelessWidget {
  const _SenderIdentity({required this.request});

  final IncomingConnectionRequest request;

  @override
  Widget build(BuildContext context) {
    final sender = request.sender;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.outlineVariant, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      child: Row(
        children: [
          PeerAvatar(peer: sender),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SENDER IDENTITY',
                  style: AppTextStyles.labelCaps.copyWith(
                    fontSize: 10,
                    color: AppColors.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sender.name.toUpperCase(),
                  style: AppTextStyles.headlineMd.copyWith(
                    color: AppColors.primaryContainer,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'LINK',
                style: AppTextStyles.labelCaps.copyWith(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${sender.signalStrength}%',
                style: AppTextStyles.labelCaps.copyWith(
                  color: AppColors.tertiaryContainer,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                sender.ipAddress,
                style: AppTextStyles.codeSm.copyWith(
                  fontSize: 10,
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Manifest extends StatelessWidget {
  const _Manifest({required this.files});

  final List<FileItem> files;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionLabel(
          text: 'PAYLOAD MANIFEST (${files.length} ITEM${files.length == 1 ? '' : 'S'})',
          color: AppColors.primaryContainer,
        ),
        const SizedBox(height: 8),
        if (files.isEmpty)
          Text(
            'No file metadata shared by sender.',
            style: AppTextStyles.bodySm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          )
        else
          ...files.map(
            (file) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Icon(file.icon, size: 16, color: AppColors.primaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.codeSm.copyWith(
                        color: AppColors.onSurface,
                      ),
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
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.request});

  final IncomingConnectionRequest request;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          'TOTAL SIZE',
          style: AppTextStyles.labelCaps.copyWith(
            color: AppColors.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          formatBytes(request.totalBytes),
          style: AppTextStyles.headlineMd.copyWith(
            color: AppColors.onSurface,
          ),
        ),
      ],
    );
  }
}
