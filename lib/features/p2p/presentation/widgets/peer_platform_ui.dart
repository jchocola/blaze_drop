import 'package:flutter/material.dart';

import '../../domain/entities/peer_device.dart';

/// UI mapping for [PeerPlatform] (FUNCTIONALITY.md §4.1 device card).
extension PeerPlatformUi on PeerPlatform {
  IconData get icon => switch (this) {
    PeerPlatform.android => Icons.android_outlined,
    PeerPlatform.ios => Icons.phone_iphone_outlined,
    PeerPlatform.windows => Icons.desktop_windows_outlined,
    PeerPlatform.macos => Icons.laptop_mac_outlined,
    PeerPlatform.linux => Icons.terminal_outlined,
    PeerPlatform.other => Icons.devices_other_outlined,
  };

  String get label => switch (this) {
    PeerPlatform.android => 'ANDROID',
    PeerPlatform.ios => 'iOS',
    PeerPlatform.windows => 'WINDOWS',
    PeerPlatform.macos => 'MACOS',
    PeerPlatform.linux => 'LINUX',
    PeerPlatform.other => 'UNKNOWN',
  };
}
