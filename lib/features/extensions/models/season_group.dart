import 'package:sumizuri/features/extensions/models/m_chapter.dart';

class SeasonGroup {
  const SeasonGroup({
    required this.key,
    required this.name,
    required this.coverUrl,
    required this.chapters,
  });

  final String? key;

  final String? name;

  final String? coverUrl;

  final List<MChapter> chapters;
}

List<SeasonGroup> groupSeasons(List<MChapter> chapters) {
  final byKey = <String?, List<MChapter>>{};
  for (final chapter in chapters) {
    byKey.putIfAbsent(chapter.season, () => []).add(chapter);
  }
  if (byKey.length < 2) return const [];

  final keys = byKey.keys.toList();
  final numbered = keys.where((k) => k != null && _number(k) != null).toList()
    ..sort((a, b) => _number(a!)!.compareTo(_number(b!)!));
  final named = keys.where((k) => k != null && _number(k) == null);
  final ordered = [...numbered, ...named, if (byKey.containsKey(null)) null];

  return [
    for (final key in ordered)
      SeasonGroup(
        key: key,
        name: byKey[key]!
            .map((c) => c.seasonName)
            .whereType<String>()
            .firstOrNull,
        coverUrl: byKey[key]!
            .map((c) => c.seasonCoverUrl)
            .whereType<String>()
            .firstOrNull,
        chapters: byKey[key]!,
      ),
  ];
}

List<MChapter> withSeasonsFrom(
  List<MChapter> stored,
  List<MChapter> fromSource,
) {
  final bySourceUrl = {for (final chapter in fromSource) chapter.url: chapter};
  return [
    for (final chapter in stored)
      if (bySourceUrl[chapter.url] case final source?
          when source.season != null)
        chapter.withSeasonOf(source)
      else
        chapter,
  ];
}

double? _number(String key) => double.tryParse(key);
