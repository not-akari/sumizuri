/// Formats a countdown as e.g. "2h 05m", "3m 12s", or "8s". Not localized:
/// it's digits and unit letters, not prose.
String formatEta(Duration d) {
  final hours = d.inHours;
  final minutes = d.inMinutes % 60;
  final seconds = d.inSeconds % 60;
  if (hours > 0) {
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m';
  }
  if (minutes > 0) {
    return '${minutes}m ${seconds.toString().padLeft(2, '0')}s';
  }
  return '${seconds}s';
}
