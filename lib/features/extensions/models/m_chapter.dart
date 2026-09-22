class MChapter {
  const MChapter({
    required this.url,
    required this.title,
    this.number,
    this.dateUploaded,
    this.locked = false,
    this.unlocksAt,
    this.read = false,
    this.progress,
    this.bookmarked = false,
    this.scanlator,
    this.webUrl,
    this.season,
    this.seasonName,
    this.seasonCoverUrl,
  });

  final String? season;

  final String? seasonName;

  final String? seasonCoverUrl;

  MChapter withSeasonOf(MChapter other) => MChapter(
    url: url,
    title: title,
    number: number,
    dateUploaded: dateUploaded,
    locked: locked,
    unlocksAt: unlocksAt,
    read: read,
    progress: progress,
    bookmarked: bookmarked,
    scanlator: scanlator,
    webUrl: webUrl,
    season: other.season,
    seasonName: other.seasonName,
    seasonCoverUrl: other.seasonCoverUrl,
  );

  final String? scanlator;

  final bool bookmarked;

  final String url;

  final String? webUrl;

  final String title;

  final double? number;

  final DateTime? dateUploaded;

  final bool locked;

  final DateTime? unlocksAt;

  final bool read;

  final double? progress;

  bool get isTimeLocked =>
      unlocksAt != null && unlocksAt!.isAfter(DateTime.now());
}
