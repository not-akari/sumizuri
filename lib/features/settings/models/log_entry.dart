enum LogLevel { debug, info, warning, error }

class AppLogEntry {
  const AppLogEntry({
    required this.timestamp,
    required this.level,
    required this.tag,
    required this.message,
    this.stackTrace,
  });

  final DateTime timestamp;
  final LogLevel level;
  final String tag;
  final String message;
  final String? stackTrace;
}
