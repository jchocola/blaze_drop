import 'dart:math' as math;

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/constants.dart';

/// Persists the stable identity of the local node (name + id).
///
/// Generated once on first launch, then reused across restarts so that other
/// nodes can recognise this device (FUNCTIONALITY.md §4).
class NodeIdentityStore {
  NodeIdentityStore(this._prefs);

  final SharedPreferences _prefs;
  String? _cachedName;
  String? _cachedId;

  /// The advertised node name (e.g. `NEXUS_NODE_09`).
  Future<String> getNodeName() async {
    final cached = _cachedName;
    if (cached != null) {
      return cached;
    }
    var name = _prefs.getString(StorageKeys.deviceName);
    if (name == null || name.isEmpty) {
      name = _generateNodeName();
      await _prefs.setString(StorageKeys.deviceName, name);
    }
    _cachedName = name;
    return name;
  }

  /// The stable unique id of this node.
  Future<String> getNodeId() async {
    final cached = _cachedId;
    if (cached != null) {
      return cached;
    }
    var id = _prefs.getString(StorageKeys.p2pNodeId);
    if (id == null || id.isEmpty) {
      id = _generateNodeId();
      await _prefs.setString(StorageKeys.p2pNodeId, id);
    }
    _cachedId = id;
    return id;
  }

  /// Generates + persists both identity fields if missing.
  Future<void> ensureReady() async {
    await getNodeName();
    await getNodeId();
  }

  String _generateNodeName() {
    final random = math.Random.secure();
    final suffix = random.nextInt(0xFFFF).toRadixString(16).toUpperCase().padLeft(4, '0');
    return 'NODE-$suffix';
  }

  String _generateNodeId() {
    final random = math.Random.secure();
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final suffix = random.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return 'node-$time-$suffix';
  }
}
