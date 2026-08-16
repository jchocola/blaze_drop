/// Global application constants for BlazeDrop.
///
/// All reused literals (strings, durations, layout metrics) are centralized
/// here and grouped by purpose (see RULE.md §5). Avoid inline "magic values".
abstract final class AppConstants {
  static const String appName = 'BlazeDrop';
  static const String tagline = 'HIGH-PERFORMANCE UTILITY';

  /// Route paths (used by `go_router` configuration).
  static const String splashPath = '/splash';
  static const String onboardingPath = '/onboarding';
  static const String homePath = '/home';
  static const String p2pPath = '/p2p';
  static const String p2pTransferPath = '/p2p/transfer';
  static const String serverPath = '/server';
  static const String settingsPath = '/settings';
  static const String historyPath = '/history';

  /// Number of most-recent server sessions kept in the transfer history
  /// (FUNCTIONALITY.md mock "HISTORY"; older sessions are pruned).
  static const int maxHistorySessions = 3;

  /// Timing.
  static const Duration splashDuration = Duration(milliseconds: 2000);
  static const Duration shortAnimation = Duration(milliseconds: 250);
  static const Duration mediumAnimation = Duration(milliseconds: 400);

  /// Layout scale (4px baseline grid, DESIGN.md).
  static const double unit = 4.0;
  static const double gutter = 16.0;
  static const double cardPadding = 12.0;
  static const double screenMargin = 16.0;
  static const double buttonHeight = 52.0;

  // --- Module B: P2P networking (FUNCTIONALITY.md §4) ---------------------

  /// UDP port used for LAN device-discovery beacons.
  static const int p2pBeaconPort = 43210;

  /// Default TCP port used for the P2P handshake + transfer socket. Falls
  /// back to auto-assigned ports when busy.
  static const int p2pServicePort = 43211;

  /// File transfer chunk size (1 MB per chunk, FUNCTIONALITY.md §4.3).
  static const int p2pChunkSize = 1024 * 1024;

  /// Interval between discovery beacon broadcasts.
  static const Duration p2pBeaconInterval = Duration(seconds: 2);

  /// Auto-refresh cadence for the discovered-device list.
  static const Duration p2pScanInterval = Duration(seconds: 5);

  /// A peer is dropped from the list after this long without a beacon
  /// (FUNCTIONALITY.md §4.1).
  static const Duration p2pPeerTimeout = Duration(seconds: 10);

  /// Incoming connection request auto-decline timeout
  /// (FUNCTIONALITY.md §4.2).
  static const Duration p2pRequestTimeout = Duration(seconds: 30);

  /// Bonjour service type advertised by the app (iOS Info.plist mirror).
  static const String p2pServiceType = '_blazedrop._tcp';

  // --- Module C: Server Mode / Host-Web (FUNCTIONALITY.md §5) -------------

  /// First port tried when activating the local relay hub.
  static const int serverDefaultPort = 8080;

  /// Ports tried sequentially (8080 → 8081 → …) before falling back to an
  /// OS-assigned port (FUNCTIONALITY.md §8 "Server Port Conflict").
  static const int serverPortAttempts = 50;

  /// A connected guest is pruned from the live list after this long without
  /// a ping.
  static const Duration serverClientTimeout = Duration(seconds: 15);

  /// Interval at which the embedded web client pings the host to stay
  /// "online".
  static const Duration serverGuestPingInterval = Duration(seconds: 5);

  /// Max upload-log entries kept in the server HUD.
  static const int serverUploadLogLimit = 50;

  /// Asset paths for the embedded guest web client (served at matching HTTP
  /// routes).
  static const String webClientIndexPath = 'assets/web_client/index.html';
  static const String webClientCssPath = 'assets/web_client/style.css';
  static const String webClientJsPath = 'assets/web_client/app.js';

  // --- App version (compile-time fallback) --------------------------------

  /// Fallback app version used when the `package_info_plus` platform channel
  /// is unavailable (stale build, widget tests, unsupported hosts).
  /// Keep in sync with `pubspec.yaml` `version:`.
  static const String appVersionFallback = '0.1.0';

  /// Fallback build number shown when the platform channel is unavailable.
  static const String appBuildNumberFallback = '0';

  /// Fallback application/package id (mirrors the Android `applicationId`).
  static const String appPackageNameFallback = 'com.jchocola.blaze_drop';

  // --- Module D: Legal links (external, open via `url_launcher`) ----------

  /// External Privacy Policy URL (placeholder — set before release).
  static const String privacyPolicyUrl = 'https://docs.google.com/document/d/1cJxDUOEvpnUyYLCAebQSN17ImugS4xR_siEwqgPE_-g/edit?usp=share_link';

  /// External Terms of Service URL (placeholder — set before release).
  static const String termsOfServiceUrl = 'https://docs.google.com/document/d/1PMU9PtvbeP3eizKMBs9sMsWZdUoyrQ_21yAAZJLU6nA/edit?usp=share_link';
}

/// Keys used for local persistence.
abstract final class StorageKeys {
  static const String deviceName = 'device_name';
  static const String onboardingComplete = 'onboarding_complete';
  static const String p2pNodeId = 'p2p_node_id';

  // System Config (FUNCTIONALITY.md mock "SYSTEM CONFIG").
  static const String configAutoAccept = 'config_auto_accept';
  static const String configNetworkDiscovery = 'config_network_discovery';
  static const String configE2eEncryption = 'config_e2e_encryption';
  static const String configSessionTimeout = 'config_session_timeout';
  static const String configDarkMode = 'config_dark_mode';
  static const String configShowHudLogs = 'config_show_hud_logs';

  // Transfer history (server sessions archive).
  static const String transferHistory = 'transfer_history';
}
