import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// One category as a soft card: its name, what is special about it, and a
/// handle to reorder it. Tapping it opens what can be done to it.
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

  void _showActions(BuildContext context) {
    showAppSheet<void>(
      context,
      builder: (sheetContext) => _CategoryActionsSheet(
        category: category,
        onRename: () {
          Navigator.of(sheetContext).pop();
          onRename();
        },
        onOpenSmartRule: () {
          Navigator.of(sheetContext).pop();
          onOpenSmartRule();
        },
        onToggleExcludeFromUpdate: onToggleExcludeFromUpdate,
        onDelete: () {
          Navigator.of(sheetContext).pop();
          onDelete();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final notes = [
      if (category.useSmartRule) l10n.categorySmartRuleTooltip,
      if (category.excludeFromUpdate) l10n.categoryExcludeFromUpdate,
    ];
    return AppListRow(
      icon: category.useSmartRule ? Icons.tune : Icons.label_outline,
      title: category.name,
      subtitle: notes.isEmpty ? null : notes.join(' · '),
      onTap: () => _showActions(context),
      trailing: ReorderableDragStartListener(
        index: dragIndex,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(Icons.drag_handle, color: cs.outline),
        ),
      ),
    );
  }
}

/// What can be done to a category. The switch keeps its own copy of the
/// value, since the sheet is not rebuilt when the category changes.
class _CategoryActionsSheet extends StatefulWidget {
  const _CategoryActionsSheet({
    required this.category,
    required this.onRename,
    required this.onOpenSmartRule,
    required this.onToggleExcludeFromUpdate,
    required this.onDelete,
  });

  final Category category;
  final VoidCallback onRename;
  final VoidCallback onOpenSmartRule;
  final ValueChanged<bool> onToggleExcludeFromUpdate;
  final VoidCallback onDelete;

  @override
  State<_CategoryActionsSheet> createState() => _CategoryActionsSheetState();
}

class _CategoryActionsSheetState extends State<_CategoryActionsSheet> {
  late bool _exclude = widget.category.excludeFromUpdate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AppSheet(
      title: widget.category.name,
      children: [
        AppListRow(
          icon: Icons.edit_outlined,
          title: l10n.categoryRename,
          onTap: widget.onRename,
        ),
        AppListRow(
          icon: Icons.tune,
          title: l10n.categorySmartRuleTooltip,
          subtitle: widget.category.useSmartRule
              ? l10n.categorySmartRuleEnable
              : null,
          onTap: widget.onOpenSmartRule,
        ),
        AppSwitchRow(
          icon: Icons.sync_disabled_outlined,
          title: l10n.categoryExcludeFromUpdate,
          value: _exclude,
          onChanged: (value) {
            setState(() => _exclude = value);
            widget.onToggleExcludeFromUpdate(value);
          },
        ),
        AppListRow(
          icon: Icons.delete_outline,
          iconColor: cs.error,
          title: l10n.categoryDelete,
          onTap: widget.onDelete,
        ),
      ],
    );
  }
}
