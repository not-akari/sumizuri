import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/bootstrap/notifications/notification_provider.dart';
import 'package:sumizuri/core/utils/downloads/jittered_delay.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/m_source_info.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/library/flows/auto_download_gate.dart';
import 'package:sumizuri/features/library/flows/chapter_download_flow.dart';
import 'package:sumizuri/features/library/flows/download_queue.dart'
    show downloadQueueStoreProvider, saveToStoredQueue;
import 'package:sumizuri/features/library/providers/library_providers.dart';

typedef _UpdateOutcome = ({
  int updated,
  int failed,
  bool cancelled,
  bool ranOutOfTime,
});

List<T> rotatedFrom<T>(List<T> items, int start) {
  if (items.isEmpty) return items;
  final at = start % items.length;
  return [...items.skip(at), ...items.take(at)];
}

Future<void> _waitForSettings(ProviderContainer container) async {
  try {
    await Future.wait([
      container.read(installedSourcesProvider.future),
      container.read(libraryUpdateSkipProvider.future),
      container.read(autoDownloadOnLibraryUpdateProvider.future),
      container.read(notificationsEnabledProvider.future),
    ]);
  } catch (_) {
    // A setting that will not load is read as its default, as it would have been.
  }
}

Future<_UpdateOutcome?> _runUpdateCore(
  ProviderContainer container, {
  Set<int>? onlyEntryIds,
  bool background = false,
  Duration? budget,
}) async {
  final logger = container.read(appLoggerProvider);

  if (container.read(libraryUpdateProgressProvider) != null) return null;
  await _waitForSettings(container);
  final deadline = budget == null ? null : DateTime.now().add(budget);
  final settings = container.read(settingsRepositoryProvider);

  final progressNotifier = container.read(
    libraryUpdateProgressProvider.notifier,
  );

  try {
    final result = await container
        .read(libraryRepositoryProvider)
        .entriesEligibleForUpdate(
          skip: container.read(libraryUpdateSkipProvider).value ?? 0,
        );
    final eligible = result.valueOrNull;
    final chosen = onlyEntryIds == null || eligible == null
        ? eligible
        : [
            for (final entry in eligible)
              if (onlyEntryIds.contains(entry.id)) entry,
          ];
    if (chosen == null) {
      logger.error(
        'Failed to load library for auto-update: ${result.errorOrNull}',
        tag: 'library_update',
      );
      return const (
        updated: 0,
        failed: 0,
        cancelled: false,
        ranOutOfTime: false,
      );
    }
    var entries = chosen;
    var start = 0;
    if (background && entries.isNotEmpty) {
      start = (await settings.getBackgroundUpdateCursor()) % entries.length;
      entries = rotatedFrom(entries, start);
    }

    final sources = container.read(installedSourcesProvider).value ?? const [];
    progressNotifier.set((
      processed: 0,
      total: entries.length,
      cancelRequested: false,
    ));

    var processed = 0;
    var updated = 0;
    var failed = 0;
    var cancelled = false;
    var ranOutOfTime = false;
    final foundNewChapters =
        <({String entryTitle, List<MChapter> chapters, bool anime})>[];

    for (final entry in entries) {
      if (container.read(libraryUpdateProgressProvider)?.cancelRequested ??
          false) {
        cancelled = true;
        break;
      }
      if (deadline != null && DateTime.now().isAfter(deadline)) {
        ranOutOfTime = true;
        break;
      }
      try {
        final parsedSourceId = int.tryParse(entry.sourceId);
        AppInstalledSource? source;
        for (final candidate in sources) {
          if (candidate.id == parsedSourceId) {
            source = candidate;
            break;
          }
        }
        if (source == null) {
          failed++;
          continue;
        }

        final serviceResult = await loadInstalledSource(
          container,
          MSourceInfo.fromInstalledSource(source),
          source,
          logger: logger,
        );
        final service = serviceResult.valueOrNull;
        if (service == null) {
          failed++;
          continue;
        }

        try {
          final chaptersResult = await service.getChapterList(
            MEntry(
              url: entry.externalId,
              title: entry.title,
              coverUrl: entry.coverUrl,
            ),
          );
          if (service.rateLimitMs != null && service.rateLimitMs! > 0) {
            await Future<void>.delayed(jitteredDelay(service.rateLimitMs!));
          }
          final chapters = chaptersResult.valueOrNull;
          if (chapters == null) {
            failed++;
            continue;
          }

          final autoDownload =
              container.read(autoDownloadOnLibraryUpdateProvider).value ??
              false;
          final notifsEnabled =
              container.read(notificationsEnabledProvider).value ?? true;
          Set<String>? existingUrls;
          if (autoDownload || notifsEnabled) {
            final existingResult = await container
                .read(libraryRepositoryProvider)
                .getAllChapters(entry.id);
            existingUrls = {
              for (final record
                  in existingResult.valueOrNull ?? const <ChapterRecord>[])
                record.url,
            };
          }

          await container
              .read(libraryRepositoryProvider)
              .syncChapters(
                libraryEntryId: entry.id,
                chapters: [
                  for (final chapter in chapters)
                    ChapterSyncItem(
                      url: chapter.url,
                      number: chapter.number,
                      title: chapter.title,
                      dateUploaded: chapter.dateUploaded,
                    ),
                ],
              );
          updated++;

          if (existingUrls != null) {
            final newChapters = [
              for (final chapter in chapters)
                if (!existingUrls.contains(chapter.url)) chapter,
            ];
            if (newChapters.isNotEmpty) {
              if (notifsEnabled) {
                foundNewChapters.add((
                  entryTitle: entry.title,
                  chapters: newChapters,
                  anime: service.info.mediaType == MediaType.anime,
                ));
              }
              if (autoDownload && await canAutoDownloadNow(container)) {
                final wanted = await capAutoDownloadChapters(
                  newChapters,
                  container,
                  libraryEntryId: entry.id,
                );
                if (background) {
                  // A background run is cut off without warning, so the app downloads them when it opens.
                  await saveToStoredQueue(
                    container.read(downloadQueueStoreProvider),
                    libraryEntryId: entry.id,
                    sourceId: entry.sourceId,
                    entryTitle: entry.title,
                    mediaType: service.info.mediaType,
                    chapters: wanted,
                  );
                } else {
                  await downloadAllChapters(
                    container: container,
                    service: service,
                    libraryEntryId: entry.id,
                    sourceId: entry.sourceId,
                    entryTitle: entry.title,
                    chapters: wanted,
                  );
                }
              }
            }
          }
        } finally {
          await service.dispose();
        }
      } finally {
        processed++;

        final currentCancelRequested =
            container.read(libraryUpdateProgressProvider)?.cancelRequested ??
            false;
        progressNotifier.set((
          processed: processed,
          total: entries.length,
          cancelRequested: currentCancelRequested,
        ));
      }
    }

    if (foundNewChapters.isNotEmpty) {
      _dispatchNewChapterNotifications(container, foundNewChapters);
    }

    if (background) {
      await settings.setBackgroundUpdateCursor(
        ranOutOfTime && entries.isNotEmpty
            ? (start + processed) % entries.length
            : 0,
      );
      logger.info(
        'Background library update: checked $processed of ${entries.length} title(s), $updated updated, $failed failed${ranOutOfTime ? ', stopped for time' : ''}',
        tag: 'library_update',
      );
    }
    return (
      updated: updated,
      failed: failed,
      cancelled: cancelled,
      ranOutOfTime: ranOutOfTime,
    );
  } finally {
    container.read(libraryUpdateProgressProvider.notifier).set(null);
  }
}

