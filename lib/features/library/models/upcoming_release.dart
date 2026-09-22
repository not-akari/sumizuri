enum ReleaseKind { actual, predicted }

class UpcomingRelease {
  const UpcomingRelease({
    required this.libraryEntryId,
    required this.entryTitle,
    required this.entryCoverUrl,
    this.customCoverPath,
    required this.sourceId,
    required this.externalId,
    required this.date,
    required this.kind,
    this.chapterNumber,
  });

  final int libraryEntryId;
  final String entryTitle;
  final String? entryCoverUrl;
  final String? customCoverPath;
  final String sourceId;
  final String externalId;

  final DateTime date;
  final ReleaseKind kind;

  final double? chapterNumber;
}
