import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/library/data/library_repository_impl.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/downloaded_entry.dart';
import 'package:sumizuri/features/library/models/entry_branch.dart';
import 'package:sumizuri/features/library/models/library_entry_summary.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/features/library/models/reading_timeline_helper.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

part 'library_providers.g.dart';

@Riverpod(keepAlive: true)
LibraryRepository libraryRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final logger = ref.watch(appLoggerProvider);
  final profileId = ref.watch(currentProfileIdProvider);
  return DriftLibraryRepository(db, logger, profileId: profileId);
}

@Riverpod(keepAlive: true)
Stream<List<LibraryEntrySummary>> libraryEntries(
  Ref ref, {
  MediaType? mediaType,
}) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchLibrary(mediaType: mediaType);
}

/// Groups entries whose source is missing or uninstalled by media type.
Map<MediaType, List<LibraryEntrySummary>> groupEntriesNeedingMigration(
  List<LibraryEntrySummary> entries,
  Set<int> installedSourceIds,
) {
  final byType = <MediaType, List<LibraryEntrySummary>>{};
  for (final entry in entries) {
    final sourceId = int.tryParse(entry.sourceId);
    if (sourceId == null || !installedSourceIds.contains(sourceId)) {
      (byType[entry.mediaType] ??= []).add(entry);
    }
  }
  return byType;
}

@riverpod
Map<MediaType, List<LibraryEntrySummary>> entriesNeedingMigration(Ref ref) {
  final entries =
      ref.watch(libraryEntriesProvider(mediaType: null)).value ??
      const <LibraryEntrySummary>[];
  final installedIds = <int>{
    for (final s in ref.watch(installedSourcesProvider).value ?? const []) s.id,
  };
  return groupEntriesNeedingMigration(entries, installedIds);
}

@riverpod
Stream<Set<String>> libraryExternalIds(Ref ref, String sourceId) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchLibraryExternalIds(sourceId);
}

@Riverpod(keepAlive: true)
Stream<List<UpdateChapterSummary>> libraryUpdates(
  Ref ref, {
  MediaType? mediaType,
}) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchUpdates(mediaType: mediaType);
}

@Riverpod(keepAlive: true)
Stream<List<HistoryChapterSummary>> libraryHistory(
  Ref ref, {
  MediaType? mediaType,
}) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchHistory(mediaType: mediaType);
}

@Riverpod(keepAlive: true)
Stream<List<UpdateChapterSummary>> allChapterDates(
  Ref ref, {
  MediaType? mediaType,
}) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchAllChapterDates(mediaType: mediaType);
}

@riverpod
Stream<bool> chapterBookmarked(Ref ref, int libraryEntryId, String chapterUrl) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchChapterBookmarked(
    libraryEntryId: libraryEntryId,
    chapterUrl: chapterUrl,
  );
}

@riverpod
Stream<double?> furthestRead(Ref ref, int libraryEntryId) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchFurthestRead(libraryEntryId);
}

/// Batch furthestRead provider keyed by a comma-joined id list for caching.
@riverpod
Stream<Map<int, double?>> furthestReadMany(Ref ref, String sortedIdsKey) {
  final ids = sortedIdsKey.isEmpty
      ? const <int>[]
      : sortedIdsKey.split(',').map(int.parse).toList();
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchFurthestReadMany(ids);
}

/// The family key [furthestReadManyProvider] expects for a set of library entry ids.
String furthestReadManyKey(Iterable<int> libraryEntryIds) =>
    (libraryEntryIds.toList()..sort()).join(',');

@Riverpod(keepAlive: true)
Stream<List<ReadingTimelineBurst>> timelineBursts(
  Ref ref, {
  int? libraryEntryId,
  MediaType? mediaType,
}) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository
      .watchTimeline(libraryEntryId: libraryEntryId, mediaType: mediaType)
      .map(groupSessionsIntoBursts);
}

@riverpod
Stream<List<ReadingSessionRecord>> timelineSessions(
  Ref ref, {
  int? libraryEntryId,
  MediaType? mediaType,
}) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchTimeline(
    libraryEntryId: libraryEntryId,
    mediaType: mediaType,
  );
}

@riverpod
Stream<List<ReadingSessionRecord>> allReadingSessions(Ref ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchTimeline(limit: null);
}

@riverpod
Stream<String?> customCoverPath(Ref ref, int entryId) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchCustomCoverPath(entryId);
}

@Riverpod(keepAlive: true)
Stream<List<Category>> libraryCategories(Ref ref, {MediaType? mediaType}) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchCategories(mediaType: mediaType);
}

@riverpod
List<Category> visibleCategories(Ref ref, {MediaType? mediaType}) {
  if (!(ref.watch(categoriesEnabledProvider).value ?? true)) return const [];
  return [
    for (final type in mediaType == null ? MediaType.values : [mediaType])
      ...ref.watch(libraryCategoriesProvider(mediaType: type)).value ??
          const <Category>[],
  ];
}

@Riverpod(keepAlive: true)
Stream<Map<int, Set<int>>> allEntryCategoryIds(Ref ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchAllEntryCategoryIds();
}

@riverpod
Stream<String?> chapterLocalPath(
  Ref ref,
  int libraryEntryId,
  String chapterUrl,
) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchChapterLocalPath(
    libraryEntryId: libraryEntryId,
    chapterUrl: chapterUrl,
  );
}

@riverpod
Stream<List<DownloadedEntry>> downloadedEntries(Ref ref) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchDownloadedEntries();
}

@riverpod
Stream<List<EntryBranch>> entryBranches(Ref ref, int libraryEntryId) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchBranches(libraryEntryId);
}

@riverpod
Stream<int?> activeBranchId(Ref ref, int libraryEntryId) {
  final repository = ref.watch(libraryRepositoryProvider);
  return repository.watchActiveBranchId(libraryEntryId);
}

typedef UpdateProgress = ({
  int processed,
  int total,
  bool cancelRequested,
  DateTime startedAt,
});

@riverpod
class LibraryUpdateProgress extends _$LibraryUpdateProgress {
  @override
  UpdateProgress? build() => null;

  void set(UpdateProgress? value) => state = value;

  void requestCancel() {
    final current = state;
    if (current != null) {
      state = (
        processed: current.processed,
        total: current.total,
        cancelRequested: true,
        startedAt: current.startedAt,
      );
    }
  }
}
