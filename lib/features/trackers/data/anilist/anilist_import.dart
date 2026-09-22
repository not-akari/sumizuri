import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';

/// The source id of an imported AniList title that has no source yet. It opens nowhere.
const aniListImportSourceId = 'anilist';

MediaType libraryTypeFor(AniListMedia media) {
  if (media.type == AniListMediaType.anime) return MediaType.anime;
  return media.isNovel ? MediaType.novel : MediaType.manga;
}

class ImportResult {
  const ImportResult({
    required this.added,
    required this.skipped,
    required this.addedIds,
    required this.failed,
  });

  /// Library entries made.
  final int added;

  /// Titles that were already in the library through AniList.
  final int skipped;

  final int failed;

  /// The new library entries, by media type, for the migration that usually follows.
  final Map<MediaType, Set<int>> addedIds;
}

/// Adds an AniList list to the library with links. Linked titles are left as they are.
Future<ImportResult> importAniListEntries({
  required LibraryRepository library,
  required TrackerStore store,
  required int profileId,
  required List<AniListListEntry> entries,
}) async {
  final linked = await store.linkedTitles(profileId);
  var added = 0;
  var skipped = 0;
  var failed = 0;
  final addedIds = <MediaType, Set<int>>{};
  for (final entry in entries) {
    final media = entry.media;
    if (media == null) continue;
    if (linked.containsKey(media.id)) {
      skipped++;
      continue;
    }
    final type = libraryTypeFor(media);
    final title = media.title.display;
    final externalId = media.id.toString();
    final result = await library.addToLibrary(
      title: title,
      coverUrl: media.coverUrl,
      mediaType: type,
      sourceId: aniListImportSourceId,
      externalId: externalId,
    );
    if (result.isErr) {
      failed++;
      continue;
    }
    final match = await library.checkLibraryMatch(
      title: title,
      sourceId: aniListImportSourceId,
      externalId: externalId,
    );
    final id = match.valueOrNull?.exactMatchId;
    if (id == null) {
      failed++;
      continue;
    }
    await store.link(
      libraryEntryId: id,
      mediaId: media.id,
      title: title,
      chapters: media.chapters ?? media.episodes,
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
