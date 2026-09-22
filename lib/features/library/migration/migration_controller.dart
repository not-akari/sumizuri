import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/core/utils/downloads/jittered_delay.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/migration/match_scoring.dart';
import 'package:sumizuri/features/library/migration/migration_models.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';

part 'migration_controller.g.dart';

/// The maximum score recorded for a user-confirmed manual match.
const manualMatchScore = MigrationScore(total: 1, title: 1, chapters: null);

const _looksAt = 3;
const _searchResultsKept = 8;
const _worthALook = 0.4;

/// How a source is opened for searching. A provider so a test can hand in a fake source.
typedef MigrationSourceLoader = Future<ExtensionService?> Function(
  AppInstalledSource source,
);

// Captures container and logger up front to safely survive caller disposal.
@Riverpod(keepAlive: true)
MigrationSourceLoader migrationSourceLoader(Ref ref) {
  final container = ref.container;
  final logger = ref.read(appLoggerProvider);
  return (source) async {
    final loaded = await loadInstalledSource(
      container,
      MSourceInfo.fromInstalledSource(source),
      source,
      logger: logger,
    );
    return loaded.valueOrNull;
  };
}

// Kept alive so long-running async search/move tasks survive navigation.
@Riverpod(keepAlive: true)
class MigrationSession extends _$MigrationSession {
  @override
  MigrationState build() => const MigrationState();

  // No-op if requested ids match loaded state, avoiding resetting active work.
  Future<void> load(Set<int> entryIds, MediaType mediaType) async {
    final existingByEntryId = {
      for (final item in state.items) item.entryId: item,
    };
    if (entryIds.length == existingByEntryId.length &&
        entryIds.every(existingByEntryId.containsKey)) {
      return;
    }

    final repository = ref.read(libraryRepositoryProvider);
    final summaries = await repository.watchLibrary().first;
    final items = <MigrationItem>[];
    for (final summary in summaries) {
      if (!entryIds.contains(summary.id)) continue;
      if (summary.mediaType != mediaType) continue;
      final existing = existingByEntryId[summary.id];
      if (existing != null) {
        items.add(existing);
        continue;
      }
      final records =
          (await repository.getAllChapters(summary.id)).valueOrNull ?? const [];
      double? lastRead;
      for (final r in records) {
        if (r.consumed && (lastRead == null || r.number > lastRead)) {
          lastRead = r.number;
        }
      }
      items.add(
        MigrationItem(
          entryId: summary.id,
          title: summary.title,
          coverUrl: summary.coverUrl,
          mediaType: summary.mediaType,
          subject: MigrationSubject(
            title: summary.title,
            chapterNumbers: {for (final r in records) r.number},
            lastReadNumber: lastRead,
          ),
        ),
      );
    }
    state = MigrationState(items: items);
  }

  void cancel() {
    if (state.running) state = state.copyWith(cancelRequested: true);
  }

  void _update(int entryId, MigrationItem Function(MigrationItem) change) {
    state = state.copyWith(
      items: [
        for (final item in state.items)
          item.entryId == entryId ? change(item) : item,
      ],
    );
  }

  Future<void> search(AppInstalledSource target) async {
    if (state.running) return;
    final todo = [
      for (final item in state.items)
        if (item.status == MigrationStatus.queued ||
            item.status == MigrationStatus.notFound)
          item.entryId,
    ];
    state = state.copyWith(
      running: true,
      cancelRequested: false,
      targetName: target.name,
      targetSourceId: '${target.id}',
      processed: 0,
      total: todo.length,
    );
    ExtensionService? service;
    try {
      service = await ref.read(migrationSourceLoaderProvider)(target);
      for (final entryId in todo) {
        if (state.cancelRequested) break;
        if (service == null) {
          _update(
            entryId,
            (i) => i.copyWith(
              status: MigrationStatus.failed,
              error: () => 'Could not open ${target.name}',
            ),
          );
          continue;
        }
        _update(entryId, (i) => i.copyWith(status: MigrationStatus.searching));
        await _searchOne(service, entryId);
        state = state.copyWith(processed: state.processed + 1);
      }
    } finally {
      await service?.dispose();
      state = state.copyWith(
        running: false,
        cancelRequested: false,
        items: [
          for (final item in state.items)
            item.status == MigrationStatus.searching
                ? item.copyWith(status: MigrationStatus.queued)
                : item,
        ],
      );
    }
  }

  Future<void> _pause(ExtensionService service) async {
    final ms = service.rateLimitMs ?? 300;
    if (ms > 0) await Future<void>.delayed(jitteredDelay(ms));
  }

