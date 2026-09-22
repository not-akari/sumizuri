// Snackbar offering mass migration for newly imported titles without a source.
import 'package:flutter/material.dart';

import 'package:sumizuri/features/library/migration/migration_page.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Displays [message] with a "Migrate now" action if [addedIds] is non-empty.
void showMigratePrompt(
  BuildContext context,
  String message,
  Map<MediaType, Set<int>> addedIds,
) {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  if (addedIds.isEmpty) {
    messenger.showSnackBar(SnackBar(content: Text(message)));
    return;
  }
  final entry = addedIds.entries.first;
  messenger.showSnackBar(
    SnackBar(
      content: Text('$message ${l10n.migrationPromptHint}'),
      duration: const Duration(seconds: 10),
      action: SnackBarAction(
        label: l10n.migrationPromptAction,
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) =>
                MigrationPage(entryIds: entry.value, mediaType: entry.key),
          ),
        ),
      ),
    ),
  );
}
