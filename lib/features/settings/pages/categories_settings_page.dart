import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/utils/formatting/media_type_label.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/cards/reorderable_card_row.dart'
    show reorderableCardProxyDecorator;
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/widgets/category_smart_rule_editor.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/widgets/category_crud.dart';
import 'package:sumizuri/features/settings/widgets/category_row.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class CategoriesSettingsPage extends ConsumerStatefulWidget {
  const CategoriesSettingsPage({super.key});

  @override
  ConsumerState<CategoriesSettingsPage> createState() =>
      _CategoriesSettingsPageState();
}

class _CategoriesSettingsPageState
    extends ConsumerState<CategoriesSettingsPage> {
  int _typeIndex = 0;

  Widget _options(AppLocalizations l10n, bool enabled) {
    final repo = ref.read(settingsRepositoryProvider);
    final hideAll = ref.watch(hideAllCategoryChipProvider).value ?? false;
    final hideDefault =
        ref.watch(hideUncategorizedCategoryChipProvider).value ?? false;
    return Column(
      children: [
        AppSwitchRow(
          icon: Icons.category_outlined,
          title: l10n.categoriesEnableTitle,
          subtitle: l10n.categoriesEnableHint,
          value: enabled,
          onChanged: repo.setCategoriesEnabled,
        ),
        if (enabled) ...[
          AppSwitchRow(
            icon: Icons.filter_alt_off_outlined,
            title: l10n.categoriesHideAllChip,
            value: hideAll,
            onChanged: repo.setHideAllCategoryChip,
          ),
          AppSwitchRow(
            icon: Icons.visibility_off_outlined,
            title: l10n.categoriesHideDefaultChip,
            value: hideDefault,
            onChanged: repo.setHideUncategorizedCategoryChip,
          ),
        ],
      ],
    );
  }

  Widget _emptyState(AppLocalizations l10n, MediaType type) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 16),
      child: Column(
        children: [
          Icon(Icons.label_off_outlined, size: 40, color: cs.outlineVariant),
          const SizedBox(height: 12),
          Text(
            l10n.categoriesEmpty,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 16),
          FilledButton.tonalIcon(
            onPressed: () => addCategory(context, ref, type),
            icon: const Icon(Icons.add, size: 18),
            label: Text(l10n.categoriesAdd),
          ),
        ],
      ),
    );
  }

  Widget _categoryList(AppLocalizations l10n, MediaType type, bool enabled) {
    final categories =
        ref.watch(libraryCategoriesProvider(mediaType: type)).value ?? const [];
    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _options(l10n, enabled),
        if (enabled && categories.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: AppSectionLabel(
              label: '${l10n.categoriesTitle} · ${categories.length}',
            ),
          ),
      ],
    );

    if (!enabled) {
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        children: [
          header,
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              l10n.categoriesDisabledMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.outline,
              ),
            ),
          ),
        ],
      );
    }
    if (categories.isEmpty) {
      return ListView(
        padding: const EdgeInsets.only(top: 8, bottom: 96),
        children: [header, _emptyState(l10n, type)],
      );
    }

    return ReorderableListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      header: header,
      footer: AppListRow(
        icon: Icons.add,
        title: l10n.categoriesAdd,
        onTap: () => addCategory(context, ref, type),
      ),
      itemCount: categories.length,
      buildDefaultDragHandles: false,
      onReorderItem: (oldIndex, newIndex) {
        final ids = categories.map((c) => c.id).toList();
        ids.insert(newIndex, ids.removeAt(oldIndex));
        ref.read(libraryRepositoryProvider).reorderCategories(ids);
      },
      proxyDecorator: reorderableCardProxyDecorator,
      itemBuilder: (context, index) {
        final category = categories[index];
        return Padding(
          key: ValueKey(category.id),
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            0,
            context.layout.gutter,
            8,
          ),
          child: CategoryRow(
            dragIndex: index,
            category: category,
            onRename: () => renameCategory(context, ref, category),
            onDelete: () => deleteCategory(context, ref, category),
            onToggleExcludeFromUpdate: (exclude) => ref
                .read(libraryRepositoryProvider)
                .setCategoryExcludeFromUpdate(
                  id: category.id,
                  exclude: exclude,
                ),
            onOpenSmartRule: () =>
                showCategorySmartRuleEditor(context, ref, category),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabledTypes = ref.watch(enabledMediaTypesProvider).orMangaOnly;
    final types = [
      for (final type in MediaType.values)
        if (enabledTypes.contains(type)) type,
    ];
    final enabled = ref.watch(categoriesEnabledProvider).value ?? true;
    final index = types.isEmpty ? 0 : _typeIndex.clamp(0, types.length - 1);
    final type = types.isEmpty ? null : types[index];

    return AmbientScaffold(
      maxContentWidth: 720,
      title: Text(l10n.categoriesTitle),
      actions: [
        if (enabled && type != null)
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: l10n.categoriesAdd,
            onPressed: () => addCategory(context, ref, type),
          ),
      ],
      body: Column(
        children: [
          if (enabled && types.length > 1)
            SquiggleTabBar(
              labels: [for (final t in types) mediaTypeLabel(t, l10n)],
              activeIndex: index,
              showUnderline: false,
              onSelected: (i) => setState(() => _typeIndex = i),
            ),
          Expanded(
            child: type == null
                ? const SizedBox.shrink()
                : _categoryList(l10n, type, enabled),
          ),
        ],
      ),
    );
  }
}
