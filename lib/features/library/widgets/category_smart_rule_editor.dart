import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

String categorySortFieldLabel(CategorySortField field, AppLocalizations l10n) =>
    switch (field) {
      CategorySortField.title => l10n.categorySmartRuleSortTitle,
      CategorySortField.unreadCount => l10n.categorySmartRuleSortUnreadCount,
      CategorySortField.addedAt => l10n.categorySmartRuleSortAddedAt,
      CategorySortField.lastUpdatedAt =>
        l10n.categorySmartRuleSortLastUpdatedAt,
    };

/// Ascending or descending, shared by the library sort sheet and the category rule sheet.
class CategorySortDirectionChoice extends StatelessWidget {
  const CategorySortDirectionChoice({
    super.key,
    required this.ascending,
    required this.onChanged,
    this.padded = false,
  });

  final bool ascending;
  final ValueChanged<bool> onChanged;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppChoice<bool>(
      style: AppChoiceStyle.pills,
      padded: padded,
      options: [
        AppChoiceOption(
          true,
          l10n.categorySmartRuleAscending,
          icon: Icons.arrow_upward,
        ),
        AppChoiceOption(
          false,
          l10n.categorySmartRuleDescending,
          icon: Icons.arrow_downward,
        ),
      ],
      value: ascending,
      onChanged: onChanged,
    );
  }
}

String categoryStatusFilterLabel(
  CategoryStatusFilter filter,
  AppLocalizations l10n,
) => switch (filter) {
  CategoryStatusFilter.any => l10n.categorySmartRuleStatusAny,
  CategoryStatusFilter.ongoing => l10n.categorySmartRuleStatusOngoing,
  CategoryStatusFilter.completed => l10n.categorySmartRuleStatusCompleted,
  CategoryStatusFilter.hiatus => l10n.categorySmartRuleStatusHiatus,
};

Future<void> showCategorySmartRuleEditor(
  BuildContext context,
  WidgetRef ref,
  Category category,
) async {
  final l10n = AppLocalizations.of(context)!;
  var useSmartRule = category.useSmartRule;
  var sortField = category.sortField;
  var sortAscending = category.sortAscending;
  var statusFilter = category.statusFilter;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (sheetContext) => StatefulBuilder(
      builder: (sheetContext, setSheetState) => Padding(
        padding: EdgeInsets.only(
          bottom: 20 + MediaQuery.of(sheetContext).viewInsets.bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppSheetHeader(title: l10n.categorySmartRuleTitle(category.name)),
            AppSwitchRow(
              icon: Icons.tune,
              title: l10n.categorySmartRuleEnable,
              value: useSmartRule,
              onChanged: (value) => setSheetState(() => useSmartRule = value),
            ),
            AppChoice<CategoryStatusFilter>.of(
              title: l10n.categorySmartRuleStatusLabel,
              padded: true,
              style: AppChoiceStyle.pills,
              values: CategoryStatusFilter.values,
              label: (filter) => categoryStatusFilterLabel(filter, l10n),
              icon: (_) => Icons.flag_outlined,
              value: statusFilter,
              onChanged: (filter) => setSheetState(() => statusFilter = filter),
            ),
            AppChoice<CategorySortField>.of(
              title: l10n.categorySmartRuleSortLabel,
              padded: true,
              style: AppChoiceStyle.pills,
              values: CategorySortField.values,
              label: (field) => categorySortFieldLabel(field, l10n),
              icon: (_) => Icons.sort,
              value: sortField,
              onChanged: (field) => setSheetState(() => sortField = field),
            ),
            CategorySortDirectionChoice(
              ascending: sortAscending,
              padded: true,
              onChanged: (ascending) =>
                  setSheetState(() => sortAscending = ascending),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: context.layout.gutter),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () async {
                    await ref
                        .read(libraryRepositoryProvider)
                        .setCategorySmartRule(
                          id: category.id,
                          useSmartRule: useSmartRule,
                          sortField: sortField,
                          sortAscending: sortAscending,
                          statusFilter: statusFilter,
                        );
                    if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                  },
                  child: Text(l10n.categorySmartRuleSave),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
