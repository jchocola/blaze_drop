import 'package:equatable/equatable.dart';

import '../../domain/entities/connected_client.dart';
import '../../domain/entities/server_session.dart';
import '../../domain/entities/server_shared_file.dart';
import '../../domain/entities/server_upload_event.dart';

/// UI state for the Server Mode flow (FUNCTIONALITY.md §5).
class ServerState extends Equatable {
  const ServerState({
    this.session = const ServerSession(),
    this.clients = const [],
    this.sharedFiles = const [],
    this.uploads = const [],
    this.hudLogsEnabled = true,
    this.isRefreshing = false,
    this.error,
  });

  /// Hub lifecycle + connection info (port, local IP, URL).
  final ServerSession session;

  /// Live connected-guest list.
  final List<ConnectedClient> clients;

  /// Files shareable on the hub.
  final List<ServerSharedFile> sharedFiles;

  /// Recent incoming-upload events (HUD transfer log, newest first).
  final List<ServerUploadEvent> uploads;

  /// Whether the HUD transfer log is visible (SYSTEM CONFIG → Show HUD Logs).
  final bool hudLogsEnabled;

  final bool isRefreshing;

  final String? error;

  bool get isActive => session.isActive;

  ServerState copyWith({
    ServerSession? session,
    List<ConnectedClient>? clients,
    List<ServerSharedFile>? sharedFiles,
    List<ServerUploadEvent>? uploads,
    bool? hudLogsEnabled,
    bool? isRefreshing,
    Object? error = _unset,
  }) {
    return ServerState(
      session: session ?? this.session,
      clients: clients ?? this.clients,
      sharedFiles: sharedFiles ?? this.sharedFiles,
      uploads: uploads ?? this.uploads,
      hudLogsEnabled: hudLogsEnabled ?? this.hudLogsEnabled,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: identical(error, _unset) ? this.error : error as String?,
    );
  }

  static const _unset = Object();

  @override
  List<Object?> get props => [
    session,
    clients,
    sharedFiles,
    uploads,
    hudLogsEnabled,
    isRefreshing,
    error,
  ];
}