Future<void> runLibraryUpdate(
  BuildContext context,
  WidgetRef ref, {
  Set<int>? onlyEntryIds,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final container = ProviderScope.containerOf(context, listen: false);
  final messenger = ScaffoldMessenger.of(context);

  if (container.read(libraryUpdateProgressProvider) != null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.libraryUpdateAlreadyRunning)),
    );
    return;
  }

  final eligibleCount =
      (await container
              .read(libraryRepositoryProvider)
              .entriesEligibleForUpdate(
                skip: container.read(libraryUpdateSkipProvider).value ?? 0,
              ))
          .valueOrNull
          ?.where((e) => onlyEntryIds?.contains(e.id) ?? true)
          .length;
  if (eligibleCount != null) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.libraryUpdateStarted(eligibleCount))),
    );
  }

  final outcome = await _runUpdateCore(container, onlyEntryIds: onlyEntryIds);
  if (outcome == null || !context.mounted) return;
  messenger.showSnackBar(
    SnackBar(
      content: Text(
        outcome.cancelled
            ? l10n.libraryUpdateCancelled(outcome.updated)
            : outcome.failed == 0
            ? l10n.libraryUpdateFinished(outcome.updated)
            : l10n.libraryUpdateFinishedWithFailures(
                outcome.updated,
                outcome.failed,
              ),
      ),
    ),
  );
}

