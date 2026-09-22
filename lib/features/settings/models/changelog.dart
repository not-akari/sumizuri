class ChangelogSection {
  const ChangelogSection(this.title, this.body);

  final String title;
  final String body;
}

List<ChangelogSection> parseChangelog(String text) {
  final sections = <ChangelogSection>[];
  String? title;
  final body = StringBuffer();
  void flush() {
    final current = title;
    if (current != null) {
      sections.add(ChangelogSection(current, body.toString()));
    }
    body.clear();
  }

  for (final line in text.split('\n')) {
    if (line.startsWith('## ')) {
      flush();
      title = line.substring(3).trim();
    } else if (title != null) {
      body.writeln(line);
    }
  }
  flush();
  return sections;
}
