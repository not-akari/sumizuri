import 'package:sumizuri/features/trackers/models/tracker_models.dart';

/// MyAnimeList's word for a status on the list of [media].
String malStatusWire(TrackerStatus status, TrackerMedia media) {
  final anime = media == TrackerMedia.anime;
  return switch (status) {
    TrackerStatus.current ||
    TrackerStatus.repeating => anime ? 'watching' : 'reading',
    TrackerStatus.planning => anime ? 'plan_to_watch' : 'plan_to_read',
    TrackerStatus.completed => 'completed',
    TrackerStatus.dropped => 'dropped',
    TrackerStatus.paused => 'on_hold',
  };
}

TrackerStatus? malStatusFrom(String? wire, {required bool repeating}) {
  final status = switch (wire) {
    'watching' || 'reading' => TrackerStatus.current,
    'plan_to_watch' || 'plan_to_read' => TrackerStatus.planning,
    'completed' => TrackerStatus.completed,
    'dropped' => TrackerStatus.dropped,
    'on_hold' => TrackerStatus.paused,
    _ => null,
  };
  return status == TrackerStatus.current && repeating
      ? TrackerStatus.repeating
      : status;
}

const _novelTypes = {'novel', 'light_novel'};

/// The title as MyAnimeList's `node` and `list_status` objects give it.
TrackerEntry malEntryFrom(
  Map<String, dynamic> node,
  Map<String, dynamic>? listStatus, {
  required TrackerMedia media,
}) {
  final anime = media == TrackerMedia.anime;
  final id = (node['id'] as num).toInt();
  final alternative = node['alternative_titles'] as Map<String, dynamic>?;
  final english = alternative?['en'] as String?;
  final japanese = alternative?['ja'] as String?;
  final picture = node['main_picture'] as Map<String, dynamic>?;
  final total = (node[anime ? 'num_episodes' : 'num_chapters'] as num?)
      ?.toInt();
  final repeating =
      (listStatus?[anime ? 'is_rewatching' : 'is_rereading'] as bool?) ?? false;
  final rawTitle = node['title'] as String? ?? '#$id';
  final progress =
      (listStatus?[anime ? 'num_episodes_watched' : 'num_chapters_read']
              as num?)
          ?.toInt() ??
      0;
  return TrackerEntry(
    tracker: TrackerKind.mal,
    mediaId: id,
    media: media,
    isNovel: _novelTypes.contains(node['media_type']),
    title: english != null && english.isNotEmpty ? english : rawTitle,
    coverUrl: (picture?['large'] ?? picture?['medium']) as String?,
    status: malStatusFrom(
      listStatus?['status'] as String?,
      repeating: repeating,
    ),
    progress: progress,
    total: total != null && total > 0 ? total : null,
    // MyAnimeList scores out of 10; the app keeps them out of 100.
    score: ((listStatus?['score'] as num?)?.toInt() ?? 0) * 10,
    startedAt: TrackerDate.parse(listStatus?['start_date'] as String?),
    completedAt: TrackerDate.parse(listStatus?['finish_date'] as String?),
    siteUrl: 'https://myanimelist.net/${anime ? 'anime' : 'manga'}/$id',
    synonyms: [
      rawTitle,
      ?japanese,
      for (final name in (alternative?['synonyms'] as List?) ?? const [])
        if (name is String) name,
    ],
  );
}

/// The form fields that carry [update] to MyAnimeList's `my_list_status`.
Map<String, String> malUpdateFields(TrackerEntryUpdate update) {
  final anime = update.media == TrackerMedia.anime;
  final status = update.status;
  final score = update.score;
  final started = update.startedAt?.iso;
  final completed = update.completedAt?.iso;
  return {
    if (status != null) 'status': malStatusWire(status, update.media),
    if (status != null)
      (anime ? 'is_rewatching' : 'is_rereading'):
          '${status == TrackerStatus.repeating}',
    if (update.progress != null)
      (anime ? 'num_watched_episodes' : 'num_chapters_read'):
          '${update.progress}',
    if (score != null) 'score': '${(score / 10).round().clamp(0, 10)}',
    'start_date': ?started,
    'finish_date': ?completed,
  };
}
