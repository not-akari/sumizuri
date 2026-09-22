/// The first heading of a guide, or [fallback] when it has none.
String docTitle(String text, String fallback) {
  for (final line in text.split('\n')) {
    if (line.startsWith('# ')) return line.substring(2).trim();
  }
  return fallback;
}

/// The first paragraph under the title, on one line and cut short.
String docSummary(String text) {
  final lines = text.split('\n');
  final buffer = StringBuffer();
  var seenTitle = false;
  for (final line in lines) {
    if (line.startsWith('# ')) {
      seenTitle = true;
      continue;
    }
    if (!seenTitle) continue;
    if (line.trim().isEmpty) {
      if (buffer.isNotEmpty) break;
      continue;
    }
    if (line.startsWith('#') || line.startsWith('```')) break;
    buffer.write('${buffer.isEmpty ? '' : ' '}${line.trim()}');
  }
  final summary = buffer.toString().replaceAll(RegExp(r'[`*]'), '');
  return summary.length > 110 ? '${summary.substring(0, 107)}…' : summary;
}
