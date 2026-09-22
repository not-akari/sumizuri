import 'package:sumizuri/features/trackers/models/anilist_media.dart';

AniListEntryUpdate? planAniListUpdate({
  required int mediaId,
  required int localProgress,
  required AniListRemoteState? remote,
  required DateTime today,
}) {
  if (localProgress <= 0) return null;
  final total = remote?.chapters;
  final capped = (total != null && total > 0 && localProgress > total)
      ? total
      : localProgress;
  final finished = total != null && total > 0 && capped >= total;
  final date = AniListFuzzyDate.fromDateTime(today);
  final entry = remote?.entry;

  if (entry == null) {
    return AniListEntryUpdate(
      mediaId: mediaId,
      status: finished
          ? AniListListStatus.completed
          : AniListListStatus.current,
      progress: capped,
      startedAt: date,
      completedAt: finished ? date : null,
    );
  }

  if (entry.status == AniListListStatus.completed ||
      entry.status == AniListListStatus.repeating) {
    return null;
  }

  if (capped <= entry.progress) return null;
  final progress = capped;
  final done = total != null && total > 0 && progress >= total;

  AniListListStatus? status;
  if (done) {
    status = AniListListStatus.completed;
  } else if (entry.status != AniListListStatus.current) {
    status = AniListListStatus.current;
  }

  final startedAt = entry.startedAt == null ? date : null;
  final completedAt = done && entry.completedAt == null ? date : null;

  return AniListEntryUpdate(
    mediaId: mediaId,
    status: status,
    progress: progress,
    startedAt: startedAt,
    completedAt: completedAt,
  );
}
