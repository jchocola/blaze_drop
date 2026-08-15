/// Raised when a P2P operation fails (RULE.md §8.1).
///
/// Wraps user-presentable messages for networking failures, declined
/// handshakes and mid-transfer errors.
class PeerTransferException implements Exception {
  const PeerTransferException(this.message);

  final String message;

  @override
  String toString() => message;
}
