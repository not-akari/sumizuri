// Turns a read Mangayomi backup into library entries, categories, chapters and history.
import 'package:sumizuri/core/utils/formatting/chapter_number.dart'
    show parseChapterNumber;
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/migration/auto_source_match.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/data/mangayomi_import_codec.dart';
import 'package:sumizuri/features/settings/flows/backup_import_result.dart';

export 'package:sumizuri/features/settings/flows/backup_import_result.dart'
    show BackupImportResult;

/// Placeholder source id assigned to imported titles before migration.
const mangayomiImportSourceId = 'mangayomi';

typedef MangayomiImportResult = BackupImportResult;

/// Imports titles from [backup] with categories, chapters, and reading history.
Future<MangayomiImportResult> importMangayomiBackup({
  required LibraryRepository library,
  required MangayomiBackup backup,
}) async {
  var added = 0;
  var skipped = 0;
  var failed = 0;
  final addedIds = <MediaType, Set<int>>{};
  final candidates = <AutoMatchCandidate>[];

  // One Sumizuri category per Mangayomi category, made once and reused for every title.
  final categoryIds = <int, int>{};
  for (final category in backup.categories) {
    final result = await library.createCategory(
      category.name,
      mediaType: category.forItemType.mediaType,
    );
    final id = result.valueOrNull;
    if (id != null) categoryIds[category.id] = id;
  }

  final chaptersByManga = <int, List<MangayomiChapter>>{};
  final chapterById = <int, MangayomiChapter>{};
  for (final chapter in backup.chapters) {
    (chaptersByManga[chapter.mangaId] ??= []).add(chapter);
    chapterById[chapter.id] = chapter;
  }
  final historyByManga = <int, List<MangayomiHistoryEntry>>{};
  for (final entry in backup.history) {
    (historyByManga[entry.mangaId] ??= []).add(entry);
  }

  for (final manga in backup.manga) {
    if (manga.link.isEmpty || manga.name.isEmpty) {
      failed++;
      continue;
    }

    final existing = await library.checkLibraryMatch(
      title: manga.name,
      sourceId: mangayomiImportSourceId,
      externalId: manga.link,
    );
    if (existing.valueOrNull?.isExactMatch ?? false) {
      skipped++;
      continue;
    }

    final createResult = await library.addToLibrary(
      title: manga.name,
      coverUrl: manga.imageUrl,
      mediaType: manga.itemType.mediaType,
      sourceId: mangayomiImportSourceId,
      externalId: manga.link,
    );
    if (createResult.isErr) {
      failed++;
      continue;
    }
    final match = await library.checkLibraryMatch(
      title: manga.name,
      sourceId: mangayomiImportSourceId,
      externalId: manga.link,
    );
    final entryId = match.valueOrNull?.exactMatchId;
    if (entryId == null) {
      failed++;
      continue;
    }

    final categoryIdsForEntry = {
      for (final id in manga.categories) ?categoryIds[id],
    };
    if (categoryIdsForEntry.isNotEmpty) {
      await library.setEntryCategories(
        entryId: entryId,
        categoryIds: categoryIdsForEntry,
      );
    }

    final chapters = chaptersByManga[manga.id] ?? const [];
    if (chapters.isNotEmpty) {
      await library.restoreChapters(
        libraryEntryId: entryId,
        chapters: [
          for (final chapter in chapters)
            ChapterRecord(
              url: chapter.url,
              number: parseChapterNumber(chapter.name) ?? 0,
              title: chapter.name,
              dateUploaded: chapter.dateUpload,
              consumed: chapter.isRead,
              progressPosition: chapter.lastPageRead,
              bookmarked: chapter.isBookmarked,
              scanlator: chapter.scanlator,
            ),
        ],
      );
    }

    final sessions = historyByManga[manga.id] ?? const [];
    if (sessions.isNotEmpty) {
      await library.restoreReadingSessions(
        libraryEntryId: entryId,
        sessions: [
          for (final session in sessions)
            if (chapterById[session.chapterId] case final chapter?)
              if (session.date case final readAt?)
                (chapterUrl: chapter.url, readAt: readAt),
        ],
      );
    }

    added++;
    (addedIds[manga.itemType.mediaType] ??= {}).add(entryId);
    candidates.add(
      AutoMatchCandidate(
        entryId: entryId,
        mediaType: manga.itemType.mediaType,
        url: manga.link,
        sourceName: manga.source.isEmpty ? null : manga.source,
      ),
    );
  }

  return MangayomiImportResult(
    added: added,
    skipped: skipped,
    failed: failed,
    addedIds: addedIds,
    candidates: candidates,
  );
}
