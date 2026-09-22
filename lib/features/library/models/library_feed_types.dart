class MoveOutcome {
  const MoveOutcome({
    required this.carried,
    required this.dropped,
    required this.bookmarks,
  });

  final int carried;

  final int dropped;
  final int bookmarks;
}

class ChapterSyncItem {
  const ChapterSyncItem({
    required this.url,
    required this.number,
    this.title,
    this.dateUploaded,
    this.scanlator,
  });

  final String url;
  final double? number;
  final String? title;
  final DateTime? dateUploaded;
  final String? scanlator;
}

class UpdateChapterSummary {
  const UpdateChapterSummary({
    required this.libraryEntryId,
    required this.entryTitle,
    required this.entryCoverUrl,
    this.customCoverPath,
    required this.sourceId,
    required this.externalId,
    required this.chapterUrl,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.dateUploaded,
  });

  final int libraryEntryId;
  final String entryTitle;
  final String? entryCoverUrl;
  final String? customCoverPath;
  final String sourceId;
  final String externalId;
  final String chapterUrl;
  final double chapterNumber;
  final String? chapterTitle;
  final DateTime dateUploaded;
}

class ChapterRecord {
  const ChapterRecord({
    required this.url,
    required this.number,
    this.title,
    this.dateUploaded,
    required this.consumed,
    this.consumedAt,
    this.progressPosition,
    this.bookmarked = false,
    this.scanlator,
  });

  final String? scanlator;
  final bool bookmarked;
  final String url;
  final double number;
  final String? title;
  final DateTime? dateUploaded;
  final bool consumed;
  final DateTime? consumedAt;
  final double? progressPosition;
}

class HistoryChapterSummary {
  const HistoryChapterSummary({
    required this.libraryEntryId,
    required this.entryTitle,
    required this.entryCoverUrl,
    this.customCoverPath,
    required this.sourceId,
    required this.externalId,
    required this.chapterUrl,
    required this.chapterNumber,
    required this.chapterTitle,
    required this.consumedAt,
  });

  final int libraryEntryId;
  final String entryTitle;
  final String? entryCoverUrl;
  final String? customCoverPath;
  final String sourceId;
  final String externalId;
  final String chapterUrl;
  final double chapterNumber;
  final String? chapterTitle;
  final DateTime consumedAt;
}
