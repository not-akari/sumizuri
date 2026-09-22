import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/library/models/library_duplicate_match.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/library/flows/auto_download_gate.dart';
import 'package:sumizuri/features/library/flows/chapter_download_flow.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/pages/library_screen.dart';

enum _DuplicateChoice { cancel, addAnyway, migrate }

Future<void> addEntryToLibrary({
  required BuildContext context,
  required WidgetRef ref,
  required MEntry entry,
  required String sourceId,
  required MediaType mediaType,
  ExtensionService? service,
}) async {
  final repository = ref.read(libraryRepositoryProvider);

  final matchResult = await repository.checkLibraryMatch(
    title: entry.title,
    sourceId: sourceId,
    externalId: entry.url,
  );
  if (!context.mounted) return;

  final match = matchResult.valueOrNull;
  if (match == null) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(matchResult.errorOrNull!.displayMessage)),
    );
    return;
  }

  if (match.isExactMatch) {
    _showAlreadyInLibraryDialog(context);
    return;
  }

  if (match.hasPossibleDuplicates) {
    await _showPossibleDuplicateDialog(
      context,
      ref,
      entry,
      sourceId,
      mediaType,
      match.otherSourceMatches.first,
      service,
    );
    return;
  }

  await _insertToLibrary(context, ref, entry, sourceId, mediaType, service);
}

Future<void> _insertToLibrary(
  BuildContext context,
  WidgetRef ref,
  MEntry entry,
  String sourceId,
  MediaType mediaType,
  ExtensionService? service,
) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await ref
      .read(libraryRepositoryProvider)
      .addToLibrary(
        title: entry.title,
        coverUrl: entry.coverUrl,
        mediaType: mediaType,
        sourceId: sourceId,
        externalId: entry.url,
      );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isOk
            ? l10n.sourceBrowseAddedToLibrary(entry.title)
            : result.errorOrNull!.displayMessage,
      ),
    ),
  );

  if (result.isOk &&
      service != null &&
      (ref.read(autoDownloadOnAddToLibraryProvider).value ?? false)) {
    final container = ProviderScope.containerOf(context, listen: false);
    unawaited(_autoDownloadNewEntry(container, service, entry, sourceId));
  }
}

Future<void> _autoDownloadNewEntry(
  ProviderContainer container,
  ExtensionService service,
  MEntry entry,
  String sourceId,
) async {
  final matchResult = await container
      .read(libraryRepositoryProvider)
      .checkLibraryMatch(
        title: entry.title,
        sourceId: sourceId,
        externalId: entry.url,
      );
  final entryId = matchResult.valueOrNull?.exactMatchId;
  if (entryId == null) return;

  final chaptersResult = await service.getChapterList(entry);
  final chapters = chaptersResult.valueOrNull;
  if (chapters == null || chapters.isEmpty) return;

  await container
      .read(libraryRepositoryProvider)
      .syncChapters(
        libraryEntryId: entryId,
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

  if (!await canAutoDownloadNow(container)) return;
  await downloadAllChapters(
    container: container,
    service: service,
    libraryEntryId: entryId,
    sourceId: sourceId,
    entryTitle: entry.title,
    chapters: await capAutoDownloadChapters(
      chapters,
      container,
      libraryEntryId: entryId,
    ),
  );
}

Future<bool> removeEntryFromLibrary({
  required BuildContext context,
  required WidgetRef ref,
  required int entryId,
  required String title,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: l10n.sourceBrowseRemoveConfirmTitle,
    message: l10n.sourceBrowseRemoveConfirmMessage(title),
    confirmLabel: l10n.sourceBrowseRemoveFromLibrary,
    isDestructive: true,
  );
  if (!confirmed || !context.mounted) return false;

  final result = await ref
      .read(libraryRepositoryProvider)
      .removeFromLibrary(entryId);
  if (!context.mounted) return result.isOk;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isOk
            ? l10n.sourceBrowseRemovedFromLibrary(title)
            : result.errorOrNull!.displayMessage,
      ),
    ),
  );
  return result.isOk;
}

void _showAlreadyInLibraryDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context)!;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(l10n.sourceBrowseAlreadyInLibraryMessage),
      // A snackbar with an action stays until dismissed unless told otherwise.
      persist: false,
      action: SnackBarAction(
        label: l10n.sourceBrowseViewLibrary,
        onPressed: () {
          if (context.mounted) {
            Navigator.of(context)
                .push(MaterialPageRoute(builder: (_) => const LibraryScreen()));
          }
        },
      ),
    ),
  );
}

Future<void> _showPossibleDuplicateDialog(
  BuildContext context,
  WidgetRef ref,
  MEntry entry,
  String sourceId,
  MediaType mediaType,
  LibraryDuplicateCandidate candidate,
  ExtensionService? service,
) async {
  final l10n = AppLocalizations.of(context)!;
  final choice = await showDialog<_DuplicateChoice>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.sourceBrowsePossibleDuplicateTitle),
      content: Text(l10n.sourceBrowsePossibleDuplicateMessage(candidate.title)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(_DuplicateChoice.cancel),
          child: Text(l10n.browseAddWarningCancel),
        ),
        TextButton(
          onPressed: () =>
              Navigator.of(context).pop(_DuplicateChoice.addAnyway),
          child: Text(l10n.sourceBrowseAddAnyway),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_DuplicateChoice.migrate),
          child: Text(l10n.sourceBrowseMigrate),
        ),
      ],
    ),
  );
  if (!context.mounted || choice == null || choice == _DuplicateChoice.cancel) {
    return;
  }

  if (choice == _DuplicateChoice.addAnyway) {
    await _insertToLibrary(context, ref, entry, sourceId, mediaType, service);
    return;
  }

  final result = await ref
      .read(libraryRepositoryProvider)
      .migrateLibraryEntry(
        entryId: candidate.id,
        sourceId: sourceId,
        externalId: entry.url,
        mediaType: mediaType,
        coverUrl: entry.coverUrl,
      );
  if (!context.mounted) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(
        result.isOk
            ? l10n.sourceBrowseMigrated(candidate.title)
            : result.errorOrNull!.displayMessage,
      ),
    ),
  );
}
