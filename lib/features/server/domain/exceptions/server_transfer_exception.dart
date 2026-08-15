/// Raised when a Server Mode operation fails (RULE.md §8.1).
///
/// Wraps user-presentable messages for bind failures, port conflicts,
/// mid-upload disconnects and storage errors.
class ServerTransferException implements Exception {
  const ServerTransferException(this.message);

  final String message;

  @override
  String toString() => message;
}
