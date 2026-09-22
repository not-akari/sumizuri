import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/library/flows/bulk_actions.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

Future<Set<int>?> _pickCategories({
  required BuildContext context,
  required String title,
  required List<Category> categories,
  required Set<int> initiallySelected,
}) async {
  final chosen = await showMultiChoiceSheet(
    context,
    title: title,
    options: [
      for (final category in categories)
        (value: '${category.id}', label: category.name),
    ],
    selected: {for (final id in initiallySelected) '$id'},
  );
  return chosen?.map(int.parse).toSet();
}

Future<int> showBulkEntryCategoriesDialog({
  required BuildContext context,
  required WidgetRef ref,
  required Set<int> entryIds,
  required MediaType mediaType,
}) async {
  final l10n = AppLocalizations.of(context)!;
  final categories =
      ref.read(libraryCategoriesProvider(mediaType: mediaType)).value ??
      const [];
  if (categories.isEmpty) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(l10n.categoriesEmpty)));
    return 0;
  }

  final membership = ref.read(allEntryCategoryIdsProvider).value ?? const {};
  final sharedByAll = categoriesSharedByAll(categories, membership, entryIds);

  final result = await _pickCategories(
    context: context,
    title: l10n.libraryEditCategoriesTitleCount(entryIds.length),
    categories: categories,
    initiallySelected: sharedByAll,
  );
  if (result == null) return 0;

  return setCategoriesForEntries(
    ref.read(libraryRepositoryProvider),
    entryIds,
    result,
  );
}
