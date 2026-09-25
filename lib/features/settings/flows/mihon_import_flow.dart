// Turns a read Mihon backup into library entries, chapters and history.
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/migration/auto_source_match.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/data/mihon_import_codec.dart';
import 'package:sumizuri/features/settings/flows/backup_import_result.dart';
import 'package:sumizuri/features/settings/flows/import_categories.dart';

/// Placeholder source id assigned to imported titles before migration.
const mihonImportSourceId = 'mihon';

typedef MihonImportResult = BackupImportResult;

/// Deduplicates chapters sharing a number, prioritizing read over unread.
List<MihonChapter> _dedupedChapters(List<MihonChapter> chapters) {
  final byNumber = <double, MihonChapter>{};
  final withoutNumber = <MihonChapter>[];
  for (final chapter in chapters) {
    final number = chapter.number;
    if (number == null) {
      withoutNumber.add(chapter);
      continue;
    }
    final existing = byNumber[number];
    if (existing == null || (!existing.isRead && chapter.isRead)) {
      byNumber[number] = chapter;
    }
  }
  return [...byNumber.values, ...withoutNumber];
}

/// Imports favorited titles from [backup] with chapters and reading history.
Future<MihonImportResult> importMihonBackup({
  required LibraryRepository library,
  required MihonBackup backup,
  void Function(int completed, int total)? onProgress,
  bool Function()? isCancelled,
}) async {
  var added = 0;
  var skipped = 0;
  var failed = 0;
  var cancelled = false;
  final addedIds = <MediaType, Set<int>>{};
  final candidates = <AutoMatchCandidate>[];

  // One category per backup category, made once (or matched by name to one
  // that is already there); titles refer to them by order.
  final categoryIdByOrder = <int, int>{};
  for (final category in backup.categories) {
    final id = await ensureCategory(library, category.name, MediaType.manga);
    if (id != null) categoryIdByOrder[category.order] = id;
  }

  final total = backup.manga.length;
  onProgress?.call(0, total);
  var completed = 0;
  for (final manga in backup.manga) {
    if (isCancelled?.call() ?? false) {
      cancelled = true;
      break;
    }
    // The `finally` still runs on every `continue` below, so this reports
    // progress for every entry regardless of which branch handled it.
    try {
      if (manga.url.isEmpty || manga.title.isEmpty) {
        failed++;
        continue;
      }

      final existing = await library.checkLibraryMatch(
        title: manga.title,
        sourceId: mihonImportSourceId,
        externalId: manga.url,
      );
      if (existing.valueOrNull?.isExactMatch ?? false) {
        skipped++;
        continue;
      }

      final createResult = await library.addToLibrary(
        title: manga.title,
        coverUrl: manga.coverUrl,
        mediaType: MediaType.manga,
        sourceId: mihonImportSourceId,
        externalId: manga.url,
      );
      if (createResult.isErr) {
        failed++;
        continue;
      }
      final match = await library.checkLibraryMatch(
        title: manga.title,
        sourceId: mihonImportSourceId,
        externalId: manga.url,
      );
      final entryId = match.valueOrNull?.exactMatchId;
      if (entryId == null) {
        failed++;
        continue;
      }

      final categoryIds = {
        for (final order in manga.categoryOrders) ?categoryIdByOrder[order],
      };
      if (categoryIds.isNotEmpty) {
        await library.setEntryCategories(
          entryId: entryId,
          categoryIds: categoryIds,
        );
      }

      final chapters = _dedupedChapters(manga.chapters);
      if (chapters.isNotEmpty) {
        await library.restoreChapters(
          libraryEntryId: entryId,
          chapters: [
            for (final chapter in chapters)
              ChapterRecord(
                url: chapter.url,
                number: chapter.number ?? 0,
                title: chapter.name,
                dateUploaded: chapter.dateUpload,
                consumed: chapter.isRead,
                scanlator: chapter.scanlator,
              ),
          ],
        );
      }

      if (manga.history.isNotEmpty) {
        await library.restoreReadingSessions(
          libraryEntryId: entryId,
          sessions: [
            for (final entry in manga.history)
              if (entry.chapterUrl.isNotEmpty)
                if (entry.lastReadAt case final readAt?)
                  (chapterUrl: entry.chapterUrl, readAt: readAt),
          ],
        );
      }

      added++;
      (addedIds[MediaType.manga] ??= {}).add(entryId);
      candidates.add(
        AutoMatchCandidate(
          entryId: entryId,
          mediaType: MediaType.manga,
          url: manga.url,
          sourceName: manga.sourceName,
        ),
      );
    } finally {
      onProgress?.call(++completed, total);
    }
  }

  return MihonImportResult(
    added: added,
    skipped: skipped,
    failed: failed,
    addedIds: addedIds,
    candidates: candidates,
    cancelled: cancelled,
  );
}
