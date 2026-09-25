import 'package:sumizuri/features/library/models/library_types.dart';

/// The services a title can be tracked on.
enum TrackerKind {
  anilist('anilist', 'AniList'),
  mal('mal', 'MyAnimeList');

  const TrackerKind(this.id, this.label);

  /// Stored on link rows and in secure storage.
  final String id;
  final String label;
}

/// The two lists a tracker keeps. Novels live in the manga list.
enum TrackerMedia { anime, manga }

/// Where a title is on the list, the same six ways on every tracker.
enum TrackerStatus { current, planning, completed, dropped, paused, repeating }

/// A calendar day some trackers keep only in part.
class TrackerDate {
  const TrackerDate({this.year, this.month, this.day});

  final int? year;
  final int? month;
  final int? day;

  bool get isEmpty => year == null && month == null && day == null;

  factory TrackerDate.fromDateTime(DateTime date) =>
      TrackerDate(year: date.year, month: date.month, day: date.day);

  /// 2024-05-03, or 2024-05 or 2024 when the rest is not known.
  static TrackerDate? parse(String? text) {
    if (text == null || text.isEmpty) return null;
    final parts = text.split('-');
    final date = TrackerDate(
      year: int.tryParse(parts[0]),
      month: parts.length > 1 ? int.tryParse(parts[1]) : null,
      day: parts.length > 2 ? int.tryParse(parts[2]) : null,
    );
    return date.isEmpty ? null : date;
  }

  /// 2024-05-03, with what is missing filled in as the first of it.
  String? get iso {
    final y = year;
    if (y == null) return null;
    final m = (month ?? 1).toString().padLeft(2, '0');
    final d = (day ?? 1).toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}

/// Who is connected on a tracker.
class TrackerAccountInfo {
  const TrackerAccountInfo({
    required this.name,
    required this.profileUrl,
    this.avatarUrl,
  });

  final String name;
  final String profileUrl;
  final String? avatarUrl;
}

/// The numbers a tracker shows for one list.
class TrackerKindStats {
  const TrackerKindStats({
    this.count = 0,
    this.meanScore = 0,
    this.unitsDone = 0,
    this.days = 0,
  });

  final int count;

  /// On a scale of 10, 0 when there are no scores.
  final double meanScore;

  /// Episodes watched for anime, chapters read for manga.
  final int unitsDone;

  /// Days of watching. Only anime has it.
  final double days;
}

class TrackerStats {
  const TrackerStats({required this.anime, required this.manga});

  final TrackerKindStats anime;
  final TrackerKindStats manga;
}

/// One title on a tracker's list, whichever tracker it came from.
class TrackerEntry {
  const TrackerEntry({
    required this.tracker,
    required this.mediaId,
    required this.media,
    required this.title,
    this.entryId,
    this.isNovel = false,
    this.coverUrl,
    this.status,
    this.progress = 0,
    this.total,
    this.score = 0,
    this.startedAt,
    this.completedAt,
    this.siteUrl,
    this.synonyms = const [],
  });

  final TrackerKind tracker;

  /// The tracker's id for the title. Anime and manga ids may repeat.
  final int mediaId;

  /// The tracker's id for the list entry, where it has one apart from the title.
  final int? entryId;
  final TrackerMedia media;
  final bool isNovel;
  final String title;
  final String? coverUrl;
  final TrackerStatus? status;

  /// Episodes watched or chapters read.
  final int progress;

  /// Episodes or chapters in all, when known.
  final int? total;

  /// Out of 100, 0 for none.
  final int score;
  final TrackerDate? startedAt;
  final TrackerDate? completedAt;
  final String? siteUrl;
  final List<String> synonyms;

  bool get isAnime => media == TrackerMedia.anime;

  MediaType get libraryType => isAnime
      ? MediaType.anime
      : isNovel
      ? MediaType.novel
      : MediaType.manga;

  /// The key that tells two titles apart across both lists.
  TrackerTitleKey get key => (media, mediaId);
}

/// A title as its own list and id.
typedef TrackerTitleKey = (TrackerMedia media, int mediaId);

/// What to change on an entry. A null field is left as it is, never cleared.
class TrackerEntryUpdate {
  const TrackerEntryUpdate({
    required this.media,
    required this.mediaId,
    this.status,
    this.progress,
    this.score,
    this.startedAt,
    this.completedAt,
  });

  final TrackerMedia media;
  final int mediaId;
  final TrackerStatus? status;
  final int? progress;

  /// Out of 100.
  final int? score;
  final TrackerDate? startedAt;
  final TrackerDate? completedAt;
}

/// What a tracker currently holds for one title, read before sending progress.
class TrackerRemoteState {
  const TrackerRemoteState({this.total, this.entry});

  final int? total;
  final TrackerEntry? entry;
}

enum TrackerFlushOutcome {
  nothingToSend,
  notDueYet,
  noAccount,
  loginExpired,
  postponed,
  sent,
}

class TrackerFlushResult {
  const TrackerFlushResult(this.outcome, {this.sent = 0, this.failed = 0});

  final TrackerFlushOutcome outcome;
  final int sent;
  final int failed;
}

/// A title found by searching a tracker, to link a library entry to.
class TrackerSearchResult {
  const TrackerSearchResult({
    required this.mediaId,
    required this.title,
    this.coverUrl,
    this.subtitle = '',
    this.total,
  });

  final int mediaId;
  final String title;
  final String? coverUrl;

  /// The kind of title and its year, such as "Manga · 2019".
  final String subtitle;

  /// Episodes or chapters in all, when known.
  final int? total;
}
