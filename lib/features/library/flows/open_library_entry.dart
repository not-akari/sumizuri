import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/library/migration/migration_page.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_page.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';

void openLibraryEntry(
  BuildContext context,
  WidgetRef ref, {
  required int libraryEntryId,
  required String title,
  required String? coverUrl,
  required String sourceId,
  required String externalId,
  String? heroTag,
}) {
  final l10n = AppLocalizations.of(context)!;
  final logger = ref.read(appLoggerProvider);

  void fail(String message, {Object? error}) {
    logger.warning(message, tag: 'library', error: error);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // Fall back to migration when an entry has no source or its source is uninstalled.
  Future<void> failNeedsMigration(String message, {Object? error}) async {
    logger.warning(message, tag: 'library', error: error);
    final entries = await ref
        .read(libraryRepositoryProvider)
        .watchLibrary()
        .first;
    final mediaType = entries
        .where((e) => e.id == libraryEntryId)
        .firstOrNull
        ?.mediaType;
    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    if (mediaType == null) {
      messenger.showSnackBar(SnackBar(content: Text(message)));
      return;
    }
    messenger.showSnackBar(
      SnackBar(
        content: Text(message),
        action: SnackBarAction(
          label: l10n.migrationPromptAction,
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => MigrationPage(
                entryIds: {libraryEntryId},
                mediaType: mediaType,
              ),
            ),
          ),
        ),
      ),
    );
  }

  try {
    final parsedSourceId = int.tryParse(sourceId);
    if (parsedSourceId == null) {
      unawaited(
        failNeedsMigration(
          l10n.libraryEntryNeedsMigration,
          error: 'bad sourceId "$sourceId"',
        ),
      );
      return;
    }

    final sources = ref.read(installedSourcesProvider).value ?? const [];
    AppInstalledSource? source;
    for (final candidate in sources) {
      if (candidate.id == parsedSourceId) {
        source = candidate;
        break;
      }
    }
    if (source == null) {
      unawaited(
        failNeedsMigration(
          l10n.libraryEntrySourceMissing,
          error: 'sourceId $parsedSourceId not in $sources',
        ),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => EntryDetailPage.fromLibrary(
          entry: MEntry(url: externalId, title: title, coverUrl: coverUrl),
          source: source!,
          libraryEntryId: libraryEntryId,
          heroTag: heroTag,
        ),
      ),
    );
  } catch (error, stackTrace) {
    logger.error(
      'Failed to open library entry',
      tag: 'library',
      error: error,
      stackTrace: stackTrace,
    );
    fail('Failed to open: $error');
  }
}
