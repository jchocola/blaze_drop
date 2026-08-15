import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/config/settings_repository.dart';
import '../../../../core/constants/constants.dart';
import '../../../../core/utils/logger.dart';
import '../../domain/entities/connected_client.dart';
import '../../domain/entities/downloaded_file.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/server_upload_event.dart';
import '../../domain/use_cases/download_shared_file_use_case.dart';
import '../../domain/use_cases/list_shared_files_use_case.dart';
import '../../domain/use_cases/pick_host_files_use_case.dart';
import '../../domain/use_cases/publish_files_use_case.dart';
import '../../domain/use_cases/refresh_server_use_case.dart';
import '../../domain/use_cases/start_server_use_case.dart';
import '../../domain/use_cases/stop_server_use_case.dart';
import '../../domain/use_cases/watch_connected_clients_use_case.dart';
import '../../domain/use_cases/watch_server_status_use_case.dart';
import '../../domain/use_cases/watch_uploads_use_case.dart';
import 'server_state.dart';

/// Orchestrates Server Mode (FUNCTIONALITY.md §5):
///
/// activate hub → show QR/URL → live connected clients → incoming upload HUD
/// → stop server. No business logic here — delegates to use cases and maps
/// results into immutable [ServerState]s (RULE.md §2).
class ServerCubit extends Cubit<ServerState> {
  ServerCubit({
    required this.startServerUseCase,
    required this.stopServerUseCase,
    required this.refreshServerUseCase,
    required this.watchServerStatusUseCase,
    required this.watchConnectedClientsUseCase,
    required this.watchUploadsUseCase,
    required this.listSharedFilesUseCase,
    required this.pickHostFilesUseCase,
    required this.publishFilesUseCase,
    required this.downloadSharedFileUseCase,
    required SettingsRepository settingsRepository,
  }) : _settingsRepository = settingsRepository,
       super(const ServerState());

  final StartServerUseCase startServerUseCase;
  final StopServerUseCase stopServerUseCase;
  final RefreshServerUseCase refreshServerUseCase;
  final WatchServerStatusUseCase watchServerStatusUseCase;
  final WatchConnectedClientsUseCase watchConnectedClientsUseCase;
  final WatchUploadsUseCase watchUploadsUseCase;
  final ListSharedFilesUseCase listSharedFilesUseCase;
  final PickHostFilesUseCase pickHostFilesUseCase;
  final PublishFilesUseCase publishFilesUseCase;
  final DownloadSharedFileUseCase downloadSharedFileUseCase;
  final SettingsRepository _settingsRepository;

  StreamSubscription<ServerSession>? _statusSub;
  StreamSubscription<List<ConnectedClient>>? _clientsSub;
  StreamSubscription<ServerUploadEvent>? _uploadsSub;
  bool _initialized = false;

  /// Subscribes to the hub streams and applies the HUD preference.
  Future<void> initialize() async {
    if (_initialized) {
      return;
    }
    _initialized = true;
    try {
      final config = await _settingsRepository.loadConfig();
      if (!isClosed) {
        emit(state.copyWith(hudLogsEnabled: config.showHudLogs));
      }
    } catch (error, stack) {
      AppLogger.error('Failed to load config for server HUD', error, stack);
    }
    _statusSub = watchServerStatusUseCase.execute().listen(
      (session) {
        if (!isClosed) {
          emit(state.copyWith(session: session, error: null));
        }
      },
      onError: _onStreamError,
    );
    _clientsSub = watchConnectedClientsUseCase.execute().listen(
      (clients) {
        if (!isClosed) {
          emit(state.copyWith(clients: clients));
        }
      },
      onError: _onStreamError,
    );
    _uploadsSub = watchUploadsUseCase.execute().listen(
      (event) {
        if (isClosed) {
          return;
        }
        final logs = [event, ...state.uploads]
            .take(AppConstants.serverUploadLogLimit)
            .toList();
        emit(state.copyWith(uploads: logs));
        // A completed transfer (guest upload or host publication) changes the
        // hub storage — refresh the shareable list live instead of waiting
        // for a server restart.
        if (event.status == ServerUploadStatus.completed) {
          refreshFiles();
        }
      },
      onError: _onStreamError,
    );
  }

