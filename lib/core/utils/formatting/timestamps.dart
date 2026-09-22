/// A time safe to put in a file name, such as 2026-09-20T10-15-30-123.
String fileStamp([DateTime? at]) =>
    (at ?? DateTime.now()).toIso8601String().replaceAll(RegExp('[:.]'), '-');

String _two(int n) => n.toString().padLeft(2, '0');

/// The time of day, such as 10:15:30.
String timeStamp(DateTime t) =>
    '${_two(t.hour)}:${_two(t.minute)}:${_two(t.second)}';

/// A date and time for a line of text, such as 2026-09-20 10:15:30.
String clockStamp(DateTime t) =>
    '${t.year}-${_two(t.month)}-${_two(t.day)} ${timeStamp(t)}';
