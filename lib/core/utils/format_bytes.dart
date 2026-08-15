/// Formats [bytes] into a compact binary-size label (`B`, `KB`, `MB`, `GB`).
///
/// Shared by the server feature (upload log, storage list). Kept in `core`
/// so features don't depend on each other's helpers (RULE.md §1.2).
String formatBytes(int bytes) {
  if (bytes < 1024) {
    return '$bytes B';
  }
  const units = <String>['KB', 'MB', 'GB', 'TB'];
  var value = bytes.toDouble();
  var unit = -1;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final text =
      value >= 100 ? value.toStringAsFixed(0) : value.toStringAsFixed(1);
  return '$text ${units[unit]}';
}
