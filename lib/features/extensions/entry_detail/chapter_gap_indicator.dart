import 'package:flutter/material.dart';

import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

List<int> missingChapterNumbers(List<MChapter> chapters) {
  final present = <int>{};
  var highest = 0;
  for (final chapter in chapters) {
    final number = chapter.number;
    if (number == null || number != number.roundToDouble()) continue;
    final n = number.round();
    present.add(n);
    if (n > highest) highest = n;
  }
  return [
    for (var n = 1; n < highest; n++)
      if (!present.contains(n)) n,
  ];
}

String formatMissingChapterRanges(List<int> missing) {
  if (missing.isEmpty) return '';
  final parts = <String>[];
  var start = missing.first;
  var end = missing.first;
  for (final n in missing.skip(1)) {
    if (n == end + 1) {
      end = n;
      continue;
    }
    parts.add(start == end ? '$start' : '$start-$end');
    start = n;
    end = n;
  }
  parts.add(start == end ? '$start' : '$start-$end');
  return parts.join(', ');
}

Widget? missingChaptersSummarySliver(
  BuildContext context,
  AppLocalizations l10n,
  List<MChapter> chapters,
) {
  final missing = missingChapterNumbers(chapters);
  if (missing.isEmpty) return null;
  final cs = Theme.of(context).colorScheme;
  return SliverToBoxAdapter(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.warning_amber_rounded, size: 15, color: cs.error),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${l10n.chapterListMissingChapters(missing.length)}: '
              '${formatMissingChapterRanges(missing)}',
              style: Theme.of(context).textTheme.bodySmall
                  ?.copyWith(color: cs.error),
            ),
          ),
        ],
      ),
    ),
  );
}

/// The whole-number chapters in [missing] that fall strictly between [a] and
/// [b], in either order, so a marker can sit at the exact spot in the list
/// where the break is. Empty when either has no number.
List<int> missingBetween(MChapter a, MChapter b, Set<int> missing) {
  final x = a.number;
  final y = b.number;
  if (x == null || y == null) return const [];
  final lo = x < y ? x : y;
  final hi = x < y ? y : x;
  return [
    for (var n = lo.floor() + 1; n < hi; n++)
      if (n > lo && missing.contains(n)) n,
  ];
}

/// Where the breaks in a chapter list are: [after] holds, for each chapter,
/// the missing whole numbers between it and the next one in the list, and
/// [before] the ones missing ahead of the very first chapter.
typedef ChapterGaps = ({List<List<int>> after, List<int> before});

/// The gaps between chapters, plus the run missing below the lowest chapter
/// the source gave us (a source that lists only its latest 200 of 3,000
/// leaves 1 through 2,800 unaccounted for, at the far end of the list).
ChapterGaps chapterGaps(List<MChapter> chapters) {
  final missing = missingChapterNumbers(chapters).toSet();
  final after = [
    for (var i = 0; i < chapters.length; i++)
      if (missing.isEmpty || i == chapters.length - 1)
        const <int>[]
      else
        missingBetween(chapters[i], chapters[i + 1], missing),
  ];
  var before = const <int>[];
  final first = chapters.isEmpty ? null : chapters.first.number;
  final last = chapters.isEmpty ? null : chapters.last.number;
  if (missing.isNotEmpty && first != null && last != null) {
    final lowest = first < last ? first : last;
    final tail = [
      for (final n in missing)
        if (n < lowest) n,
    ]..sort();
    if (tail.isNotEmpty) {
      if (first > last) {
        // Newest first: the low numbers fall off the bottom of the list.
        after[after.length - 1] = tail;
      } else {
        before = tail;
      }
    }
  }
  return (after: after, before: before);
}

/// A break in the chapter list, shown between the two chapters it falls
/// between: a line, what is missing, a line.
class ChapterGapMarker extends StatelessWidget {
  const ChapterGapMarker({super.key, required this.missing});

  final List<int> missing;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final line = Expanded(
      child: Divider(
        height: 1,
        thickness: 1,
        color: cs.error.withValues(alpha: 0.35),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          line,
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.warning_amber_rounded, size: 14, color: cs.error),
                const SizedBox(width: 4),
                Text(
                  l10n.chapterListGapInline(
                    formatMissingChapterRanges(missing),
                  ),
                  style: Theme.of(context).textTheme.labelSmall
                      ?.copyWith(color: cs.error),
                ),
              ],
            ),
          ),
          line,
        ],
      ),
    );
  }
}
