import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/onboarding/data/datasources/onboarding_local_data_source.dart';
import '../../features/onboarding/data/datasources/permission_local_data_source.dart';
import '../../features/onboarding/data/repositories_impl/onboarding_repository_impl.dart';
import '../../features/onboarding/data/repositories_impl/permission_repository_impl.dart';
import '../../features/onboarding/domain/repositories/onboarding_repository.dart';
import '../../features/onboarding/domain/repositories/permission_repository.dart';
import '../../features/onboarding/domain/use_cases/check_permissions_use_case.dart';
import '../../features/onboarding/domain/use_cases/complete_onboarding_use_case.dart';
import '../../features/onboarding/domain/use_cases/get_onboarding_completion_use_case.dart';
import '../../features/onboarding/domain/use_cases/open_app_settings_use_case.dart';
import '../../features/onboarding/domain/use_cases/request_permissions_use_case.dart';
import '../../features/onboarding/presentation/cubit/onboarding_cubit.dart';
import '../../features/p2p/data/datasources/camera_picker_data_source.dart';
import '../../features/p2p/data/datasources/file_picker_data_source.dart';
import '../../features/p2p/data/datasources/gallery_picker_data_source.dart';
import '../../features/p2p/data/datasources/node_identity_store.dart';
import '../../features/p2p/data/datasources/peer_transport_data_source.dart';
import '../../features/p2p/data/datasources/peer_transport_impl.dart';
import '../../features/p2p/data/datasources/system_camera_picker.dart';
import '../../features/p2p/data/datasources/system_file_picker.dart';
import '../../features/p2p/data/datasources/system_gallery_picker.dart';
import '../../features/p2p/data/repositories_impl/peer_repository_impl.dart';
import '../../features/p2p/domain/repositories/peer_repository.dart';
import '../../features/p2p/domain/use_cases/capture_photo_use_case.dart';
import '../../features/p2p/domain/use_cases/get_local_node_name_use_case.dart';
import '../../features/p2p/domain/use_cases/get_inbox_directory_use_case.dart';
import '../../features/p2p/domain/use_cases/pick_files_use_case.dart';
import '../../features/p2p/domain/use_cases/pick_gallery_photos_use_case.dart';
import '../../features/p2p/domain/use_cases/respond_to_request_use_case.dart';
import '../../features/p2p/domain/use_cases/send_files_use_case.dart';
import '../../features/p2p/domain/use_cases/start_discovery_use_case.dart';
import '../../features/p2p/domain/use_cases/stop_discovery_use_case.dart';
import '../../features/p2p/domain/use_cases/watch_discovered_peers_use_case.dart';
import '../../features/p2p/domain/use_cases/watch_incoming_requests_use_case.dart';
import '../../features/p2p/domain/use_cases/watch_transfer_updates_use_case.dart';
import '../../features/p2p/presentation/cubit/p2p_cubit.dart';
import '../../features/server/data/datasources/device_media_store.dart';
import '../../features/server/data/datasources/host_file_picker.dart';
import '../../features/server/data/datasources/local_ip_resolver.dart';
import '../../features/server/data/datasources/media_store.dart';
import '../../features/server/data/datasources/shelf_web_server_transport.dart';
import '../../features/server/data/datasources/web_client_assets.dart';
import '../../features/server/data/datasources/web_server_transport.dart';
import '../../features/server/data/repositories_impl/server_repository_impl.dart';
import '../../features/server/domain/repositories/server_repository.dart';
import '../../features/server/domain/use_cases/download_shared_file_use_case.dart';
import '../../features/server/domain/use_cases/list_shared_files_use_case.dart';
import '../../features/server/domain/use_cases/pick_host_camera_photo_use_case.dart';
import '../../features/server/domain/use_cases/pick_host_files_use_case.dart';
import '../../features/server/domain/use_cases/pick_host_gallery_photos_use_case.dart';
import '../../features/server/domain/use_cases/publish_files_use_case.dart';
import '../../features/server/domain/use_cases/refresh_server_use_case.dart';
import '../../features/server/domain/use_cases/start_server_use_case.dart';
import '../../features/server/domain/use_cases/stop_server_use_case.dart';
import '../../features/server/domain/use_cases/watch_connected_clients_use_case.dart';
import '../../features/server/domain/use_cases/watch_server_status_use_case.dart';
import '../../features/server/domain/use_cases/watch_uploads_use_case.dart';
import '../../features/server/presentation/cubit/server_cubit.dart';
import '../../features/settings/data/datasources/settings_local_data_source.dart';
import '../../features/settings/data/datasources/version_package_data_source.dart';
import '../../features/settings/data/repositories_impl/settings_repository_impl.dart';
import '../../features/settings/data/repositories_impl/version_repository_impl.dart';
import '../../features/settings/domain/repositories/version_repository.dart';
import '../../features/settings/domain/use_cases/get_version_info_use_case.dart';
import '../../features/settings/domain/use_cases/load_config_use_case.dart';
import '../../features/settings/domain/use_cases/reset_config_use_case.dart';
import '../../features/settings/domain/use_cases/save_config_use_case.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/history/data/datasources/history_local_data_source.dart';
import '../../features/history/data/repositories_impl/history_repository_impl.dart';
import '../../features/history/domain/use_cases/clear_history_use_case.dart';
import '../../features/history/domain/use_cases/get_history_use_case.dart';
import '../../features/history/domain/use_cases/watch_history_use_case.dart';
import '../../features/history/presentation/cubit/history_cubit.dart';
import '../config/settings_repository.dart';
import '../history/history_repository.dart';
import '../utils/storage_paths.dart';