Future<void> autoUpdateLibraryIfDue(
  ProviderContainer container, {
  bool background = false,
  Duration? budget,
}) async {
  final intervalHours =
      container.read(autoLibraryUpdateIntervalHoursProvider).value ?? 0;
  if (intervalHours <= 0) return;
  if (container.read(libraryUpdateProgressProvider) != null) return;

  final repository = container.read(settingsRepositoryProvider);
  final lastRun = await repository.getLastAutoLibraryUpdateAt();
  final due =
      lastRun == null ||
      DateTime.now().difference(lastRun) >= Duration(hours: intervalHours);
  if (!due) return;

  final wifiOnly =
      container.read(autoLibraryUpdateWifiOnlyProvider).value ?? true;
  if (wifiOnly && !await hasUnmeteredConnection()) return;

  await repository.setLastAutoLibraryUpdateAt(DateTime.now());
  final outcome = await _runUpdateCore(
    container,
    background: background,
    budget: budget,
  );
  if (outcome != null && outcome.ranOutOfTime) {
    await repository.setLastAutoLibraryUpdateAt(lastRun);
  }
}

void _dispatchNewChapterNotifications(
  ProviderContainer container,
  List<({String entryTitle, List<MChapter> chapters, bool anime})> updates,
) {
  final notifService = container.read(notificationServiceProvider);
  if (updates.isEmpty) return;

  final locale = WidgetsBinding.instance.platformDispatcher.locale;
  final l10n = lookupAppLocalizations(locale);

  if (updates.length == 1) {
    final single = updates.first;
    final count = single.chapters.length;
    final chapterNames = single.chapters
        .take(3)
        .map((c) => _formatChapterLabel(c, l10n, single.anime))
        .join(', ');
    final suffix = count > 3
        ? l10n.notificationMoreChaptersSuffix(count - 3)
        : '';

    notifService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: l10n.notificationNewChaptersSingleTitle(single.entryTitle),
      body: single.anime
          ? l10n.notificationNewEpisodesSingleBody(
              count,
              '$chapterNames$suffix',
            )
          : l10n.notificationNewChaptersSingleBody(
              count,
              '$chapterNames$suffix',
            ),
    );
  } else {
    final allAnime = updates.every((u) => u.anime);
    final totalChapters = updates.fold<int>(
      0,
      (sum, u) => sum + u.chapters.length,
    );
    notifService.showNotification(
      id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title: allAnime
          ? l10n.notificationNewEpisodesMultiTitle
          : l10n.notificationNewChaptersMultiTitle,
      body: allAnime
          ? l10n.notificationNewEpisodesMultiBody(totalChapters, updates.length)
          : l10n.notificationNewChaptersMultiBody(
              totalChapters,
              updates.length,
            ),
    );
  }
}

String _formatChapterLabel(MChapter c, AppLocalizations l10n, bool anime) {
  if (c.title.trim().isNotEmpty) return c.title.trim();
  if (c.number != null) {
    final numStr = c.number!.toStringAsFixed(c.number! % 1 == 0 ? 0 : 1);
    return anime
        ? l10n.notificationEpisodeNumber(numStr)
        : l10n.notificationChapterNumber(numStr);
  }
  return anime
      ? l10n.notificationEpisodeFallback
      : l10n.notificationChapterFallback;
}
