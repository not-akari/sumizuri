import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/upcoming_release.dart';

abstract final class UpcomingReleasesCalculator {
  static const _minHistoryForPrediction = 3;

  static List<UpcomingRelease> calculate(
    List<UpdateChapterSummary> chapters, {
    DateTime? now,
  }) {
    final today = _dateOnly(now ?? DateTime.now());
    final byEntry = <int, List<UpdateChapterSummary>>{};
    for (final c in chapters) {
      byEntry.putIfAbsent(c.libraryEntryId, () => []).add(c);
    }

    final releases = <UpcomingRelease>[];
    for (final group in byEntry.values) {
      final sorted = [...group]
        ..sort((a, b) => a.dateUploaded.compareTo(b.dateUploaded));

      for (final c in sorted) {
        releases.add(
          UpcomingRelease(
            libraryEntryId: c.libraryEntryId,
            entryTitle: c.entryTitle,
            entryCoverUrl: c.entryCoverUrl,
            customCoverPath: c.customCoverPath,
            sourceId: c.sourceId,
            externalId: c.externalId,
            date: _dateOnly(c.dateUploaded),
            kind: ReleaseKind.actual,
            chapterNumber: c.chapterNumber,
          ),
        );
      }

      final predicted = _predictNext(sorted, today);
      if (predicted != null) releases.add(predicted);
    }

    return releases;
  }

  static UpcomingRelease? _predictNext(
    List<UpdateChapterSummary> sorted,
    DateTime today,
  ) {
    final distinctDays =
        sorted.map((c) => _dateOnly(c.dateUploaded)).toSet().toList()..sort();
    if (distinctDays.length < _minHistoryForPrediction) return null;

    final gaps = <int>[];
    for (var i = 1; i < distinctDays.length; i++) {
      gaps.add(distinctDays[i].difference(distinctDays[i - 1]).inDays);
    }
    final recentGaps = gaps.length > 6 ? gaps.sublist(gaps.length - 6) : gaps;
    recentGaps.sort();
    final medianGap = recentGaps[recentGaps.length ~/ 2];
    if (medianGap <= 0) return null;

    var nextDate = distinctDays.last.add(Duration(days: medianGap));
    while (!nextDate.isAfter(today)) {
      nextDate = nextDate.add(Duration(days: medianGap));
    }

    final latest = sorted.last;
    return UpcomingRelease(
      libraryEntryId: latest.libraryEntryId,
      entryTitle: latest.entryTitle,
      entryCoverUrl: latest.entryCoverUrl,
      customCoverPath: latest.customCoverPath,
      sourceId: latest.sourceId,
      externalId: latest.externalId,
      date: nextDate,
      kind: ReleaseKind.predicted,
    );
  }

  static DateTime _dateOnly(DateTime dt) => DateTime(dt.year, dt.month, dt.day);
}
