import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';

/// What to do about one linked title, given how far each side says it is.
enum ProgressAction {
  /// The tracker is ahead: mark the chapters here as read.
  pull,

  /// This device is ahead: queue it for the tracker.
  push,

  /// They agree.
  none,

  /// The tracker is ahead but the library has no chapters yet, as with an unmoved title.
  waitingForChapters,
}

ProgressAction planProgressSync({
  required int local,
  required int remote,
  required bool hasChapters,
}) {
  if (remote > local) {
    return hasChapters
        ? ProgressAction.pull
        : ProgressAction.waitingForChapters;
  }
  if (local > remote) return ProgressAction.push;
  return ProgressAction.none;
}

/// The chapters to mark read so everything up to [remote] is read.
List<String> chaptersToMarkRead(List<ChapterRecord> chapters, int remote) => [
  for (final chapter in chapters)
    if (!chapter.consumed && chapter.number <= remote) chapter.url,
];

class ProgressSyncResult {
  const ProgressSyncResult({
    this.pulled = 0,
    this.pushed = 0,
    this.waiting = 0,
  });

  /// Titles whose chapters were marked read here.
  final int pulled;

  /// Titles queued for the tracker.
  final int pushed;

  /// Titles that need a source before they can take the tracker's progress.
  final int waiting;
}

/// Syncs the library and a tracker both ways. The side further along wins.
Future<ProgressSyncResult> syncTrackerProgress({
  required LibraryRepository library,
  required TrackerStore store,
  required int profileId,
  required List<TrackerEntry> remote,
}) async {
  final linked = await store.linkedTitles(profileId);
  var pulled = 0;
  var pushed = 0;
  var waiting = 0;
  for (final entry in remote) {
    final link = linked[entry.key];
    if (link == null) continue;
    final records =
        (await library.getAllChapters(link.libraryEntryId)).valueOrNull ??
        const <ChapterRecord>[];
    final action = planProgressSync(
      local: await store.localProgress(link.libraryEntryId),
      remote: entry.progress,
      hasChapters: records.isNotEmpty,
    );
    switch (action) {
      case ProgressAction.pull:
        final urls = chaptersToMarkRead(records, entry.progress);
        if (urls.isEmpty) break;
        await library.markChaptersConsumed(
          libraryEntryId: link.libraryEntryId,
          chapterUrls: urls,
          consumed: true,
        );
        pulled++;
      case ProgressAction.push:
        await store.queueLink(link.linkId);
        pushed++;
      case ProgressAction.waitingForChapters:
        waiting++;
      case ProgressAction.none:
        break;
    }
  }
  return ProgressSyncResult(pulled: pulled, pushed: pushed, waiting: waiting);
}

/// The change to send for a title: [localProgress] is what this device has read,
/// [remote] what the tracker holds now. Null when nothing should be sent, so
/// progress only ever moves forward and a finished title is left alone.
TrackerEntryUpdate? planTrackerUpdate({
  required TrackerMedia media,
  required int mediaId,
  required int localProgress,
  required TrackerRemoteState remote,
  required DateTime today,
}) {
  if (localProgress <= 0) return null;
  final total = remote.total;
  final known = total != null && total > 0;
  final capped = known && localProgress > total ? total : localProgress;
  final finished = known && capped >= total;
  final date = TrackerDate.fromDateTime(today);
  final entry = remote.entry;

  if (entry == null) {
    return TrackerEntryUpdate(
      media: media,
      mediaId: mediaId,
      status: finished ? TrackerStatus.completed : TrackerStatus.current,
      progress: capped,
      startedAt: date,
      completedAt: finished ? date : null,
    );
  }
  if (entry.status == TrackerStatus.completed ||
      entry.status == TrackerStatus.repeating) {
    return null;
  }
  if (capped <= entry.progress) return null;

  TrackerStatus? status;
  if (finished) {
    status = TrackerStatus.completed;
  } else if (entry.status != TrackerStatus.current) {
    status = TrackerStatus.current;
  }
  return TrackerEntryUpdate(
    media: media,
    mediaId: mediaId,
    status: status,
    progress: capped,
    startedAt: entry.startedAt == null ? date : null,
    completedAt: finished && entry.completedAt == null ? date : null,
  );
}
