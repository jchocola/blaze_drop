import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/theme/theme.dart';
import '../../../../core/widgets/blaze_button.dart';
import '../../../../core/widgets/section_label.dart';
import '../../domain/entities/connected_client.dart';
import '../../domain/entities/downloaded_file.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/server_shared_file.dart';
import '../../domain/entities/server_upload_event.dart';
import '../cubit/server_cubit.dart';
import '../cubit/server_state.dart';
import '../widgets/connection_tile.dart';
import '../widgets/qr_beacon.dart';
import '../widgets/storage_tile.dart';
import '../widgets/upload_log_tile.dart';

/// Server Mode host screen (FUNCTIONALITY.md §5, mock "SERVER ACTIVE"):
///
/// activates the relay hub on entry, then shows the broadcast beacon (QR +
/// direct-connect IP), the live connected-client list, the incoming-upload
/// HUD and the shareable-file list, with a prominent STOP SERVER control.
class ServerPage extends StatefulWidget {
  const ServerPage({super.key});

  @override
  State<ServerPage> createState() => _ServerPageState();
}

class _ServerPageState extends State<ServerPage> {
  String? _lastNotifiedUpload;

  @override
  void initState() {
    super.initState();
    final cubit = context.read<ServerCubit>();
    cubit.initialize();
    cubit.startServer();
  }

  void _onStateChanged(BuildContext context, ServerState state) {
    if (state.error != null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(state.error!)));
    }
    final latest = state.uploads.isNotEmpty ? state.uploads.first : null;
    if (latest != null &&
        latest.status == ServerUploadStatus.completed &&
        latest.fileName != _lastNotifiedUpload) {
      _lastNotifiedUpload = latest.fileName;
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('▲ RECEIVED // ${latest.fileName}')),
        );
    }
  }

  void _copyDirectConnect(BuildContext context, ServerSession session) {
    final value = session.directConnect;
    if (value.isEmpty) {
      return;
    }
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(content: Text('DIRECT CONNECT IP COPIED')),
      );
  }

  void _stopServer(BuildContext context) {
    context.read<ServerCubit>().stopServer();
    if (context.canPop()) {
      context.pop();
    }
  }

  void _publishFiles(BuildContext context) {
    context.read<ServerCubit>().pickAndPublishFiles();
  }

  Future<void> _downloadFile(ServerSharedFile file) async {
    final downloaded = await context
        .read<ServerCubit>()
        .downloadSharedFile(file.id);
    if (!mounted || downloaded == null) {
      return;
    }
    final label = downloaded.target == DownloadTarget.gallery
        ? '▼ SAVED TO GALLERY // ${downloaded.name}'
        : '▼ SAVED // ${downloaded.name}';
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(label)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<ServerCubit, ServerState>(
          listener: _onStateChanged,
          builder: (context, state) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Header(state: state),
                const Divider(thickness: 1, color: AppColors.outlineVariant),
                Expanded(
                  child: state.isActive
                      ? _HubBody(
                          state: state,
                          onCopy: (session) =>
                              _copyDirectConnect(context, session),
                          onPublish: () => _publishFiles(context),
                          onDownload: _downloadFile,
                        )
                      : const _StartingView(),
                ),
                _StopBar(
                  isActive: state.isActive,
                  isRefreshing: state.isRefreshing,
                  onStop: () => _stopServer(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.state});

  final ServerState state;

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
                  text: 'SERVER MODE',
                  color: AppColors.primaryContainer,
                ),
              ),
              const Icon(
                Icons.wifi_tethering_outlined,
                size: 18,
                color: AppColors.tertiaryContainer,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'RELAY HUB',
                style: AppTextStyles.headlineLg.copyWith(
                  color: AppColors.onSurface,
                ),
              ),
              const Spacer(),
              SectionLabel(
                text: state.isActive ? 'SECURE LINK' : 'BINDING',
                color: state.isActive
                    ? AppColors.tertiaryContainer
                    : AppColors.onSurfaceVariant,
                showBar: false,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StartingView extends StatelessWidget {
  const _StartingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'BINDING LOCAL RELAY…',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubBody extends StatelessWidget {
  const _HubBody({
    required this.state,
    required this.onCopy,
    required this.onPublish,
    required this.onDownload,
  });

  final ServerState state;
  final void Function(ServerSession session) onCopy;
  final VoidCallback onPublish;
  final void Function(ServerSharedFile file) onDownload;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppConstants.screenMargin),
      children: [
        _ActiveBanner(port: state.session.port),
        const SizedBox(height: 14),
        _BeaconCard(
          session: state.session,
          isRefreshing: state.isRefreshing,
          onCopy: () => onCopy(state.session),
          onRefresh: () => context.read<ServerCubit>().refresh(),
        ),
        const SizedBox(height: 14),
        _HostUploadCard(isPublishing: state.isPublishing, onPublish: onPublish),
        const SizedBox(height: 14),
        _ConnectionsCard(clients: state.clients),
        if (state.hudLogsEnabled) ...[
          const SizedBox(height: 14),
          _UploadLogCard(uploads: state.uploads),
        ],
        const SizedBox(height: 14),
        _StorageCard(files: state.sharedFiles, onDownload: onDownload),
      ],
    );
  }
}

class _ActiveBanner extends StatelessWidget {
  const _ActiveBanner({required this.port});

