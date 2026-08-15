import 'dart:io';

import '../../../../core/utils/logger.dart';

/// Resolves the local IPv4 address advertised by the QR beacon.
abstract interface class LocalIpResolver {
  Future<String> resolve();
}

/// [LocalIpResolver] backed by `dart:io` interface enumeration.
///
/// Prefers a private-range address (192.168/16, 10/8, 172.16-31/12) so the
/// QR points at the LAN interface the guests actually reach.
class NetworkLocalIpResolver implements LocalIpResolver {
  const NetworkLocalIpResolver();

  @override
  Future<String> resolve() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
        includeLinkLocal: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (_isPrivate(address.address)) {
            return address.address;
          }
        }
      }
      for (final interface in interfaces) {
        if (interface.addresses.isNotEmpty) {
          return interface.addresses.first.address;
        }
      }
    } catch (error, stack) {
      AppLogger.warning('Local IP resolution failed: $error');
      AppLogger.error('Local IP resolution failed', error, stack);
    }
    return '127.0.0.1';
  }

  bool _isPrivate(String ip) {
    if (ip.startsWith('192.168.')) {
      return true;
    }
    if (ip.startsWith('10.')) {
      return true;
    }
    final parts = ip.split('.');
    if (parts.length == 4) {
      final second = int.tryParse(parts[1]) ?? -1;
      if (parts[0] == '172' && second >= 16 && second <= 31) {
        return true;
      }
    }
    return false;
  }
}
