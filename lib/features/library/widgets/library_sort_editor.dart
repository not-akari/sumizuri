import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/library/widgets/category_smart_rule_editor.dart';

Future<void> showLibrarySortEditor(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  var sortField =
      ref.read(librarySortFieldProvider).value ??
      CategorySortField.lastUpdatedAt;
  var sortAscending = ref.read(librarySortAscendingProvider).value ?? false;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.librarySortEditorTitle,
              style: Theme.of(sheetContext).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            AppChoice<CategorySortField>.of(
              style: AppChoiceStyle.menu,
              labelText: l10n.categorySmartRuleSortLabel,
              values: CategorySortField.values,
              label: (field) => categorySortFieldLabel(field, l10n),
              value: sortField,
              onChanged: (field) => setSheetState(() => sortField = field),
            ),
            const SizedBox(height: 12),
            CategorySortDirectionChoice(
              ascending: sortAscending,
              onChanged: (ascending) =>
                  setSheetState(() => sortAscending = ascending),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final repository = ref.read(settingsRepositoryProvider);
                  await repository.setLibrarySortField(sortField);
                  await repository.setLibrarySortAscending(sortAscending);
                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                },
                child: Text(l10n.categorySmartRuleSave),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
