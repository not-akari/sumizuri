import 'package:sumizuri/features/library/models/series_overrides.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/downloaded_entry.dart';
import 'package:sumizuri/features/library/models/entry_branch.dart';
import 'package:sumizuri/features/library/models/library_duplicate_match.dart';
import 'package:sumizuri/features/library/models/library_entry_summary.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';

abstract interface class LibraryRepository {
  Stream<double?> watchFurthestRead(int libraryEntryId);

  /// Single query to watch furthest read for multiple entry ids.
  Stream<Map<int, double?>> watchFurthestReadMany(List<int> libraryEntryIds);

  Stream<List<ReadingSessionRecord>> watchTimeline({
    int? libraryEntryId,
    MediaType? mediaType,
    int? limit = 200,
  });

  Stream<List<LibraryEntrySummary>> watchLibrary({MediaType? mediaType});

  Future<String?> entryTitle(int libraryEntryId);

  Future<Result<void, AppFailure>> addToLibrary({
    required String title,
    String? coverUrl,
    required MediaType mediaType,
    required String sourceId,
    required String externalId,
  });

  Future<Result<LibraryMatch, AppFailure>> checkLibraryMatch({
    required String title,
    required String sourceId,
    required String externalId,
  });

  Future<Result<void, AppFailure>> migrateLibraryEntry({
    required int entryId,
    required String sourceId,
    required String externalId,
    required MediaType mediaType,
    String? coverUrl,
    String? status,
  });

  Future<Result<void, AppFailure>> fillMissingCover(
    int entryId,
    String coverUrl,
  );

  Future<Result<MoveOutcome, AppFailure>> moveEntryToSource({
    required int entryId,
    required String sourceId,
    required String externalId,
    String? coverUrl,
    String? status,
    required List<ChapterSyncItem> newChapters,
  });

  Stream<Set<String>> watchLibraryExternalIds(String sourceId);

  Future<Result<void, AppFailure>> removeFromLibrary(int entryId);

  Future<Result<void, AppFailure>> syncChapters({
    required int libraryEntryId,
    required List<ChapterSyncItem> chapters,
  });

  Future<Result<void, AppFailure>> markChapterConsumed({
    required int libraryEntryId,
    required String chapterUrl,
  });

  /// Logs that a chapter or episode is being read or watched, without marking it done.
  Future<Result<void, AppFailure>> recordChapterSession({
    required int libraryEntryId,
    required String chapterUrl,
  });

  Future<Result<void, AppFailure>> markChaptersConsumed({
    required int libraryEntryId,
    required List<String> chapterUrls,
    required bool consumed,
    bool recordSession = false,
  });

  Future<Result<void, AppFailure>> updateChapterProgress({
    required int libraryEntryId,
    required String chapterUrl,
    required double progressPosition,
  });

  Future<Result<double?, AppFailure>> getChapterProgress({
    required int libraryEntryId,
    required String chapterUrl,
  });

  Stream<ReaderMode?> watchEntryReaderMode(int entryId);

  Stream<SeriesOverrides> watchEntryOverrides(int entryId);

  Future<Result<void, AppFailure>> updateEntryOverrides({
    required int entryId,
    required SeriesOverrides overrides,
  });

  Stream<ReaderDualPageMode?> watchEntryDualPageMode(int entryId);

  Future<Result<void, AppFailure>> updateEntryDualPageMode({
    required int entryId,
    required ReaderDualPageMode? mode,
  });

  Future<Result<void, AppFailure>> updateEntryReaderMode({
    required int entryId,
    required ReaderMode? readerMode,
  });

  /// Whether reader-mode auto-detection has already run for this entry.
  Future<bool> hasCheckedReaderMode(int entryId);

  Future<Result<void, AppFailure>> markReaderModeChecked(int entryId);

  Stream<List<UpdateChapterSummary>> watchUpdates({
    MediaType? mediaType,
    int limit = 200,
  });

  Stream<List<HistoryChapterSummary>> watchHistory({
    MediaType? mediaType,
    int limit = 200,
  });

  Stream<List<UpdateChapterSummary>> watchAllChapterDates({
    MediaType? mediaType,
  });

  Stream<String?> watchCustomCoverPath(int entryId);

  Future<Result<void, AppFailure>> setCustomCoverPath({
    required int entryId,
    required String? path,
  });

  Stream<List<Category>> watchCategories({MediaType? mediaType});

  Future<Result<int, AppFailure>> createCategory(
    String name, {
    required MediaType mediaType,
  });

  Future<Result<void, AppFailure>> renameCategory({
    required int id,
    required String name,
  });

  Future<Result<void, AppFailure>> deleteCategory(int id);

  Future<Result<void, AppFailure>> reorderCategories(List<int> orderedIds);

  Future<Result<void, AppFailure>> setCategoryExcludeFromUpdate({
    required int id,
    required bool exclude,
  });

  Future<Result<void, AppFailure>> setCategorySmartRule({
    required int id,
    required bool useSmartRule,
    required CategorySortField sortField,
    required bool sortAscending,
    required CategoryStatusFilter statusFilter,
  });

  Stream<Set<int>> watchEntryCategoryIds(int entryId);

  Stream<Map<int, Set<int>>> watchAllEntryCategoryIds();

  Future<Result<void, AppFailure>> setEntryCategories({
    required int entryId,
    required Set<int> categoryIds,
  });

  Future<Result<List<LibraryEntrySummary>, AppFailure>>
  entriesEligibleForUpdate({int skip = 0});

  Stream<List<String>> watchExcludedScanlators(int libraryEntryId);

  Future<Result<void, AppFailure>> setExcludedScanlators(
    int libraryEntryId,
    List<String> scanlators,
  );

  Stream<bool> watchChapterBookmarked({
    required int libraryEntryId,
    required String chapterUrl,
  });

  Future<Result<void, AppFailure>> setChaptersBookmarked({
    required int libraryEntryId,
    required List<String> chapterUrls,
    required bool bookmarked,
  });

  Stream<String?> watchChapterLocalPath({
    required int libraryEntryId,
    required String chapterUrl,
  });

  Future<Result<void, AppFailure>> setChapterLocalPath({
    required int libraryEntryId,
    required String chapterUrl,
    required String? path,
  });

  Future<Result<List<ChapterRecord>, AppFailure>> getAllChapters(
    int libraryEntryId,
  );

  Future<Result<List<({String chapterUrl, DateTime readAt})>, AppFailure>>
  getReadingSessions(int libraryEntryId);

  Future<Result<void, AppFailure>> restoreReadingSessions({
    required int libraryEntryId,
    required List<({String chapterUrl, DateTime readAt})> sessions,
  });

  Future<Result<void, AppFailure>> restoreChapters({
    required int libraryEntryId,
    required List<ChapterRecord> chapters,
  });

  Stream<List<DownloadedEntry>> watchDownloadedEntries();

  Stream<List<EntryBranch>> watchBranches(int libraryEntryId);

  Stream<int?> watchActiveBranchId(int libraryEntryId);

  Future<Result<EntryBranch, AppFailure>> createBranch({
    required int libraryEntryId,
    required String name,
  });

  Future<Result<void, AppFailure>> switchBranch({
    required int libraryEntryId,
    required int branchId,
  });

  Future<Result<void, AppFailure>> renameBranch({
    required int branchId,
    required String name,
  });

  Future<Result<void, AppFailure>> deleteBranch({
    required int libraryEntryId,
    required int branchId,
  });
}
