import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/bulk_actions.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/migration/migration_page.dart';
import 'package:sumizuri/features/library/widgets/entry_categories_dialog.dart';

List<Widget> librarySelectionActions({
  required BuildContext context,
  required WidgetRef ref,
  required AppLocalizations l10n,
  required Set<int> selectedEntryIds,
  required Map<int, MediaType> selectedEntryMediaTypes,
  required VoidCallback onDone,
}) {
  Future<void> bulkCategorize() async {
    final selectedTypes = selectedEntryMediaTypes.values.toSet();
    if (selectedTypes.length > 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.libraryBulkCategoriesMixedTypes)),
      );
      return;
    }
    final failed = await showBulkEntryCategoriesDialog(
      context: context,
      ref: ref,
      entryIds: {...selectedEntryIds},
      mediaType: selectedTypes.single,
    );
    if (!context.mounted) return;
    onDone();
    if (failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.libraryBulkCategoriesFailed(failed))),
      );
    }
  }

  Future<void> bulkMigrate() async {
    final selectedTypes = selectedEntryMediaTypes.values.toSet();
    if (selectedTypes.length != 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.libraryBulkMigrateMixedTypes)),
      );
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => MigrationPage(
          entryIds: {...selectedEntryIds},
          mediaType: selectedTypes.single,
        ),
      ),
    );
    if (context.mounted) onDone();
  }

  Future<void> bulkRemove() async {
    final count = selectedEntryIds.length;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.libraryBulkRemoveConfirmTitle,
      message: l10n.libraryBulkRemoveConfirmMessage(count),
      confirmLabel: l10n.sourceBrowseRemoveFromLibrary,
      isDestructive: true,
    );
    if (!confirmed) return;

    final failed = await removeEntries(
      ref.read(libraryRepositoryProvider),
      selectedEntryIds,
    );
    if (!context.mounted) return;
    onDone();
    if (failed > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.libraryBulkRemoveFailed(failed))),
      );
    }
  }

  return [
    IconButton(
      icon: const Icon(Icons.label_outline),
      tooltip: l10n.categoriesTitle,
      onPressed: bulkCategorize,
    ),
    IconButton(
      icon: const Icon(Icons.swap_horiz),
      tooltip: l10n.libraryBulkMigrate,
      onPressed: bulkMigrate,
    ),
    IconButton(
      icon: const Icon(Icons.delete_outline),
      tooltip: l10n.sourceBrowseRemoveFromLibrary,
      onPressed: bulkRemove,
    ),
  ];
}
