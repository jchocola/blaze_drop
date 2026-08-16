import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/peer_device.dart';
import '../cubit/p2p_cubit.dart';
import '../cubit/p2p_state.dart';
import '../widgets/device_card.dart';
import '../widgets/incoming_request_overlay.dart';
import '../widgets/radar_scan.dart';

/// P2P device-discovery grid (FUNCTIONALITY.md §4.1, mock "LOCAL NETWORK GRID").
///
/// Shows the radar while scanning, the live peer list (auto-refreshed every
/// 5s, stale peers pruned after 10s) and reacts to incoming connection
/// requests via [IncomingRequestOverlay].
class P2pDiscoveryPage extends StatefulWidget {
  const P2pDiscoveryPage({super.key});

  @override
  State<P2pDiscoveryPage> createState() => _P2pDiscoveryPageState();
}

class _P2pDiscoveryPageState extends State<P2pDiscoveryPage> {
  late final P2pCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<P2pCubit>();
    _cubit.initialize();
  }

  @override
  void dispose() {
    // Discovery runs only while this grid screen is visible. The cubit
    // reference is captured in initState — never touch `context` in dispose.
    _cubit.stopScan();
    super.dispose();
  }

  void _openTransfer(PeerDevice peer) {
    context.read<P2pCubit>().selectTarget(peer);
    context.push(AppConstants.p2pTransferPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(),
                Expanded(
                  child: BlocBuilder<P2pCubit, P2pState>(
                    buildWhen: (previous, current) =>
                        previous.scanStatus != current.scanStatus ||
                        previous.peers != current.peers ||
                        previous.error != current.error,
                    builder: (context, state) {
                      if (state.scanStatus == P2pScanStatus.idle &&
                          state.peers.isEmpty) {
                        return _ScanPrompt(
                          nodeName: state.nodeName,
                          onScan: () => context
                              .read<P2pCubit>()
                              .startScan(),
                        );
                      }
                      return _PeerList(
                        state: state,
                        onTap: _openTransfer,
                      );
                    },
                  ),
                ),
                _ScanBar(),
              ],
            ),
            const IncomingRequestOverlay(),
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
              const Expanded(child: SectionLabel(
                text: 'LOCAL NETWORK GRID',
                color: AppColors.primaryContainer,
              )),
              BlocBuilder<P2pCubit, P2pState>(
                buildWhen: (p, c) => p.scanStatus != c.scanStatus,
                builder: (context, state) {
                  final active = state.scanStatus == P2pScanStatus.active;
                  return SectionLabel(
                    text: active ? 'SCANNING' : 'STANDBY',
                    color: active
                        ? AppColors.tertiaryContainer
                        : AppColors.onSurfaceVariant,
                    showBar: false,
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'LOCAL NETWORK GRID',
            style: AppTextStyles.headlineLg.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 6),
          Text(
            '> Analyzing P2P spectrum…',
            style: AppTextStyles.codeSm.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _ScanPrompt extends StatelessWidget {
  const _ScanPrompt({required this.nodeName, required this.onScan});

  final String nodeName;
  final VoidCallback onScan;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          RadarScan(size: 160),
          const SizedBox(height: 24),
          SectionLabel(
            text: 'NODE // ${nodeName.isEmpty ? 'INITIALIZING' : nodeName}',
            color: AppColors.onSurfaceVariant,
          ),
          const SizedBox(height: 8),
          Text(
            'NO NODES DETECTED',
            style: AppTextStyles.headlineMd.copyWith(color: AppColors.onSurface),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppConstants.unit * 10),
            child: Text(
              'Hold both devices on the same Wi-Fi network, then rescan to '
              'discover nearby nodes.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySm.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: 200,
            child: BlazeButton(
              label: 'INITIATE SCAN',
              icon: Icons.radar_outlined,
              variant: BlazeButtonVariant.primary,
              onPressed: onScan,
            ),
          ),
        ],
      ),
    );
  }
}

class _PeerList extends StatelessWidget {
  const _PeerList({required this.state, required this.onTap});

  final P2pState state;
  final void Function(PeerDevice peer) onTap;

  @override
  Widget build(BuildContext context) {
    if (state.error != null) {
      return _ErrorState(message: state.error!);
    }
    if (state.peers.isEmpty) {
      if (state.scanStatus == P2pScanStatus.scanning) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            RadarScan(size: 150),
            const SizedBox(height: 20),
            Text(
              'ANALYZING P2P SPECTRUM…',
              style: AppTextStyles.labelCaps.copyWith(
                color: AppColors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.screenMargin,
        vertical: AppConstants.unit,
      ),
      itemCount: state.peers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final peer = state.peers[index];
        return DeviceCard(
          peer: peer,
          onTap: () => onTap(peer),
          trailing: const Icon(
            Icons.chevron_right,
            size: 20,
            color: AppColors.primaryContainer,
          ),
        );
      },
    );
  }
}

class _ScanBar extends StatelessWidget {
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
      child: BlocBuilder<P2pCubit, P2pState>(
        buildWhen: (p, c) => p.scanStatus != c.scanStatus,
        builder: (context, state) {
          final scanning = state.scanStatus != P2pScanStatus.idle;
          return BlazeButton(
            label: scanning ? 'RESCAN' : 'INITIATE SCAN',
            icon: Icons.radar_outlined,
            variant: BlazeButtonVariant.outline,
            onPressed: () => context.read<P2pCubit>().startScan(),
          );
        },
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.gutter),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_off_outlined,
              size: 40,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              message.toUpperCase(),
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMd.copyWith(color: AppColors.error),
            ),
          ],
        ),
      ),
    );
  }
}
