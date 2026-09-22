import 'package:sumizuri/features/library/models/library_entry_summary.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/features/library/models/reading_timeline_helper.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';

abstract final class ReadingStatsCalculator {
  static ReadingStats calculate({
    required List<ReadingSessionRecord> sessions,
    required List<LibraryEntrySummary> entries,
    DateTime? now,
  }) {
    if (sessions.isEmpty && entries.isEmpty) {
      return ReadingStats.empty;
    }

    final refNow = now ?? DateTime.now();
    final today = DateTime(refNow.year, refNow.month, refNow.day);
    final sevenDaysAgo = today.subtract(const Duration(days: 6));
    final thirtyDaysAgo = today.subtract(const Duration(days: 29));

    final dailyActivity = <DateTime, int>{};
    final entryReadCounts = <int, int>{};
    final entryLatestReadAt = <int, DateTime>{};
    final sessionMetadata = <int, ReadingSessionRecord>{};
    final weekdayCounts = <int, int>{};
    final timeOfDayCounts = <TimeOfDayBucket, int>{};

    for (final s in sessions) {
      final day = DateTime(s.readAt.year, s.readAt.month, s.readAt.day);
      dailyActivity[day] = (dailyActivity[day] ?? 0) + 1;

      entryReadCounts[s.libraryEntryId] =
          (entryReadCounts[s.libraryEntryId] ?? 0) + 1;
      final prevDate = entryLatestReadAt[s.libraryEntryId];
      if (prevDate == null || s.readAt.isAfter(prevDate)) {
        entryLatestReadAt[s.libraryEntryId] = s.readAt;
        sessionMetadata[s.libraryEntryId] = s;
      }

      weekdayCounts[s.readAt.weekday] =
          (weekdayCounts[s.readAt.weekday] ?? 0) + 1;
      final bucket = _timeOfDayBucket(s.readAt.hour);
      timeOfDayCounts[bucket] = (timeOfDayCounts[bucket] ?? 0) + 1;
    }

    int? mostActiveWeekday;
    if (weekdayCounts.isNotEmpty) {
      mostActiveWeekday = weekdayCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }
    TimeOfDayBucket? mostActiveTimeOfDay;
    if (timeOfDayCounts.isNotEmpty) {
      mostActiveTimeOfDay = timeOfDayCounts.entries
          .reduce((a, b) => a.value >= b.value ? a : b)
          .key;
    }

    final chaptersToday = dailyActivity[today] ?? 0;
    var chaptersThisWeek = 0;
    var chaptersThisMonth = 0;

    for (final entry in dailyActivity.entries) {
      final d = entry.key;
      final count = entry.value;
      if (!d.isBefore(sevenDaysAgo) && !d.isAfter(today)) {
        chaptersThisWeek += count;
      }
      if (!d.isBefore(thirtyDaysAgo) && !d.isAfter(today)) {
        chaptersThisMonth += count;
      }
    }

    final activeDays = dailyActivity.keys.toList()..sort();
    final activeSet = activeDays.toSet();
    final yesterday = today.subtract(const Duration(days: 1));

    int currentStreak = 0;
    final checkDay = activeSet.contains(today)
        ? today
        : (activeSet.contains(yesterday) ? yesterday : null);

    if (checkDay != null) {
      var cur = checkDay;
      while (activeSet.contains(cur)) {
        currentStreak++;
        cur = cur.subtract(const Duration(days: 1));
      }
    }

    int longestStreak = 0;
    if (activeDays.isNotEmpty) {
      longestStreak = 1;
      int run = 1;
      for (int i = 1; i < activeDays.length; i++) {
        final diff = activeDays[i].difference(activeDays[i - 1]).inDays;
        if (diff == 1) {
          run++;
          if (run > longestStreak) longestStreak = run;
        } else {
          run = 1;
        }
      }
    }

    final bursts = groupSessionsIntoBursts(sessions);
    final totalSessions = bursts.length;
    final totalReReadSessions = bursts.where((b) => b.isReRead).length;
    final firstReadAt = sessions.isEmpty
        ? null
        : sessions.map((s) => s.readAt).reduce((a, b) => a.isBefore(b) ? a : b);
    final longestSingleDayCount = dailyActivity.values.isEmpty
        ? 0
        : dailyActivity.values.reduce((a, b) => a > b ? a : b);

    var mangaCount = 0;
    var novelCount = 0;
    var animeCount = 0;
    var favoriteCount = 0;
    var totalUnreadChapters = 0;
    final entryById = <int, LibraryEntrySummary>{};

    for (final entry in entries) {
      entryById[entry.id] = entry;
      totalUnreadChapters += entry.unreadCount;
      switch (entry.mediaType) {
        case MediaType.manga:
          mangaCount++;
        case MediaType.novel:
          novelCount++;
        case MediaType.anime:
          animeCount++;
      }
      if (entry.favorite) {
        favoriteCount++;
      }
    }

    final sortedEntryIds = entryReadCounts.keys.toList()
      ..sort((a, b) {
        final cmp = entryReadCounts[b]!.compareTo(entryReadCounts[a]!);
        if (cmp != 0) return cmp;
        return entryLatestReadAt[b]!.compareTo(entryLatestReadAt[a]!);
      });

    final topReadEntries = <TopReadEntry>[];
    for (final id in sortedEntryIds.take(5)) {
      final summary = entryById[id];
      final meta = sessionMetadata[id];
      if (meta == null) continue;

      topReadEntries.add(
        TopReadEntry(
          libraryEntryId: id,
          title: summary?.title ?? meta.entryTitle,
          coverUrl: summary?.coverUrl ?? meta.entryCoverUrl,
          customCoverPath: summary?.customCoverPath ?? meta.customCoverPath,
          sourceId: summary?.sourceId ?? meta.sourceId,
          externalId: summary?.externalId ?? meta.externalId,
          chaptersReadCount: entryReadCounts[id] ?? 0,
          lastReadAt: entryLatestReadAt[id] ?? meta.readAt,
        ),
      );
    }

    return ReadingStats(
      totalLibraryEntries: entries.length,
      totalChaptersRead: sessions.length,
      totalSessions: totalSessions,
      totalActiveDays: dailyActivity.length,
      currentStreak: currentStreak,
      longestStreak: longestStreak,
      chaptersToday: chaptersToday,
      chaptersThisWeek: chaptersThisWeek,
      chaptersThisMonth: chaptersThisMonth,
      mangaCount: mangaCount,
      novelCount: novelCount,
      animeCount: animeCount,
      favoriteCount: favoriteCount,
      dailyActivity: dailyActivity,
      topReadEntries: topReadEntries,
      firstReadAt: firstReadAt,
      longestSingleDayCount: longestSingleDayCount,
      totalUnreadChapters: totalUnreadChapters,
      totalReReadSessions: totalReReadSessions,
      mostActiveWeekday: mostActiveWeekday,
      mostActiveTimeOfDay: mostActiveTimeOfDay,
    );
  }

  static TimeOfDayBucket _timeOfDayBucket(int hour) {
    if (hour >= 5 && hour < 12) return TimeOfDayBucket.morning;
    if (hour >= 12 && hour < 17) return TimeOfDayBucket.afternoon;
    if (hour >= 17 && hour < 21) return TimeOfDayBucket.evening;
    return TimeOfDayBucket.night;
  }
}
