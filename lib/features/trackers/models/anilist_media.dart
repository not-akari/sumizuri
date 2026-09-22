enum AniListMediaType {
  manga('MANGA'),
  anime('ANIME');

  const AniListMediaType(this.wire);

  final String wire;

  static AniListMediaType? fromWire(String? value) {
    for (final type in values) {
      if (type.wire == value) return type;
    }
    return null;
  }
}

enum AniListListStatus {
  current('CURRENT'),
  planning('PLANNING'),
  completed('COMPLETED'),
  dropped('DROPPED'),
  paused('PAUSED'),
  repeating('REPEATING');

  const AniListListStatus(this.wire);

  final String wire;

  static AniListListStatus? fromWire(String? value) {
    for (final status in values) {
      if (status.wire == value) return status;
    }
    return null;
  }
}

class AniListFuzzyDate {
  const AniListFuzzyDate({this.year, this.month, this.day});

  final int? year;
  final int? month;
  final int? day;

  bool get isEmpty => year == null && month == null && day == null;

  factory AniListFuzzyDate.fromDateTime(DateTime date) =>
      AniListFuzzyDate(year: date.year, month: date.month, day: date.day);

  static AniListFuzzyDate? fromJson(Object? json) {
    if (json is! Map<String, dynamic>) return null;
    final date = AniListFuzzyDate(
      year: json['year'] as int?,
      month: json['month'] as int?,
      day: json['day'] as int?,
    );
    return date.isEmpty ? null : date;
  }

  Map<String, dynamic> toJson() => {
    if (year != null) 'year': year,
    if (month != null) 'month': month,
    if (day != null) 'day': day,
  };
}

class AniListTitle {
  const AniListTitle({this.romaji, this.english, this.native});

  final String? romaji;
  final String? english;
  final String? native;

  String get display => english ?? romaji ?? native ?? '';
}

class AniListMedia {
  const AniListMedia({
    required this.id,
    required this.type,
    required this.title,
    this.format,
    this.status,
    this.coverUrl,
    this.chapters,
    this.volumes,
    this.episodes,
    this.startYear,
    this.siteUrl,
    this.isAdult = false,
    this.synonyms = const [],
    this.entry,
  });

  final int id;
  final AniListMediaType type;
  final AniListTitle title;

  final String? format;

  final String? status;
  final String? coverUrl;
  final int? chapters;
  final int? volumes;
  final int? episodes;
  final int? startYear;
  final String? siteUrl;
  final bool isAdult;
  final List<String> synonyms;

  final AniListListEntry? entry;

  bool get isNovel => format == 'NOVEL';

  factory AniListMedia.fromJson(Map<String, dynamic> json) {
    final title = json['title'] as Map<String, dynamic>? ?? const {};
    final cover = json['coverImage'] as Map<String, dynamic>?;
    final start = json['startDate'] as Map<String, dynamic>?;
    final entry = json['mediaListEntry'];
    return AniListMedia(
      id: json['id'] as int,
      type:
          AniListMediaType.fromWire(json['type'] as String?) ??
          AniListMediaType.manga,
      title: AniListTitle(
        romaji: title['romaji'] as String?,
        english: title['english'] as String?,
        native: title['native'] as String?,
      ),
      format: json['format'] as String?,
      status: json['status'] as String?,
      coverUrl: (cover?['large'] ?? cover?['medium']) as String?,
      chapters: json['chapters'] as int?,
      volumes: json['volumes'] as int?,
      episodes: json['episodes'] as int?,
      startYear: start?['year'] as int?,
      siteUrl: json['siteUrl'] as String?,
      isAdult: json['isAdult'] as bool? ?? false,
      synonyms: [
        for (final name in (json['synonyms'] as List?) ?? const [])
          if (name is String) name,
      ],
      entry: entry is Map<String, dynamic>
          ? AniListListEntry.fromJson(entry)
          : null,
    );
  }
}

class AniListListEntry {
  const AniListListEntry({
    required this.id,
    required this.mediaId,
    this.status,
    this.progress = 0,
    this.progressVolumes,
    this.score = 0,
    this.repeat = 0,
    this.startedAt,
    this.completedAt,
    this.updatedAt,
    this.media,
  });

  final int id;
  final int mediaId;
  final AniListListStatus? status;

  final int progress;
  final int? progressVolumes;

  final int score;
  final int repeat;
  final AniListFuzzyDate? startedAt;
  final AniListFuzzyDate? completedAt;

  final int? updatedAt;

  final AniListMedia? media;

  factory AniListListEntry.fromJson(Map<String, dynamic> json) {
    final media = json['media'];
    return AniListListEntry(
      id: json['id'] as int,
      mediaId: (json['mediaId'] ?? (media as Map?)?['id']) as int,
      status: AniListListStatus.fromWire(json['status'] as String?),
      progress: json['progress'] as int? ?? 0,
      progressVolumes: json['progressVolumes'] as int?,
      score: (json['score'] as num?)?.round() ?? 0,
      repeat: json['repeat'] as int? ?? 0,
      startedAt: AniListFuzzyDate.fromJson(json['startedAt']),
      completedAt: AniListFuzzyDate.fromJson(json['completedAt']),
      updatedAt: json['updatedAt'] as int?,
      media: media is Map<String, dynamic> && media['title'] != null
          ? AniListMedia.fromJson(media)
          : null,
    );
  }
}

/// What to change on an entry. A null field is left as it is on AniList, never cleared.
class AniListEntryUpdate {
  const AniListEntryUpdate({
    required this.mediaId,
    this.status,
    this.progress,
    this.progressVolumes,
    this.score,
    this.repeat,
    this.startedAt,
    this.completedAt,
  });

  final int mediaId;
  final AniListListStatus? status;
  final int? progress;
  final int? progressVolumes;

  final int? score;
  final int? repeat;
  final AniListFuzzyDate? startedAt;
  final AniListFuzzyDate? completedAt;

  AniListEntryUpdate mergedWith(AniListEntryUpdate newer) => AniListEntryUpdate(
    mediaId: mediaId,
    status: newer.status ?? status,
    progress: newer.progress ?? progress,
    progressVolumes: newer.progressVolumes ?? progressVolumes,
    score: newer.score ?? score,
    repeat: newer.repeat ?? repeat,
    startedAt: newer.startedAt ?? startedAt,
    completedAt: newer.completedAt ?? completedAt,
  );
}

class AniListSearchPage {
  const AniListSearchPage({required this.results, required this.hasNextPage});

  final List<AniListMedia> results;
  final bool hasNextPage;
}

class AniListListPage {
  const AniListListPage({required this.entries, required this.hasNextChunk});

  final List<AniListListEntry> entries;
  final bool hasNextChunk;
}

class AniListRemoteState {
  const AniListRemoteState({required this.mediaId, this.chapters, this.entry});

  final int mediaId;
  final int? chapters;
  final AniListListEntry? entry;
}

class AniListBatchSave {
  const AniListBatchSave({required this.saved, required this.failed});

  final Map<int, AniListListEntry> saved;
  final Map<int, String> failed;
}
