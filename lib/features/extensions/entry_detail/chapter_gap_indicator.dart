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
