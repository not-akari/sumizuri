enum TimeOfDayBucket { morning, afternoon, evening, night }

class TopReadEntry {
  const TopReadEntry({
    required this.libraryEntryId,
    required this.title,
    this.coverUrl,
    this.customCoverPath,
    required this.sourceId,
    required this.externalId,
    required this.chaptersReadCount,
    required this.lastReadAt,
  });

  final int libraryEntryId;
  final String title;
  final String? coverUrl;
  final String? customCoverPath;
  final String sourceId;
  final String externalId;
  final int chaptersReadCount;
  final DateTime lastReadAt;
}

class ReadingStats {
  const ReadingStats({
    required this.totalLibraryEntries,
    required this.totalChaptersRead,
    required this.totalSessions,
    required this.totalActiveDays,
    required this.currentStreak,
    required this.longestStreak,
    required this.chaptersToday,
    required this.chaptersThisWeek,
    required this.chaptersThisMonth,
    required this.mangaCount,
    required this.novelCount,
    required this.animeCount,
    required this.favoriteCount,
    required this.dailyActivity,
    required this.topReadEntries,
    this.firstReadAt,
    this.longestSingleDayCount = 0,
    this.totalUnreadChapters = 0,
    this.totalReReadSessions = 0,
    this.mostActiveWeekday,
    this.mostActiveTimeOfDay,
  });

  final int totalLibraryEntries;
  final int totalChaptersRead;

  final int totalSessions;
  final int totalActiveDays;
  final int currentStreak;
  final int longestStreak;
  final int chaptersToday;
  final int chaptersThisWeek;
  final int chaptersThisMonth;
  final int mangaCount;
  final int novelCount;
  final int animeCount;
  final int favoriteCount;

  final DateTime? firstReadAt;

  final int longestSingleDayCount;

  final Map<DateTime, int> dailyActivity;

  final List<TopReadEntry> topReadEntries;

  final int totalUnreadChapters;

  final int totalReReadSessions;

  final int? mostActiveWeekday;

  final TimeOfDayBucket? mostActiveTimeOfDay;

  double get averageChaptersPerSession =>
      totalSessions == 0 ? 0 : totalChaptersRead / totalSessions;

  double get averageChaptersPerActiveDay =>
      totalActiveDays == 0 ? 0 : totalChaptersRead / totalActiveDays;

  double get averageChaptersPerWeek {
    final start = firstReadAt;
    if (start == null) return 0;
    final daysSinceStart = DateTime.now().difference(start).inDays + 1;
    final weeks = daysSinceStart / 7;
    return totalChaptersRead / (weeks < 1 ? 1 : weeks);
  }

  double? get estimatedWeeksToClearBacklog {
    if (totalUnreadChapters <= 0) return 0;
    final pace = averageChaptersPerWeek;
    if (pace <= 0) return null;
    return totalUnreadChapters / pace;
  }

  static const empty = ReadingStats(
    totalLibraryEntries: 0,
    totalChaptersRead: 0,
    totalSessions: 0,
    totalActiveDays: 0,
    currentStreak: 0,
    longestStreak: 0,
    chaptersToday: 0,
    chaptersThisWeek: 0,
    chaptersThisMonth: 0,
    mangaCount: 0,
    novelCount: 0,
    animeCount: 0,
    favoriteCount: 0,
    dailyActivity: {},
    topReadEntries: [],
  );
}
