import 'package:equatable/equatable.dart';

/// Defaults for the "System Config" screen (FUNCTIONALITY.md mock
/// "SYSTEM CONFIG"). Mirrors the shipped dark HUD state.
abstract final class AppConfigDefaults {
  static const bool autoAcceptIncoming = false;
  static const bool networkDiscovery = false;
  static const bool e2eEncryption = true;
  static const int sessionTimeoutMinutes = 15;
  static const bool darkMode = false;
  static const bool showHudLogs = true;
}

/// Immutable application configuration edited on the "SYSTEM CONFIG" screen.
///
/// Lives in `core` so that the Server feature can read connection/security
/// preferences without depending on the settings feature (RULE.md §1.2 —
/// features only depend on core).
class AppConfig extends Equatable {
  const AppConfig({
    this.autoAcceptIncoming = AppConfigDefaults.autoAcceptIncoming,
    this.networkDiscovery = AppConfigDefaults.networkDiscovery,
    this.e2eEncryption = AppConfigDefaults.e2eEncryption,
    this.sessionTimeoutMinutes = AppConfigDefaults.sessionTimeoutMinutes,
    this.darkMode = AppConfigDefaults.darkMode,
    this.showHudLogs = AppConfigDefaults.showHudLogs,
  });

  /// Auto-accept incoming transfers from known nodes.
  final bool autoAcceptIncoming;

  /// Allow nearby devices to find this node.
  final bool networkDiscovery;

  /// Force AES-256 encryption on all transfers (stored; transport-level
  /// enforcement is future scope — FUNCTIONALITY.md §7).
  final bool e2eEncryption;

  /// Inactivity (minutes) before a connected session is forced to disconnect.
  final int sessionTimeoutMinutes;

  /// Dark mode. Enforced by the system protocol — stored but UI-locked.
  final bool darkMode;

  /// Show the real-time transfer log (the "HUD Terminal") on server screens.
  final bool showHudLogs;

  static const AppConfig defaults = AppConfig();

  AppConfig copyWith({
    bool? autoAcceptIncoming,
    bool? networkDiscovery,
    bool? e2eEncryption,
    int? sessionTimeoutMinutes,
    bool? darkMode,
    bool? showHudLogs,
  }) {
    return AppConfig(
      autoAcceptIncoming: autoAcceptIncoming ?? this.autoAcceptIncoming,
      networkDiscovery: networkDiscovery ?? this.networkDiscovery,
      e2eEncryption: e2eEncryption ?? this.e2eEncryption,
      sessionTimeoutMinutes: sessionTimeoutMinutes ?? this.sessionTimeoutMinutes,
      darkMode: darkMode ?? this.darkMode,
      showHudLogs: showHudLogs ?? this.showHudLogs,
    );
  }

  @override
  List<Object?> get props => [
    autoAcceptIncoming,
    networkDiscovery,
    e2eEncryption,
    sessionTimeoutMinutes,
    darkMode,
    showHudLogs,
  ];
}
