import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/library/flows/download_queue.dart';
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/download_plan.dart';
import 'package:sumizuri/features/settings/pages/download_queue_page.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

export 'package:sumizuri/features/library/flows/download_queue.dart'
    show downloadKey, downloadingChaptersProvider, downloadProgressProvider;

/// Puts chapters or episodes in the download queue and returns at once.
Future<int> downloadAllChapters({
  required ProviderContainer container,
  required ExtensionService service,
  required int libraryEntryId,
  required String sourceId,
  required String entryTitle,
  required List<MChapter> chapters,
}) async {
  var wanted = chapters;
  // Leave out a chapter that only duplicates one already read, if that is asked for.
  final skipDuplicates = await container
      .read(settingsRepositoryProvider)
      .watchSetting(Settings.downloadsSkipDuplicateRead)
      .first;
  if (skipDuplicates) {
    final records =
        (await container
                .read(libraryRepositoryProvider)
                .getAllChapters(libraryEntryId))
            .valueOrNull ??
        const [];
    wanted = withoutDuplicateReads(
      chapters,
      readNumbers: {
        for (final r in records)
          if (r.consumed) r.number,
      },
      numberOf: (c) => c.number,
      isRead: (c) => c.read,
    );
  }
  return container
      .read(downloadQueueProvider.notifier)
      .enqueue(
        libraryEntryId: libraryEntryId,
        sourceId: sourceId,
        entryTitle: entryTitle,
        mediaType: service.info.mediaType,
        chapters: wanted,
      );
}

Future<void> downloadChapter({
  required BuildContext context,
  required WidgetRef ref,
  required ExtensionService service,
  required int libraryEntryId,
  required String sourceId,
  required String entryTitle,
  required MChapter chapter,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  final navigator = Navigator.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final added = await downloadAllChapters(
    container: container,
    service: service,
    libraryEntryId: libraryEntryId,
    sourceId: sourceId,
    entryTitle: entryTitle,
    chapters: [chapter],
  );
  messenger.showSnackBar(
    SnackBar(
      content: Text(l10n.downloadQueueAdded(added)),
      action: SnackBarAction(
        label: l10n.downloadQueueView,
        onPressed: () => navigator.push(
          MaterialPageRoute<void>(builder: (_) => const DownloadQueuePage()),
        ),
      ),
    ),
  );
}

Future<void> deleteChapterDownload({
  required LibraryRepository repository,
  required int libraryEntryId,
  required String chapterUrl,
  required String localPath,
}) async {
  final dir = Directory(localPath);
  await deleteIfExists(dir, recursive: true);
  await repository.setChapterLocalPath(
    libraryEntryId: libraryEntryId,
    chapterUrl: chapterUrl,
    path: null,
  );
}