  Future<void> _searchOne(ExtensionService service, int entryId) async {
    final item = state.items.firstWhere((i) => i.entryId == entryId);
    final found = await service.search(item.title);
    await _pause(service);
    final results = found.valueOrNull;
    if (results == null) {
      _update(
        entryId,
        (i) => i.copyWith(
          status: MigrationStatus.failed,
          error: () => found.errorOrNull?.displayMessage,
        ),
      );
      return;
    }

    final byTitle = [
      for (final r in results.take(_searchResultsKept))
        (r, titleSimilarity(item.title, r.title)),
    ]..sort((a, b) => b.$2.compareTo(a.$2));
    final closeLook = [
      for (final (r, score) in byTitle)
        if (score >= _worthALook) r,
    ].take(_looksAt).toList();

    final chapterLists = <MEntry, List<MChapter>>{};
    for (final candidate in closeLook) {
      if (state.cancelRequested) return;
      final chapters = await service.getChapterList(candidate);
      await _pause(service);
      chapterLists[candidate] = chapters.valueOrNull ?? const [];
    }

    final candidates = [
      for (final entry in closeLook)
        MigrationCandidate(
          title: entry.title,
          author: entry.author,
          chapterNumbers: {
            for (final c in chapterLists[entry]!)
              if (c.number != null) c.number!,
          },
        ),
    ];
    final ranking = rank(item.subject, candidates);
    final options = <MigrationOption>[
      for (final (candidate, score) in ranking.ranked)
        MigrationOption(
          entry: closeLook[candidates.indexOf(candidate)],
          chapters: chapterLists[closeLook[candidates.indexOf(candidate)]]!,
          score: score,
        ),
    ];
    _update(
      entryId,
      (i) => i.copyWith(
        status: switch (ranking.verdict) {
          MigrationVerdict.found => MigrationStatus.found,
          MigrationVerdict.review => MigrationStatus.review,
          MigrationVerdict.notFound => MigrationStatus.notFound,
        },
        options: options,
        chosen: () =>
            ranking.verdict == MigrationVerdict.found ? options.first : null,
        error: () => null,
      ),
    );
  }

  /// Searches [target] directly for [query] during manual match.
  Future<Result<List<MEntry>, AppFailure>> manualSearch(
    AppInstalledSource target,
    String query,
  ) async {
    final service = await ref.read(migrationSourceLoaderProvider)(target);
    if (service == null) {
      return Err(UnknownFailure('Could not open ${target.name}'));
    }
    try {
      return await service.search(query);
    } finally {
      await service.dispose();
    }
  }

  /// Applies manually-picked entry to item after fetching its chapters.
  Future<Result<void, AppFailure>> manualMatch({
    required AppInstalledSource target,
    required int entryId,
    required MEntry entry,
  }) async {
    final service = await ref.read(migrationSourceLoaderProvider)(target);
    if (service == null) {
      return Err(UnknownFailure('Could not open ${target.name}'));
    }
    try {
      final chapters = await service.getChapterList(entry);
      final list = chapters.valueOrNull;
      if (list == null) {
        return Err(
          chapters.errorOrNull ?? const UnknownFailure('No chapters found'),
        );
      }
      choose(
        entryId,
        MigrationOption(entry: entry, chapters: list, score: manualMatchScore),
      );
      return const Ok(null);
    } finally {
      await service.dispose();
    }
  }

  void choose(int entryId, MigrationOption option) => _update(
    entryId,
    (i) => i.copyWith(status: MigrationStatus.found, chosen: () => option),
  );

  void reject(int entryId) => _update(
    entryId,
    (i) => i.copyWith(
      status: MigrationStatus.notFound,
      chosen: () => null,
      options: const [],
    ),
  );

  Future<({int moved, int failed})> moveFound() async {
    final targetId = state.targetSourceId;
    if (state.running || targetId == null) return (moved: 0, failed: 0);
    final repository = ref.read(libraryRepositoryProvider);
    final ready = state.withStatus(MigrationStatus.found);
    state = state.copyWith(
      running: true,
      cancelRequested: false,
      processed: 0,
      total: ready.length,
    );
    var moved = 0;
    var failed = 0;
    try {
      for (final item in ready) {
        if (state.cancelRequested) break;
        final choice = item.chosen;
        if (choice == null) continue;
        final result = await repository.moveEntryToSource(
          entryId: item.entryId,
          sourceId: targetId,
          externalId: choice.entry.url,
          coverUrl: choice.entry.coverUrl ?? item.coverUrl,
          status: choice.entry.status,
          newChapters: [
            for (final c in choice.chapters)
              ChapterSyncItem(
                url: c.url,
                number: c.number,
                title: c.title,
                dateUploaded: c.dateUploaded,
                scanlator: c.scanlator,
              ),
          ],
        );
        final outcome = result.valueOrNull;
        if (outcome == null) {
          failed++;
          _update(
            item.entryId,
            (i) => i.copyWith(
              status: MigrationStatus.failed,
              error: () =>
                  result.errorOrNull?.displayMessage ?? 'Could not move it',
            ),
          );
        } else {
          moved++;
          _update(
            item.entryId,
            (i) => i.copyWith(status: MigrationStatus.moved, outcome: outcome),
          );
        }
        state = state.copyWith(processed: state.processed + 1);
      }
    } finally {
      state = state.copyWith(running: false, cancelRequested: false);
    }
    return (moved: moved, failed: failed);
  }
}
