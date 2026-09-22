String stripJsonComments(String text) {
  final buffer = StringBuffer();
  var inString = false;
  var i = 0;
  while (i < text.length) {
    final char = text[i];
    if (inString) {
      buffer.write(char);
      if (char == r'\' && i + 1 < text.length) {
        buffer.write(text[i + 1]);
        i += 2;
        continue;
      }
      if (char == '"') inString = false;
      i++;
      continue;
    }
    if (char == '"') {
      inString = true;
      buffer.write(char);
      i++;
      continue;
    }
    if (char == '/' && i + 1 < text.length && text[i + 1] == '/') {
      final end = text.indexOf('\n', i);
      if (end == -1) break;
      i = end;
      continue;
    }
    if (char == '/' && i + 1 < text.length && text[i + 1] == '*') {
      final end = text.indexOf('*/', i + 2);
      if (end == -1) break;
      i = end + 2;
      continue;
    }
    buffer.write(char);
    i++;
  }
  return buffer.toString();
}