/// Service locator (get_it). Configure once at app startup (RULE.md §3).
final GetIt sl = GetIt.instance;

/// Registers all application dependencies.
///
/// Scope rules (RULE.md §3.1):
/// - repositories / use cases: `registerLazySingleton`
/// - cubits: `registerFactory` (fresh instance per access)
Future<void> setupLocator() async {
  // Local persistence.
  final prefs = await SharedPreferences.getInstance();
  sl
    ..registerLazySingleton<SharedPreferences>(() => prefs)
    ..registerLazySingleton<NodeIdentityStore>(() => NodeIdentityStore(prefs));

  // Module A — onboarding / permissions.
  sl
    ..registerLazySingleton<PermissionLocalDataSource>(
      PermissionLocalDataSource.new,
    )
    ..registerLazySingleton<PermissionRepository>(
      () => PermissionRepositoryImpl(sl<PermissionLocalDataSource>()),
    )
    ..registerLazySingleton<OnboardingLocalDataSource>(
      () => OnboardingLocalDataSource(prefs),
    )
    ..registerLazySingleton<OnboardingRepository>(
      () => OnboardingRepositoryImpl(sl<OnboardingLocalDataSource>()),
    );

  // Module B — P2P data layer.
  final identityStore = sl<NodeIdentityStore>();
  await identityStore.ensureReady();
  final nodeId = await identityStore.getNodeId();
  final nodeName = await identityStore.getNodeName();
  sl
    ..registerLazySingleton<FilePickerDataSource>(SystemFilePicker.new)
    ..registerLazySingleton<GalleryPickerDataSource>(SystemGalleryPicker.new)
    ..registerLazySingleton<CameraPickerDataSource>(SystemCameraPicker.new)
    ..registerLazySingleton<PeerTransportDataSource>(
      () => PeerTransportImpl(
        nodeId: nodeId,
        nodeName: nodeName,
        inboxDirectoryProvider: () => StoragePaths.inboxDirectory,
      ),
    )
    ..registerLazySingleton<PeerRepository>(
      () => PeerRepositoryImpl(
        transport: sl<PeerTransportDataSource>(),
        identityStore: sl<NodeIdentityStore>(),
        filePicker: sl<FilePickerDataSource>(),
        galleryPicker: sl<GalleryPickerDataSource>(),
        cameraPicker: sl<CameraPickerDataSource>(),
      ),
    );

  // Domain use cases (Module A).
  sl
    ..registerLazySingleton(
      () => CheckPermissionsUseCase(sl<PermissionRepository>()),
    )
    ..registerLazySingleton(
      () => RequestPermissionsUseCase(sl<PermissionRepository>()),
    )
    ..registerLazySingleton(
      () => OpenAppSettingsUseCase(sl<PermissionRepository>()),
    )
    ..registerLazySingleton(
      () => CompleteOnboardingUseCase(sl<OnboardingRepository>()),
    )
    ..registerLazySingleton(
      () => GetOnboardingCompletionUseCase(sl<OnboardingRepository>()),
    );

  // Domain use cases (Module B).
  sl
    ..registerLazySingleton(
      () => GetLocalNodeNameUseCase(sl<PeerRepository>()),
    )
    ..registerLazySingleton(
      () => StartDiscoveryUseCase(sl<PeerRepository>()),
    )
    ..registerLazySingleton(
      () => StopDiscoveryUseCase(sl<PeerRepository>()),
    )
    ..registerLazySingleton(
      () => WatchDiscoveredPeersUseCase(sl<PeerRepository>()),
    )
    ..registerLazySingleton(
      () => WatchIncomingRequestsUseCase(sl<PeerRepository>()),
    )
    ..registerLazySingleton(
      () => WatchTransferUpdatesUseCase(sl<PeerRepository>()),
    )
    ..registerLazySingleton(() => PickFilesUseCase(sl<PeerRepository>()))
    ..registerLazySingleton(
      () => PickGalleryPhotosUseCase(sl<PeerRepository>()),
    )
    ..registerLazySingleton(() => CapturePhotoUseCase(sl<PeerRepository>()))
    ..registerLazySingleton(() => SendFilesUseCase(sl<PeerRepository>()))
    ..registerLazySingleton(
      () => RespondToRequestUseCase(sl<PeerRepository>()),
    )
    ..registerLazySingleton(
      () => GetInboxDirectoryUseCase(sl<PeerRepository>()),
    );

  // Module C — Settings (SYSTEM CONFIG, FUNCTIONALITY.md mock).
  sl
    ..registerLazySingleton<SettingsLocalDataSource>(
      () => SettingsLocalDataSource(prefs),
    )
    ..registerLazySingleton<SettingsRepository>(
      () => SettingsRepositoryImpl(sl<SettingsLocalDataSource>()),
    )
    ..registerLazySingleton<VersionPackageDataSource>(
      VersionPackageDataSource.new,
    )
    ..registerLazySingleton<VersionRepository>(
      () => VersionRepositoryImpl(sl<VersionPackageDataSource>()),
    );

  // Domain use cases (Module C — Settings).
  sl
    ..registerLazySingleton(() => LoadConfigUseCase(sl<SettingsRepository>()))
    ..registerLazySingleton(() => SaveConfigUseCase(sl<SettingsRepository>()))
    ..registerLazySingleton(() => ResetConfigUseCase(sl<SettingsRepository>()))
    ..registerLazySingleton(
      () => GetVersionInfoUseCase(sl<VersionRepository>()),
    );

  // Module C — Server Mode (Host-Web, FUNCTIONALITY.md §5).
  sl
    ..registerLazySingleton<LocalIpResolver>(NetworkLocalIpResolver.new)
    ..registerLazySingleton<WebClientAssets>(BundledWebClientAssets.new)
    ..registerLazySingleton<HostFilePicker>(SystemHostFilePicker.new)
    ..registerLazySingleton<MediaStore>(DeviceMediaStore.new)
    ..registerLazySingleton<HistoryLocalDataSource>(
      () => HistoryLocalDataSource(prefs),
    )
    ..registerLazySingleton<HistoryRepository>(
      () => LocalHistoryRepositoryImpl(sl<HistoryLocalDataSource>()),
    )
    ..registerLazySingleton<WebServerTransport>(
      () => ShelfWebServerTransport(
        ipResolver: sl<LocalIpResolver>(),
        assets: sl<WebClientAssets>(),
        sharedDirectoryProvider: () => StoragePaths.hubCacheDirectory,
        mediaStore: sl<MediaStore>(),
      ),
    )
    ..registerLazySingleton<ServerRepository>(
      () => ServerRepositoryImpl(
        transport: sl<WebServerTransport>(),
        filePicker: sl<HostFilePicker>(),
      ),
    );

  // Domain use cases (Module C — Server).
  sl
    ..registerLazySingleton(() => StartServerUseCase(sl<ServerRepository>()))
    ..registerLazySingleton(() => StopServerUseCase(sl<ServerRepository>()))
    ..registerLazySingleton(
      () => RefreshServerUseCase(sl<ServerRepository>()),
    )
    ..registerLazySingleton(
      () => WatchServerStatusUseCase(sl<ServerRepository>()),
    )
    ..registerLazySingleton(
      () => WatchConnectedClientsUseCase(sl<ServerRepository>()),
    )
    ..registerLazySingleton(() => WatchUploadsUseCase(sl<ServerRepository>()))
    ..registerLazySingleton(
      () => ListSharedFilesUseCase(sl<ServerRepository>()),
    )
    ..registerLazySingleton(
      () => PickHostFilesUseCase(sl<ServerRepository>()),
    )
    ..registerLazySingleton(
      () => PickHostGalleryPhotosUseCase(sl<ServerRepository>()),
    )
    ..registerLazySingleton(
      () => PickHostCameraPhotoUseCase(sl<ServerRepository>()),
    )
    ..registerLazySingleton(
      () => PublishFilesUseCase(sl<ServerRepository>()),
    )
    ..registerLazySingleton(
      () => DownloadSharedFileUseCase(sl<ServerRepository>()),
    );

  // Domain use cases (History / TRANSFER HISTORY).
  sl
    ..registerLazySingleton(() => WatchHistoryUseCase(sl<HistoryRepository>()))
    ..registerLazySingleton(() => GetHistoryUseCase(sl<HistoryRepository>()))
    ..registerLazySingleton(() => ClearHistoryUseCase(sl<HistoryRepository>()));

  // Presentation.
  sl.registerFactory(
    () => OnboardingCubit(
      checkPermissionsUseCase: sl<CheckPermissionsUseCase>(),
      requestPermissionsUseCase: sl<RequestPermissionsUseCase>(),
      openAppSettingsUseCase: sl<OpenAppSettingsUseCase>(),
      completeOnboardingUseCase: sl<CompleteOnboardingUseCase>(),
      getOnboardingCompletionUseCase: sl<GetOnboardingCompletionUseCase>(),
    ),
  );
  sl.registerFactory(
    () => P2pCubit(
      getLocalNodeNameUseCase: sl<GetLocalNodeNameUseCase>(),
      startDiscoveryUseCase: sl<StartDiscoveryUseCase>(),
      stopDiscoveryUseCase: sl<StopDiscoveryUseCase>(),
      watchDiscoveredPeersUseCase: sl<WatchDiscoveredPeersUseCase>(),
      watchIncomingRequestsUseCase: sl<WatchIncomingRequestsUseCase>(),
      watchTransferUpdatesUseCase: sl<WatchTransferUpdatesUseCase>(),
      pickFilesUseCase: sl<PickFilesUseCase>(),
      pickGalleryPhotosUseCase: sl<PickGalleryPhotosUseCase>(),
      capturePhotoUseCase: sl<CapturePhotoUseCase>(),
      sendFilesUseCase: sl<SendFilesUseCase>(),
      respondToRequestUseCase: sl<RespondToRequestUseCase>(),
    ),
  );
  sl.registerFactory(
    () => SettingsCubit(
      loadConfigUseCase: sl<LoadConfigUseCase>(),
      saveConfigUseCase: sl<SaveConfigUseCase>(),
      resetConfigUseCase: sl<ResetConfigUseCase>(),
      getVersionInfoUseCase: sl<GetVersionInfoUseCase>(),
    ),
  );
  sl.registerFactory(
    () => ServerCubit(
      startServerUseCase: sl<StartServerUseCase>(),
      stopServerUseCase: sl<StopServerUseCase>(),
      refreshServerUseCase: sl<RefreshServerUseCase>(),
      watchServerStatusUseCase: sl<WatchServerStatusUseCase>(),
      watchConnectedClientsUseCase: sl<WatchConnectedClientsUseCase>(),
      watchUploadsUseCase: sl<WatchUploadsUseCase>(),
      listSharedFilesUseCase: sl<ListSharedFilesUseCase>(),
      pickHostFilesUseCase: sl<PickHostFilesUseCase>(),
      pickHostGalleryPhotosUseCase: sl<PickHostGalleryPhotosUseCase>(),
      pickHostCameraPhotoUseCase: sl<PickHostCameraPhotoUseCase>(),
      publishFilesUseCase: sl<PublishFilesUseCase>(),
      downloadSharedFileUseCase: sl<DownloadSharedFileUseCase>(),
      settingsRepository: sl<SettingsRepository>(),
      historyRepository: sl<HistoryRepository>(),
    ),
  );
  sl.registerFactory(
    () => HistoryCubit(
      getHistoryUseCase: sl<GetHistoryUseCase>(),
      watchHistoryUseCase: sl<WatchHistoryUseCase>(),
      clearHistoryUseCase: sl<ClearHistoryUseCase>(),
    ),
  );
}
