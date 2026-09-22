import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/extensions/models/season_group.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_chapter_widgets.dart';

Future<Result<ExtensionService, AppFailure>> loadEntryService({
  required BuildContext context,
  required WidgetRef ref,
  required AppInstalledSource source,
}) async {
  return loadInstalledSource(
    ProviderScope.containerOf(context, listen: false),
    MSourceInfo.fromInstalledSource(source),
    source,
    logger: ref.read(appLoggerProvider),
  );
}

Future<Result<List<MChapter>, AppFailure>> loadEntryChapters({
  required WidgetRef ref,
  required ExtensionService service,
  required MEntry entry,
  required int? libraryEntryId,
  required bool ascending,
  bool forceNetwork = false,
}) async {
  final repository = ref.read(libraryRepositoryProvider);
  if (!forceNetwork && libraryEntryId != null) {
    final cached = await repository.getAllChapters(libraryEntryId);
    final records = cached.valueOrNull;
    if (records != null && records.isNotEmpty) {
      final stored = [for (final record in records) chapterFromRecord(record)];
      final withSeasons = service.info.mediaType == MediaType.anime
          ? await _refreshedFromSource(
              repository,
              service,
              entry,
              libraryEntryId,
              stored,
            )
          : stored;
      return Ok(sortChapters(withSeasons, ascending: ascending));
    }
  }

  final result = await service.getChapterList(entry);
  return result.when(
    ok: (chapters) => Ok(sortChapters(chapters, ascending: ascending)),
    err: Err.new,
  );
}

Future<List<MChapter>> _refreshedFromSource(
  LibraryRepository repository,
  ExtensionService service,
  MEntry entry,
  int libraryEntryId,
  List<MChapter> stored,
) async {
  final fromSource = (await service.getChapterList(entry)).valueOrNull;
  if (fromSource == null || fromSource.isEmpty) return stored;
  await repository.syncChapters(
    libraryEntryId: libraryEntryId,
    chapters: [
      for (final chapter in fromSource)
        ChapterSyncItem(
          url: chapter.url,
          number: chapter.number,
          title: chapter.title,
          dateUploaded: chapter.dateUploaded,
          scanlator: chapter.scanlator,
        ),
    ],
  );
  final records = (await repository.getAllChapters(libraryEntryId)).valueOrNull;
  if (records == null || records.isEmpty) return stored;
  return withSeasonsFrom([
    for (final record in records) chapterFromRecord(record),
  ], fromSource);
}

Future<MEntry?> loadEntryDetails({
  required WidgetRef ref,
  required ExtensionService service,
  required MEntry entry,
  required int? libraryEntryId,
  required AppInstalledSource? source,
}) async {
  final library = ref.read(libraryRepositoryProvider);
  final result = await service.getDetails(entry);
  final details = result.valueOrNull;
  if (details != null && libraryEntryId != null && source != null) {
    await library.migrateLibraryEntry(
      entryId: libraryEntryId,
      sourceId: source.id.toString(),
      externalId: entry.url,
      mediaType: source.mediaType,
      coverUrl: details.coverUrl ?? entry.coverUrl,
      status: details.status ?? entry.status,
    );
  }
  return details;
}

Future<int?> checkEntryLibraryMembership({
  required WidgetRef ref,
  required ExtensionService service,
  required MEntry entry,
}) async {
  final result = await ref
      .read(libraryRepositoryProvider)
      .checkLibraryMatch(
        title: entry.title,
        sourceId: service.info.id,
        externalId: entry.url,
      );
  return result.valueOrNull?.exactMatchId;
}

Future<bool> addEntryToLibraryFromDetail({
  required WidgetRef ref,
  required ExtensionService? service,
  required MEntry entry,
}) async {
  if (service == null) return false;
  final res = await ref
      .read(libraryRepositoryProvider)
      .addToLibrary(
        title: entry.title,
        coverUrl: entry.coverUrl,
        mediaType: service.info.mediaType,
        sourceId: service.info.id,
        externalId: entry.url,
      );
  return res.isOk;
}
