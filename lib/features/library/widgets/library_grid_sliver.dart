import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/library/models/library_search.dart';
import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/library/widgets/library_dashboard_previews.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/library/models/downloaded_entry.dart';
import 'package:sumizuri/features/library/models/category_membership.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';

class LibraryGridSliver extends ConsumerStatefulWidget {
  const LibraryGridSliver({
    super.key,
    required this.mediaType,
    this.categoryId,
    this.category,
    required this.selectedIds,
    required this.onToggleSelect,
    this.searchQuery = '',
  });

  final String searchQuery;
  final MediaType? mediaType;
  final int? categoryId;
  final Category? category;
  final Set<int> selectedIds;
  final void Function(int entryId, MediaType mediaType) onToggleSelect;

  @override
  ConsumerState<LibraryGridSliver> createState() => _LibraryGridSliverState();
}

class _LibraryGridSliverState extends ConsumerState<LibraryGridSliver>
    with SingleTickerProviderStateMixin {
  late final _fade = AnimationController(
    vsync: this,
    duration: AppMotion.medium,
    value: 1,
  );

  @override
  void didUpdateWidget(covariant LibraryGridSliver oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.categoryId != widget.categoryId) {
      _fade.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mediaType = widget.mediaType;
    final categoryId = widget.categoryId;
    final selectedIds = widget.selectedIds;
    final onToggleSelect = widget.onToggleSelect;
    final l10n = AppLocalizations.of(context)!;
    final gestures =
        ref.watch(appGesturesProvider).value ?? AppGestures.defaults;
    final entriesAsync = ref.watch(
      libraryEntriesProvider(mediaType: mediaType),
    );
    final categoryMembership =
        ref.watch(allEntryCategoryIdsProvider).value ?? const {};
    final tileSize =
        ref.watch(libraryGridTileSizeProvider).value ??
        LibraryGridTileSize.medium;
    final showUnread =
        ref.watch(boolSettingProvider(Settings.libraryShowUnreadBadge)).value ??
        true;
    final showDownloads =
        ref
            .watch(boolSettingProvider(Settings.libraryShowDownloadBadge))
            .value ??
        false;
    final downloadedCounts = showDownloads
        ? {
            for (final e
                in ref.watch(downloadedEntriesProvider).value ??
                    const <DownloadedEntry>[])
              e.entryId: e.chapters.length,
          }
        : const <int, int>{};
    final byCategory = categoryId == null
        ? entriesAsync
        : entriesAsync.whenData(
            (items) => items
                .where(
                  (item) =>
                      isInCategory(categoryMembership, item.id, categoryId),
                )
                .toList(),
          );
    final search = LibrarySearch.parse(widget.searchQuery);
    final sourceNames = {
      for (final source
          in ref.watch(installedSourcesProvider).value ??
              const <AppInstalledSource>[])
        '${source.id}': source.name,
    };
    final categoryNames = <int, String>{
      for (final type in MediaType.values)
        for (final c
            in ref.watch(libraryCategoriesProvider(mediaType: type)).value ??
                const <Category>[])
          c.id: c.name,
    };
    final searched = search.isEmpty
        ? byCategory
        : byCategory.whenData(
            (items) => items
                .where(
                  (item) => search.matches(
                    LibrarySearchTarget(
                      title: item.title,
                      status: item.status,
                      sourceName: sourceNames[item.sourceId],
                      categoryNames: [
                        for (final id
                            in categoryMembership[item.id] ?? const {})
                          ?categoryNames[id],
                      ],
                      mediaType: item.mediaType.name,
                      favorite: item.favorite,
                      unread: item.unreadCount,
                    ),
                  ),
                )
                .toList(),
          );
    final category = widget.category;
    final librarySortField =
        ref.watch(librarySortFieldProvider).value ??
        CategorySortField.lastUpdatedAt;
    final librarySortAscending =
        ref.watch(librarySortAscendingProvider).value ?? false;
    final entries = category == null
        ? searched.whenData(
            (items) => sortLibraryEntries(
              items,
              librarySortField,
              librarySortAscending,
            ),
          )
        : searched.whenData((items) => applyCategorySmartRule(items, category));

    return entries.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (error, stackTrace) =>
          SliverToBoxAdapter(child: ErrorView(message: '$error')),
      data: (items) {
        if (items.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Text(
                  l10n.libraryEmpty,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
          );
        }
        return SliverFadeTransition(
          opacity: _fade,
          sliver: SliverPadding(
            padding: EdgeInsets.fromLTRB(
              12,
              12,
              12,
              12 + MediaQuery.paddingOf(context).bottom,
            ),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: tileSize.maxExtent,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.55,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final item = items[index];
                final heroTag = dashboardHeroTag('library', item.id);
                final selected = selectedIds.contains(item.id);
                final selectionMode = selectedIds.isNotEmpty;
                void toggle() => onToggleSelect(item.id, item.mediaType);
                void open() => openLibraryEntry(
                  context,
                  ref,
                  libraryEntryId: item.id,
                  title: item.title,
                  coverUrl: item.coverUrl,
                  sourceId: item.sourceId,
                  externalId: item.externalId,
                  heroTag: heroTag,
                );
                void run(LibraryCoverAction action) {
                  switch (action) {
                    case LibraryCoverAction.open:
                      open();
                    case LibraryCoverAction.select:
                      toggle();
                    case LibraryCoverAction.none:
                      break;
                  }
                }

                return MangaCoverTile(
                  title: item.title,
                  coverUrl: item.coverUrl,
                  customCoverPath: item.customCoverPath,
                  unreadCount: showUnread && item.unreadCount > 0
                      ? item.unreadCount
                      : null,
                  downloadedCount: downloadedCounts[item.id],
                  status: item.status,
                  heroTag: selectionMode ? null : heroTag,
                  selected: selected,
                  selectable: selectionMode,
                  onTap: selectionMode
                      ? toggle
                      : () => run(gestures.libraryTap),
                  onLongPress: selectionMode
                      ? toggle
                      : () => run(gestures.libraryLongPress),
                  onDoubleTap:
                      selectionMode ||
                          gestures.libraryDoubleTap == LibraryCoverAction.none
                      ? null
                      : () => run(gestures.libraryDoubleTap),
                );
              }, childCount: items.length),
            ),
          ),
        );
      },
    );
  }
}
