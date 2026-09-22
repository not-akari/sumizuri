import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/core/widgets/overlays/dialog_with_controller.dart';

Future<String?> promptForCategoryName(
  BuildContext context,
  AppLocalizations l10n, {
  required String initial,
}) {
  return showAppTextFieldDialog(
    context: context,
    title: l10n.categoriesAdd,
    initialText: initial,
    hint: l10n.categoryNameHint,
    confirmLabel: l10n.categoriesAdd,
    trim: false,
  );
}

Future<void> addCategory(
  BuildContext context,
  WidgetRef ref,
  MediaType mediaType,
) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await promptForCategoryName(context, l10n, initial: '');
  if (name == null || name.trim().isEmpty) return;
  await ref
      .read(libraryRepositoryProvider)
      .createCategory(name.trim(), mediaType: mediaType);
}

Future<void> renameCategory(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final l10n = AppLocalizations.of(context)!;
  final name = await promptForCategoryName(
    context,
    l10n,
    initial: category.name,
  );
  if (name == null || name.trim().isEmpty) return;
  await ref
      .read(libraryRepositoryProvider)
      .renameCategory(id: category.id, name: name.trim());
}

Future<void> deleteCategory(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final l10n = AppLocalizations.of(context)!;
  final confirmed = await showAppConfirmDialog(
    context: context,
    title: l10n.categoryDeleteConfirmTitle,
    message: l10n.categoryDeleteConfirmMessage(category.name),
    confirmLabel: l10n.categoryDelete,
    isDestructive: true,
  );
  if (confirmed) {
    await ref.read(libraryRepositoryProvider).deleteCategory(category.id);
  }
}
