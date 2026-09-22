/// What AniList says about one kind of title on the account.
class AniListKindStats {
  const AniListKindStats({
    this.count = 0,
    this.meanScore = 0,
    this.unitsDone = 0,
    this.minutesWatched = 0,
  });

  final int count;
  final double meanScore;

  /// Episodes watched for anime, chapters read for manga.
  final int unitsDone;

  /// Only anime has a watch time.
  final int minutesWatched;

  double get daysWatched => minutesWatched / 1440;

  factory AniListKindStats.fromJson(Object? json, {required bool anime}) {
    if (json is! Map<String, dynamic>) return const AniListKindStats();
    return AniListKindStats(
      count: (json['count'] as num?)?.toInt() ?? 0,
      meanScore: (json['meanScore'] as num?)?.toDouble() ?? 0,
      unitsDone:
          (json[anime ? 'episodesWatched' : 'chaptersRead'] as num?)?.toInt() ??
          0,
      minutesWatched: (json['minutesWatched'] as num?)?.toInt() ?? 0,
    );
  }
}

class AniListStats {
  const AniListStats({required this.anime, required this.manga});

  final AniListKindStats anime;
  final AniListKindStats manga;

  factory AniListStats.fromJson(Map<String, dynamic> viewer) {
    final statistics = viewer['statistics'];
    final map = statistics is Map<String, dynamic> ? statistics : const {};
    return AniListStats(
      anime: AniListKindStats.fromJson(map['anime'], anime: true),
      manga: AniListKindStats.fromJson(map['manga'], anime: false),
    );
  }
}
