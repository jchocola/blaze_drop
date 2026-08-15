import 'package:equatable/equatable.dart';

/// What kind of file activity a history entry records.
enum HistoryFileKind {
  /// A guest uploaded a file to the hub (host received it).
  received,

  /// The host published a file into the hub.
  published,

  /// The host downloaded a file from the hub.
  downloaded,
}

/// A single file recorded during a server session (FUNCTIONALITY.md mock
/// "HISTORY").
class HistoryFile extends Equatable {
  const HistoryFile({
    required this.name,
    required this.size,
    required this.kind,
    this.mimeType,
    this.timestamp,
  });

  final String name;

  /// Size in bytes (0 when unknown).
  final int size;

  final HistoryFileKind kind;

  final String? mimeType;

  final DateTime? timestamp;

  HistoryFile copyWith({DateTime? timestamp}) {
    return HistoryFile(
      name: name,
      size: size,
      kind: kind,
      mimeType: mimeType,
      timestamp: timestamp ?? this.timestamp,
    );
  }

  /// Serialization for the local persistence layer.
  Map<String, Object?> toJson() => {
    'name': name,
    'size': size,
    'kind': kind.name,
    'mimeType': mimeType,
    'timestamp': timestamp?.toIso8601String(),
  };

  factory HistoryFile.fromJson(Map<String, dynamic> json) {
    return HistoryFile(
      name: json['name'] as String,
      size: (json['size'] as num?)?.toInt() ?? 0,
      kind: HistoryFileKind.values.firstWhere(
        (k) => k.name == json['kind'],
        orElse: () => HistoryFileKind.received,
      ),
      mimeType: json['mimeType'] as String?,
      timestamp: json['timestamp'] == null
          ? null
          : DateTime.tryParse(json['timestamp'] as String),
    );
  }

  @override
  List<Object?> get props => [name, size, kind, mimeType, timestamp];
}
