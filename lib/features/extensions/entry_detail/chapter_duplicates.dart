import 'package:sumizuri/features/extensions/models/m_chapter.dart';

/// Whether [a] and [b] are the same chapter listed twice: the same address,
/// or the same season, number and scanlator. A different scanlator's release
/// of a chapter, or the same number in another season, is not a duplicate.
String _identity(MChapter c) => c.number == null
    ? 'url:${c.url}'
    : 'n:${c.season ?? ''}|${c.number}|${c.scanlator ?? ''}';

/// [chapters] with each duplicate dropped, in the order they came. Of a set
/// of duplicates the one you have read, bookmarked, or started is kept in
/// preference to the first listed, so hiding never loses your place.
List<MChapter> withoutDuplicateChapters(List<MChapter> chapters) {
  final keptAt = <String, int>{};
  final seenUrls = <String>{};
  final kept = <MChapter>[];
  bool touched(MChapter c) => c.read || c.bookmarked || c.progress != null;
  for (final chapter in chapters) {
    if (!seenUrls.add(chapter.url)) continue;
    final at = keptAt[_identity(chapter)];
    if (at == null) {
      keptAt[_identity(chapter)] = kept.length;
      kept.add(chapter);
    } else if (!touched(kept[at]) && touched(chapter)) {
      kept[at] = chapter;
    }
  }
  return kept;
}

/// How many chapters in [chapters] are duplicates of another one.
int duplicateChapterCount(List<MChapter> chapters) =>
    chapters.length - withoutDuplicateChapters(chapters).length;