  final int port;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppConstants.cardPadding,
        vertical: 12,
      ),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        border: Border.all(color: AppColors.primaryContainer, width: 1),
        borderRadius: AppTheme.sharp,
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            color: AppColors.tertiaryContainer,
          ),
          const SizedBox(width: 10),
          Text(
            'SERVER ACTIVE',
            style: AppTextStyles.labelCaps.copyWith(
              color: AppColors.primaryContainer,
            ),
          ),
          const Spacer(),
          Text(
            'PORT: $port',
            style: AppTextStyles.codeSm.copyWith(
              color: AppColors.primaryContainer,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _BeaconCard extends StatelessWidget {
  const _BeaconCard({
    required this.session,
    required this.isRefreshing,
    required this.onCopy,
    required this.onRefresh,
  });

  final ServerSession session;
  final bool isRefreshing;
  final VoidCallback onCopy;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Column(
        children: [
          QrBeacon(data: session.url),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppConstants.cardPadding),
            color: AppColors.surfaceContainerLowest,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SectionLabel(
                  text: 'DIRECT CONNECT IP',
                  color: AppColors.onSurfaceVariant,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        session.directConnect.isEmpty
                            ? 'tcp://—'
                            : session.directConnect,
                        style: AppTextStyles.codeSm.copyWith(
                          color: AppColors.primaryContainer,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: onCopy,
                      child: const Icon(
                        Icons.copy_outlined,
                        size: 18,
                        color: AppColors.primaryContainer,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          BlazeButton(
            label: isRefreshing ? 'REBINDING…' : 'REFRESH BEACON',
            icon: Icons.refresh,
            variant: BlazeButtonVariant.outline,
            compact: true,
            isLoading: isRefreshing,
            onPressed: isRefreshing ? null : onRefresh,
          ),
        ],
      ),
    );
  }
}

class _ConnectionsCard extends StatelessWidget {
  const _ConnectionsCard({required this.clients});

  final List<ConnectedClient> clients;

  @override
  Widget build(BuildContext context) {
    final count = clients.length;
    return _Card(
      title: 'ACTIVE_CONNECTIONS [$count]',
      child: clients.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'NO GUESTS CONNECTED',
                style: AppTextStyles.codeSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (final client in clients)
                  ConnectionTile(client: client),
              ],
            ),
    );
  }
}

/// Host→hub upload card (FUNCTIONALITY.md §5.4 "Host Management"): the host
/// stages files from its device and pushes them into the hub so guests can
/// download them.
class _HostUploadCard extends StatelessWidget {
  const _HostUploadCard({
    required this.isPublishing,
    required this.onPublish,
  });

  final bool isPublishing;
  final VoidCallback onPublish;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'HOST UPLOAD // DEPLOY ASSETS',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: isPublishing ? null : onPublish,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainerLowest,
                border: Border.all(
                  color: AppColors.primaryContainer.withValues(alpha: 0.55),
                  width: 1.5,
                ),
                borderRadius: AppTheme.sharp,
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.cloud_upload_outlined,
                    size: 30,
                    color: AppColors.primaryContainer,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'DEPLOY ASSETS HERE',
                    style: AppTextStyles.labelCaps.copyWith(
                      color: AppColors.primaryContainer,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Push files from this device to the hub.',
                    style: AppTextStyles.bodySm.copyWith(
                      color: AppColors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          BlazeButton(
            label: isPublishing ? 'PUBLISHING…' : 'PUSH FILES',
            icon: Icons.bolt,
            variant: BlazeButtonVariant.cta,
            compact: true,
            isLoading: isPublishing,
            onPressed: isPublishing ? null : onPublish,
          ),
        ],
      ),
    );
  }
}

class _UploadLogCard extends StatelessWidget {
  const _UploadLogCard({required this.uploads});

  final List<ServerUploadEvent> uploads;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'UPLOAD_LOG ⚙ LIVE',
      child: uploads.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                '> SYSTEM STANDBY…',
                style: AppTextStyles.codeSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (final event in uploads) UploadLogTile(event: event),
              ],
            ),
    );
  }
}

class _StorageCard extends StatelessWidget {
  const _StorageCard({required this.files, required this.onDownload});

  final List<ServerSharedFile> files;
  final void Function(ServerSharedFile file) onDownload;

  @override
  Widget build(BuildContext context) {
    return _Card(
      title: 'AVAILABLE ON SERVER',
      child: files.isEmpty
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'NO ASSETS SHARED',
                style: AppTextStyles.codeSm.copyWith(
                  color: AppColors.onSurfaceVariant,
                ),
              ),
            )
          : Column(
              children: [
                for (final file in files)
                  StorageTile(file: file, onDownload: () => onDownload(file)),
              ],
            ),
    );
  }
}

/// Sharp-cornered section card with a label-caps header strip.
class _Card extends StatelessWidget {
  const _Card({required this.child, this.title});

  final Widget child;
  final String? title;

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
          if (title != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.cardPadding,
                vertical: 10,
              ),
              color: AppColors.surfaceContainerHigh,
              child: SectionLabel(
                text: title!,
                color: AppColors.primaryContainer,
              ),
            ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.cardPadding,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _StopBar extends StatelessWidget {
  const _StopBar({
    required this.isActive,
    required this.isRefreshing,
    required this.onStop,
  });

  final bool isActive;
  final bool isRefreshing;
  final VoidCallback onStop;

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
        label: 'STOP SERVER',
        icon: Icons.power_settings_new,
        variant: BlazeButtonVariant.cta,
        enabled: isActive,
        isLoading: isRefreshing,
        onPressed: isActive ? onStop : null,
      ),
    );
  }
}
