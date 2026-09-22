class KnownChapter {
  const KnownChapter({
    required this.id,
    required this.url,
    required this.number,
    required this.title,
  });

  final int id;
  final String url;
  final double number;
  final String? title;
}

class ListedChapter {
  const ListedChapter({
    required this.url,
    required this.number,
    required this.title,
  });

  final String url;
  final double number;
  final String? title;
}

class ReconcilePlan {
  const ReconcilePlan({this.renames = const {}, this.merges = const {}});

  final Map<int, String> renames;

  final Map<int, int> merges;

  bool get isEmpty => renames.isEmpty && merges.isEmpty;
}

ReconcilePlan planReconcile({
  required List<KnownChapter> saved,
  required List<ListedChapter> listed,
}) {
  final listedUrls = {for (final chapter in listed) chapter.url};
  final savedByUrl = {for (final chapter in saved) chapter.url: chapter};

  // Saved chapters the list no longer contains under their address.
  final orphans = [
    for (final chapter in saved)
      if (!listedUrls.contains(chapter.url) && _key(chapter) != null) chapter,
  ];
  if (orphans.isEmpty) return const ReconcilePlan();

  final claimed = <int>{};
  final renames = <int, String>{};
  final merges = <int, int>{};

  for (final chapter in listed) {
    if (savedByUrl.containsKey(chapter.url)) continue;
    final key = _key(chapter);
    if (key == null) continue;
    for (final orphan in orphans) {
      if (claimed.contains(orphan.id) || _key(orphan) != key) continue;
      renames[orphan.id] = chapter.url;
      claimed.add(orphan.id);
      break;
    }
  }

  final currentByKey = <String, KnownChapter>{};
  for (final chapter in saved) {
    final key = _key(chapter);
    if (key != null && listedUrls.contains(chapter.url)) {
      currentByKey.putIfAbsent(key, () => chapter);
    }
  }
  for (final orphan in orphans) {
    if (claimed.contains(orphan.id)) continue;
    final keep = currentByKey[_key(orphan)];
    if (keep != null) merges[orphan.id] = keep.id;
  }

  return ReconcilePlan(renames: renames, merges: merges);
}

String? _key(Object chapter) {
  final (number, title) = switch (chapter) {
    KnownChapter(:final number, :final title) => (number, title),
    ListedChapter(:final number, :final title) => (number, title),
    _ => (0.0, null),
  };
  final text = title?.trim().toLowerCase();
  if (text == null || text.isEmpty) return null;
  return '$number|$text';
}
