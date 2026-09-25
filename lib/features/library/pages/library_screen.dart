import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/formatting/eta.dart';
import 'package:sumizuri/core/utils/formatting/media_type_label.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/features/library/widgets/library_continue_reading.dart';
import 'package:sumizuri/features/library/widgets/library_display_sheet.dart';
import 'package:sumizuri/features/library/widgets/library_header.dart';
import 'package:sumizuri/features/library/widgets/library_search_help.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/library_entry_summary.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/library/migration/migration_page.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/library/widgets/category_smart_rule_editor.dart';
import 'package:sumizuri/features/library/widgets/library_dashboard_sections.dart';
import 'package:sumizuri/features/library/widgets/library_filter_chips.dart';
import 'package:sumizuri/features/library/models/category_membership.dart';
import 'package:sumizuri/features/library/widgets/library_selection_actions.dart';
import 'package:sumizuri/features/library/widgets/library_sort_editor.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/flows/library_update_flow.dart';

class LibraryScreen extends ConsumerStatefulWidget {
  const LibraryScreen({super.key, this.mediaType, this.title});

  final MediaType? mediaType;

  final String? title;

  @override
  ConsumerState<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends ConsumerState<LibraryScreen> {
  MediaType? _filter;

  int? _categoryFilter;

  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  final Set<int> _selectedEntryIds = {};

  final Map<int, MediaType> _selectedEntryMediaTypes = {};

  void _clearSelection() {
    _selectedEntryIds.clear();
    _selectedEntryMediaTypes.clear();
  }

  // Selects all entries in the current tab and active category filter.
  void _selectAllInView(MediaType? type) {
    for (final entry in _entriesInView(type)) {
      _selectedEntryIds.add(entry.id);
      _selectedEntryMediaTypes[entry.id] = entry.mediaType;
    }
  }

  List<LibraryEntrySummary> _entriesInView(MediaType? type) {
    final entries =
        ref.read(libraryEntriesProvider(mediaType: type)).value ??
        const <LibraryEntrySummary>[];
    final chosen = ref.read(categoriesEnabledProvider).value ?? true
        ? _categoryFilter
        : null;
    if (chosen == null) return entries;
    final membership =
        ref.read(allEntryCategoryIdsProvider).value ?? const <int, Set<int>>{};
    return [
      for (final entry in entries)
        if (isInCategory(membership, entry.id, chosen)) entry,
    ];
  }

  void _openRandom(MediaType? type) {
    final entries = _entriesInView(type);
    if (entries.isEmpty) return;
    final pick = entries[Random().nextInt(entries.length)];
    openLibraryEntry(
      context,
      ref,
      libraryEntryId: pick.id,
      title: pick.title,
      coverUrl: pick.coverUrl,
      sourceId: pick.sourceId,
      externalId: pick.externalId,
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final enabledTypes = ref.watch(enabledMediaTypesProvider).orMangaOnly;
    final showFilter = widget.mediaType == null && enabledTypes.length > 1;
    final effectiveType = widget.mediaType ?? (showFilter ? _filter : null);

    final updateProgress = ref.watch(libraryUpdateProgressProvider);
    final needingMigration = ref.watch(entriesNeedingMigrationProvider);
    // Scoped to visible tab; on "All", falls back to first type with entries.
    final migrationType =
        effectiveType ??
        (needingMigration.isEmpty ? null : needingMigration.keys.first);
    final migrationEntries = migrationType == null
        ? const <LibraryEntrySummary>[]
        : needingMigration[migrationType] ?? const [];
    final navDestinations =
        ref.watch(navDestinationsProvider).value ?? const [];
    final categoriesEnabled =
        ref.watch(categoriesEnabledProvider).value ?? true;

    final categoryFilterActive = categoriesEnabled && _categoryFilter != null;
    final showUpdates =
        !navDestinations.contains(NavDestinationKind.updates) &&
        !categoryFilterActive;
    final showHistory =
        !navDestinations.contains(NavDestinationKind.history) &&
        !categoryFilterActive;
    final sectionOrder =
        ref.watch(dashboardSectionOrderProvider).value ??
        const [
          DashboardSectionKind.updates,
          DashboardSectionKind.history,
          DashboardSectionKind.library,
        ];

    final categories = !categoriesEnabled || effectiveType == null
        ? const <Category>[]
        : ref
                  .watch(libraryCategoriesProvider(mediaType: effectiveType))
                  .value ??
              const [];
    final selectionMode = _selectedEntryIds.isNotEmpty;

    Category? activeCategory;
    for (final category in categories) {
      if (category.id == _categoryFilter) {
        activeCategory = category;
        break;
      }
    }

    final mediaTypeRow = showFilter
        ? FilterTabRow<MediaType>(
            allLabel: l10n.libraryTitle,
            selected: _filter,
            items: [
              for (final type in MediaType.values)
                if (enabledTypes.contains(type))
                  (type, mediaTypeLabel(type, l10n)),
            ],

            onSelect: (value) => setState(() {
              _filter = value;
              _categoryFilter = null;
            }),
          )
        : null;
    final hideAllChip = ref.watch(hideAllCategoryChipProvider).value ?? false;
    final hideDefaultChip =
        ref.watch(hideUncategorizedCategoryChipProvider).value ?? false;
    final categoryRow = categories.isEmpty
        ? null
        : FilterTabRow<int>(
            brush: true,
            allLabel: l10n.libraryCategoryAll,
            selected: _categoryFilter,
            showAllChip: !hideAllChip,
            items: [
              if (!hideDefaultChip)
                (uncategorizedCategoryId, l10n.libraryCategoryDefault),
              for (final category in categories) (category.id, category.name),
            ],
            onSelect: (value) => setState(() => _categoryFilter = value),
          );

    return Scaffold(
      body: Stack(
        children: [
          const AmbientBloomBackground(),
          CustomScrollView(
            slivers: [
              if (selectionMode)
                SliverAppBar(
                  backgroundColor: Colors.transparent,
                  surfaceTintColor: Colors.transparent,
                  flexibleSpace: const AmbientAppBarBackdrop(),
                  floating: true,
                  snap: true,
                  pinned: true,
                  leading: IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => setState(_clearSelection),
                  ),
                  title: Text(
                    l10n.librarySelectionCount(_selectedEntryIds.length),
                  ),
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.select_all),
                      tooltip: l10n.librarySelectAll,
                      onPressed: () =>
                          setState(() => _selectAllInView(effectiveType)),
                    ),
                    ...librarySelectionActions(
                      context: context,
                      ref: ref,
                      l10n: l10n,
                      selectedEntryIds: _selectedEntryIds,
                      selectedEntryMediaTypes: _selectedEntryMediaTypes,
                      onDone: () => setState(_clearSelection),
                    ),
                  ],
                )
              else ...[
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).top),
                ),
                SliverToBoxAdapter(
                  child: LibraryHeader(
                    onDisplay: () => showLibraryDisplaySheet(context),
                    displayTooltip: l10n.libraryDisplayButtonTooltip,
                    title: widget.title ?? l10n.libraryTitle,
                    subtitle: l10n.libraryTagline,
                    smartRuleActive: activeCategory?.useSmartRule ?? false,
                    smartRuleTooltip: l10n.categorySmartRuleTooltip,
                    onSmartRuleOrSort: () {
                      final category = activeCategory;
                      if (category != null) {
                        showCategorySmartRuleEditor(context, ref, category);
                      } else {
                        showLibrarySortEditor(context, ref);
                      }
                    },
                    updateProgressLabel: updateProgress == null
                        ? null
                        : (updateProgress.cancelRequested
                              ? l10n.libraryUpdateCancelling
                              : _updateLabel(updateProgress)),
                    updateProgressValue:
                        updateProgress == null || updateProgress.total == 0
                        ? null
                        : updateProgress.processed / updateProgress.total,
                    onCancelUpdate: updateProgress == null
                        ? null
                        : (updateProgress.cancelRequested
                              ? null
                              : () => ref
                                    .read(
                                      libraryUpdateProgressProvider.notifier,
                                    )
                                    .requestCancel()),
                    onRefresh: () {
                      final inView = categoriesEnabled
                          ? _entriesInView(effectiveType)
                          : null;
                      runLibraryUpdate(
                        context,
                        ref,
                        onlyEntryIds: _categoryFilter == null || inView == null
                            ? null
                            : {for (final entry in inView) entry.id},
                      );
                    },
                    onRandom: () => _openRandom(effectiveType),
                    randomTooltip: l10n.libraryOpenRandom,
                    refreshTooltip: categoryFilterActive
                        ? l10n.libraryUpdateCategory
                        : l10n.libraryUpdate,
                  ),
                ),
                if (migrationEntries.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _NeedsMigrationBanner(
                        count: migrationEntries.length,
                        mediaTypeLabel: mediaTypeLabel(migrationType!, l10n),
                        onMigrate: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => MigrationPage(
                              entryIds: {
                                for (final e in migrationEntries) e.id,
                              },
                              mediaType: migrationType,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                    child: AnimatedSearchBar(
                      controller: _searchController,
                      hintText: l10n.librarySearchHint,
                      trailing: const LibrarySearchHelpButton(),
                      onChanged: (value) => setState(() => _query = value),
                      onClear: () => setState(() => _query = ''),
                    ),
                  ),
                ),
                if (mediaTypeRow != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: mediaTypeRow,
                    ),
                  ),
                if (categoryRow != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: categoryRow,
                    ),
                  ),
                SliverToBoxAdapter(
                  child: LibraryContinueReadingRow(
                    mediaType: effectiveType,
                    categoryId: categoriesEnabled ? _categoryFilter : null,
                  ),
                ),
              ],
              for (final kind in sectionOrder)
                ...libraryDashboardSlivers(
                  context: context,
                  kind: kind,
                  mediaType: effectiveType,
                  showUpdates: showUpdates,
                  showHistory: showHistory,
                  l10n: l10n,
                  categoryFilter: categoriesEnabled ? _categoryFilter : null,
                  searchQuery: _query,
                  activeCategory: activeCategory,
                  selectedIds: _selectedEntryIds,
                  onToggleSelect: (id, entryMediaType) => setState(() {
                    if (_selectedEntryIds.remove(id)) {
                      _selectedEntryMediaTypes.remove(id);
                    } else {
                      _selectedEntryIds.add(id);
                      _selectedEntryMediaTypes[id] = entryMediaType;
                    }
                  }),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live query banner nudging migration for entries with missing sources.
class _NeedsMigrationBanner extends StatelessWidget {
  const _NeedsMigrationBanner({
    required this.count,
    required this.mediaTypeLabel,
    required this.onMigrate,
  });

  final int count;
  final String mediaTypeLabel;
  final VoidCallback onMigrate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    // The same soft card the settings rows are, with a hint of accent so it is noticed.
    return AppCard(
      tone: AppCardTone.inset,
      borderColor: cs.primary.withValues(alpha: 0.45),
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cs.primary.withValues(alpha: 0.14),
              border: Border.all(color: cs.primary.withValues(alpha: 0.4)),
              borderRadius: context.shapes.iconTile.radius,
            ),
            alignment: Alignment.center,
            child: Icon(Icons.link_off, size: 19, color: cs.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              l10n.libraryNeedsMigrationBanner(count, mediaTypeLabel),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 8),
          FilledButton.tonal(
            onPressed: onMigrate,
            child: Text(l10n.migrationPromptAction),
          ),
        ],
      ),
    );
  }
}

/// "processed/total", plus a rough time left once a few entries are done.
String _updateLabel(UpdateProgress progress) {
  final count = '${progress.processed}/${progress.total}';
  if (progress.processed == 0 || progress.processed >= progress.total) {
    return count;
  }
  final perEntry =
      DateTime.now().difference(progress.startedAt) ~/ progress.processed;
  final left = perEntry * (progress.total - progress.processed);
  return '$count · ${formatEta(left)}';
}
