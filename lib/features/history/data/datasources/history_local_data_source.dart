import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/constants/constants.dart';
import '../../../../core/history/session_record.dart';

/// SharedPreferences-backed store for the server-session transfer history.
///
/// Persists a JSON-encoded list of [SessionRecord]s (newest first).
class HistoryLocalDataSource {
  HistoryLocalDataSource(this._prefs);

  final SharedPreferences _prefs;

  Future<List<SessionRecord>> read() async {
    final raw = _prefs.getString(StorageKeys.transferHistory);
    if (raw == null || raw.isEmpty) {
      return const [];
    }
    final decoded = jsonDecode(raw) as List<dynamic>;
    return decoded
        .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> write(List<SessionRecord> sessions) async {
    final raw = jsonEncode(sessions.map((s) => s.toJson()).toList());
    await _prefs.setString(StorageKeys.transferHistory, raw);
  }

  Future<void> clear() async {
    await _prefs.remove(StorageKeys.transferHistory);
  }
}
