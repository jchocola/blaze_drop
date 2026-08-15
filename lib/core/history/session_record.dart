import 'package:equatable/equatable.dart';

import 'history_file.dart';

/// A server session (hub active period) with the files that went through it
/// (FUNCTIONALITY.md mock "HISTORY").
class SessionRecord extends Equatable {
  const SessionRecord({
    required this.id,
    required this.startedAt,
    this.endedAt,
    this.files = const [],
  });

  final String id;

  final DateTime startedAt;

  /// Null while the session is still open (server running).
  final DateTime? endedAt;

  final List<HistoryFile> files;

  bool get isActive => endedAt == null;

  SessionRecord copyWith({
    DateTime? endedAt,
    List<HistoryFile>? files,
  }) {
    return SessionRecord(
      id: id,
      startedAt: startedAt,
      endedAt: endedAt ?? this.endedAt,
      files: files ?? this.files,
    );
  }

  /// Serialization for the local persistence layer.
  Map<String, Object?> toJson() => {
    'id': id,
    'startedAt': startedAt.toIso8601String(),
    'endedAt': endedAt?.toIso8601String(),
    'files': files.map((f) => f.toJson()).toList(),
  };

  factory SessionRecord.fromJson(Map<String, dynamic> json) {
    return SessionRecord(
      id: json['id'] as String,
      startedAt: DateTime.parse(json['startedAt'] as String),
      endedAt: json['endedAt'] == null
          ? null
          : DateTime.tryParse(json['endedAt'] as String),
      files: (json['files'] as List<dynamic>? ?? const [])
          .map((f) => HistoryFile.fromJson(f as Map<String, dynamic>))
          .toList(),
    );
  }

  @override
  List<Object?> get props => [id, startedAt, endedAt, files];
}
