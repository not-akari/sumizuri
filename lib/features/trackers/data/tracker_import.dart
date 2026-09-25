import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';

class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.addedIds,
    required this.failed,
  });

  /// Library entries made.
  final int added;

  /// Titles that were already in the library through this tracker.
  final int skipped;

  final int failed;

  /// The new library entries, by media type, for the migration that usually follows.
  final Map<MediaType, Set<int>> addedIds;
}

/// Adds a tracker's list to the library with links. Linked titles are left as
/// they are. The titles have no source yet, so [sourceId] opens nowhere until
/// they are moved to one.
Future<ImportResult> importTrackerEntries({
  required LibraryRepository library,
  required TrackerStore store,
  required int profileId,
  required List<TrackerEntry> entries,
}) async {
  final sourceId = store.tracker;
  final linked = await store.linkedTitles(profileId);
  var added = 0;
  var skipped = 0;
  var failed = 0;
  final addedIds = <MediaType, Set<int>>{};
  for (final entry in entries) {
    if (linked.containsKey(entry.key)) {
      skipped++;
      continue;
    }
    final type = entry.libraryType;
    // AniList ids are unique across both lists. MyAnimeList repeats them, so
    // there the list is part of the id.
    final externalId = store.tracker == 'anilist'
        ? '${entry.mediaId}'
        : '${entry.media.name}-${entry.mediaId}';
    final result = await library.addToLibrary(
      title: entry.title,
      coverUrl: entry.coverUrl,
      mediaType: type,
      sourceId: sourceId,
      externalId: externalId,
    );
    if (result.isErr) {
      failed++;
      continue;
    }
    final match = await library.checkLibraryMatch(
      title: entry.title,
      sourceId: sourceId,
      externalId: externalId,
    );
    final id = match.valueOrNull?.exactMatchId;
    if (id == null) {
      failed++;
      continue;
    }
    await store.link(
      libraryEntryId: id,
      mediaId: entry.mediaId,
      title: entry.title,
      chapters: entry.total,
      queue: false,
    );
    added++;
    (addedIds[type] ??= {}).add(id);
  }
  return ImportResult(
    added: added,
    skipped: skipped,
    failed: failed,
    addedIds: addedIds,
  );
}
