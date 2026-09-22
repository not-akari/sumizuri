import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';

/// What to do about one linked title, given how far each side says it is.
enum ProgressAction {
  /// AniList is ahead: mark the chapters here as read.
  pull,

  /// This device is ahead: queue it for AniList.
  push,

  /// They agree.
  none,

  /// AniList is ahead but the library has no chapters yet, as with an unmoved title.
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

  /// Titles queued for AniList.
  final int pushed;

  /// Titles that need a source before they can take AniList's progress.
  final int waiting;
}

/// Syncs the library and AniList both ways. The side further along wins.
Future<ProgressSyncResult> syncProgress({
  required LibraryRepository library,
  required TrackerStore store,
  required int profileId,
  required List<AniListListEntry> remote,
}) async {
  final linked = await store.linkedTitles(profileId);
  var pulled = 0;
  var pushed = 0;
  var waiting = 0;
  for (final entry in remote) {
    final link = linked[entry.mediaId];
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
