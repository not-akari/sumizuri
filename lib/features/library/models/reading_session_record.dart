class ReadingSessionRecord {
  const ReadingSessionRecord({
    required this.id,
    required this.libraryEntryId,
    required this.entryTitle,
    required this.entryCoverUrl,
    this.customCoverPath,
    required this.sourceId,
    required this.externalId,
    required this.contentUnitId,
    required this.chapterUrl,
    required this.chapterNumber,
    this.chapterTitle,
    this.branchId,
    required this.readAt,
  });

  final int id;
  final int libraryEntryId;
  final int? branchId;
  final String entryTitle;
  final String? entryCoverUrl;
  final String? customCoverPath;
  final String sourceId;
  final String externalId;
  final int contentUnitId;
  final String chapterUrl;
  final double chapterNumber;
  final String? chapterTitle;
  final DateTime readAt;
}

class ReadingTimelineBurst {
  const ReadingTimelineBurst({
    required this.libraryEntryId,
    required this.entryTitle,
    required this.entryCoverUrl,
    this.customCoverPath,
    required this.sourceId,
    required this.externalId,
    required this.date,
    required this.isReRead,
    required this.chapterNumbers,
    required this.lastReadAt,
    this.latestChapterUrl,
    this.latestChapterTitle,
  });

  final int libraryEntryId;
  final String entryTitle;
  final String? entryCoverUrl;
  final String? customCoverPath;
  final String sourceId;
  final String externalId;
  final DateTime date;
  final bool isReRead;
  final List<double> chapterNumbers;
  final DateTime lastReadAt;
  final String? latestChapterUrl;
  final String? latestChapterTitle;

  double get minChapter => chapterNumbers.isEmpty
      ? 0
      : chapterNumbers.reduce((a, b) => a < b ? a : b);
  double get maxChapter => chapterNumbers.isEmpty
      ? 0
      : chapterNumbers.reduce((a, b) => a > b ? a : b);
  bool get isSingleChapter =>
      chapterNumbers.length <= 1 || minChapter == maxChapter;
}
