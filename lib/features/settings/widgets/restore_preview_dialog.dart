// Shows what a backup contains before it is restored, so nothing is applied blind.
import 'package:flutter/material.dart';

import 'package:sumizuri/features/settings/models/backup_data.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<bool> confirmRestorePreview(
  BuildContext context,
  BackupData data,
) async {
  final l10n = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  final chapters = data.libraryEntries.fold<int>(
    0,
    (sum, e) => sum + e.chapters.length,
  );
  final read = data.libraryEntries.fold<int>(
    0,
    (sum, e) => sum + e.chapters.where((c) => c.consumed).length,
  );
  final sessions = data.libraryEntries.fold<int>(
    0,
    (sum, e) => sum + e.sessions.length,
  );
  final t = data.createdAt.toLocal();
  final created =
      '${t.year}-${t.month.toString().padLeft(2, '0')}-${t.day.toString().padLeft(2, '0')} '
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Widget row(String label, int count) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        Expanded(child: Text(label)),
        Text('$count', style: const TextStyle(fontWeight: FontWeight.w700)),
      ],
    ),
  );

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(l10n.restorePreviewTitle),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.restorePreviewCreated(created),
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
          const SizedBox(height: 12),
          row(l10n.restorePreviewEntries, data.libraryEntries.length),
          row(l10n.restorePreviewChapters, chapters),
          row(l10n.restorePreviewRead, read),
          row(l10n.restorePreviewHistory, sessions),
          row(l10n.restorePreviewSources, data.sources.length),
          row(l10n.restorePreviewCategories, data.categories.length),
          row(l10n.restorePreviewThemes, data.customThemes.length),
          const SizedBox(height: 12),
          Text(
            l10n.restorePreviewMergeNote,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(l10n.browseAddWarningCancel),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(l10n.restorePreviewConfirm),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
