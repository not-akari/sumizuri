import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/core/widgets/cards/reorderable_card_row.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

extension on CategoryAction {
  String label(AppLocalizations l10n) => switch (this) {
    CategoryAction.rename => l10n.categoryRename,
    CategoryAction.smartRule => l10n.categorySmartRuleTooltip,
    CategoryAction.toggleExclude => l10n.categoryExcludeFromUpdate,
    CategoryAction.delete => l10n.categoryDelete,
  };
}

enum CategoryAction { rename, smartRule, toggleExclude, delete }

class CategoryRow extends StatelessWidget {
  const CategoryRow({
    super.key,
    required this.category,
    required this.onRename,
    required this.onDelete,
    required this.onToggleExcludeFromUpdate,
    required this.onOpenSmartRule,
    required this.dragIndex,
  });

  final Category category;
  final VoidCallback onRename;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleExcludeFromUpdate;
  final VoidCallback onOpenSmartRule;
  final int dragIndex;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final notes = [
      if (category.useSmartRule) l10n.categorySmartRuleTooltip,
      if (category.excludeFromUpdate) l10n.categoryExcludeFromUpdate,
    ];

    return ReorderableCardRow(
      dragIndex: dragIndex,
      icon: category.useSmartRule ? Icons.tune : Icons.label_outline,
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      title: InkWell(
        onTap: onRename,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                category.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (notes.isNotEmpty)
                Text(
                  notes.join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
            ],
          ),
        ),
      ),
      trailing: [
        AppMenu<CategoryAction>.of(
          values: CategoryAction.values,
          label: (a) => a.label(l10n),
          checked: (a) => a == CategoryAction.toggleExclude
              ? category.excludeFromUpdate
              : null,
          destructive: (a) => a == CategoryAction.delete,
          dividerBefore: (a) => a == CategoryAction.delete,
          onSelected: (action) => switch (action) {
            CategoryAction.rename => onRename(),
            CategoryAction.smartRule => onOpenSmartRule(),
            CategoryAction.toggleExclude => onToggleExcludeFromUpdate(
              !category.excludeFromUpdate,
            ),
            CategoryAction.delete => onDelete(),
          },
        ),
      ],
    );
  }
}
