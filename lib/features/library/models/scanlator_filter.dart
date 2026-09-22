import 'dart:convert';

List<String> decodeScanlatorList(String? stored) {
  if (stored == null || stored.isEmpty) return const [];
  try {
    final decoded = jsonDecode(stored);
    if (decoded is List) {
      return [
        for (final v in decoded)
          if (v is String) v,
      ];
    }
  } on FormatException {
    // Fall through to none: a bad value must never hide chapters.
  }
  return const [];
}

String? encodeScanlatorList(List<String> names) {
  final clean = {
    for (final n in names)
      if (n.trim().isNotEmpty) n,
  }.toList()..sort();
  return clean.isEmpty ? null : jsonEncode(clean);
}

List<String> scanlatorsOf<T>(
  List<T> chapters,
  String? Function(T) scanlatorOf,
) {
  final counts = <String, int>{};
  for (final chapter in chapters) {
    final name = scanlatorOf(chapter);
    if (name != null && name.isNotEmpty) counts[name] = (counts[name] ?? 0) + 1;
  }
  final names = counts.keys.toList()
    ..sort(
      (a, b) => counts[b]!.compareTo(counts[a]!) != 0
          ? counts[b]!.compareTo(counts[a]!)
          : a.compareTo(b),
    );
  return names;
}

/// Chapters without the excluded scanlators. A chapter with no scanlator is never hidden.
List<T> withoutScanlators<T>(
  List<T> chapters,
  Set<String> excluded,
  String? Function(T) scanlatorOf,
) {
  if (excluded.isEmpty) return chapters;
  return [
    for (final chapter in chapters)
      if (!excluded.contains(scanlatorOf(chapter))) chapter,
  ];
}