  void _onStreamError(Object error, StackTrace stack) {
    AppLogger.error('Server stream error', error, stack);
    if (!isClosed) {
      emit(state.copyWith(error: 'Relay stream error: $error'));
    }
  }

  /// Activates the hub (binds sockets, resolves IP, serves the web client).
  Future<void> startServer() async {
    if (state.isActive || state.session.status == ServerStatus.starting) {
      return;
    }
    if (state.error != null) {
      emit(state.copyWith(error: null));
    }
    try {
      final config = await _settingsRepository.loadConfig();
      final session = await startServerUseCase.execute(
        sessionTimeoutMinutes: config.sessionTimeoutMinutes,
      );
      if (!isClosed) {
        emit(state.copyWith(session: session));
      }
      AppLogger.info('Relay hub started on port ${session.port}');
      await refreshFiles();
    } catch (error, stack) {
      AppLogger.error('Failed to start relay hub', error, stack);
      if (!isClosed) {
        emit(state.copyWith(error: 'Server failed to start'));
      }
    }
  }

  /// Terminates the hub.
  Future<void> stopServer() async {
    try {
      await stopServerUseCase.execute();
    } catch (error, stack) {
      AppLogger.error('Failed to stop relay hub', error, stack);
    }
    if (!isClosed) {
      emit(
        state.copyWith(
          session: const ServerSession(status: ServerStatus.stopped),
          clients: const [],
          uploads: const [],
        ),
      );
    }
  }

  /// Restarts the hub on a fresh port (QR/URL change).
  Future<void> refresh() async {
    emit(state.copyWith(isRefreshing: true, error: null));
    try {
      await refreshServerUseCase.execute();
      await refreshFiles();
    } catch (error, stack) {
      AppLogger.error('Failed to refresh relay hub', error, stack);
      if (!isClosed) {
        emit(state.copyWith(error: 'Refresh failed'));
      }
    }
    if (!isClosed) {
      emit(state.copyWith(isRefreshing: false));
    }
  }

  /// Re-scans the shared storage.
  Future<void> refreshFiles() async {
    try {
      final files = await listSharedFilesUseCase.execute();
      if (!isClosed) {
        emit(state.copyWith(sharedFiles: files));
      }
    } catch (error, stack) {
      AppLogger.error('Failed to list shared files', error, stack);
    }
  }

  /// Opens the host picker and publishes the chosen files into the hub so
  /// guests can download them (FUNCTIONALITY.md §5.4).
  Future<void> pickAndPublishFiles() async {
    if (state.isPublishing) {
      return;
    }
    emit(state.copyWith(isPublishing: true, error: null));
    var published = false;
    try {
      final files = await pickHostFilesUseCase.execute();
      if (files.isNotEmpty && !isClosed) {
        await publishFilesUseCase.execute(files);
        published = true;
        AppLogger.info('Published ${files.length} file(s) to the hub');
      }
    } catch (error, stack) {
      AppLogger.error('Failed to publish files', error, stack);
      if (!isClosed) {
        emit(state.copyWith(error: 'Failed to publish files'));
      }
    } finally {
      if (!isClosed) {
        emit(state.copyWith(isPublishing: false));
      }
    }
    // The completed publication events already refresh the storage list, but
    // re-scan once more so the UI reflects the exact result.
    if (published && !isClosed) {
      await refreshFiles();
    }
  }

  /// Pulls a copy of [fileId] from the hub to this device: photos land in the
  /// gallery, other files in documents. Returns the result (or null on
  /// failure) for UI feedback.
  Future<DownloadedFile?> downloadSharedFile(String fileId) async {
    try {
      final downloaded = await downloadSharedFileUseCase.execute(fileId);
      return downloaded;
    } catch (error, stack) {
      AppLogger.error('Failed to download shared file', error, stack);
      if (!isClosed) {
        emit(state.copyWith(error: 'Download failed'));
      }
      return null;
    }
  }

  /// Clears the HUD transfer log.
  void clearUploads() {
    if (!isClosed) {
      emit(state.copyWith(uploads: const []));
    }
  }

  @override
  Future<void> close() async {
    await _statusSub?.cancel();
    await _clientsSub?.cancel();
    await _uploadsSub?.cancel();
    _statusSub = null;
    _clientsSub = null;
    _uploadsSub = null;
    await super.close();
  }
}
