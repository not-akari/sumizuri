import 'package:sumizuri/features/extensions/entry_detail/entry_media_wording.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/entry_detail/chapter_gap_indicator.dart';
import 'package:sumizuri/features/extensions/entry_detail/chapter_grid_cell.dart';
import 'package:sumizuri/features/extensions/entry_detail/chapter_list_skeleton.dart';
import 'package:sumizuri/features/extensions/entry_detail/chapter_list_tile.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_widgets.dart';

export 'package:sumizuri/features/extensions/entry_detail/chapter_duplicates.dart';
export 'package:sumizuri/features/extensions/entry_detail/chapter_gap_indicator.dart';
export 'package:sumizuri/features/extensions/entry_detail/chapter_grid_cell.dart'
    show ChapterGridCell, formatChapterDateLine;
export 'package:sumizuri/features/extensions/entry_detail/chapter_list_mapping.dart';
export 'package:sumizuri/features/extensions/entry_detail/chapter_list_skeleton.dart'
    show ChapterListSkeleton;
export 'package:sumizuri/features/extensions/entry_detail/chapter_list_tile.dart'
    show formatChapterSubtitle, buildChapterSubtitleWithProgress;

List<Widget> buildChapterSlivers({
  required BuildContext context,
  required AppLocalizations l10n,
  required MediaType mediaType,
  required List<MChapter>? chapters,
  required ChapterListLayout layout,
  required bool hasChapterComments,
  required int? libraryEntryId,
  required String? sourceId,
  required String entryTitle,
  required dynamic service,
  Widget? branchSelector,
  String? seasonHeading,
  VoidCallback? onLeaveSeason,
  required VoidCallback? onRefresh,
  int duplicateCount = 0,
  bool hidingDuplicates = false,
  VoidCallback? onToggleDuplicates,
  bool sortAscending = false,
  VoidCallback? onToggleSort,
  Widget? overflowMenu,
  required void Function(MChapter) onOpenChapter,
  required void Function(MChapter) onOpenChapterComments,
  Set<String> selectedChapterUrls = const {},
  void Function(MChapter)? onChapterLongPress,
  void Function(MChapter)? onChapterTap,
  AppGestures gestures = AppGestures.defaults,
  void Function(MChapter, ChapterRowAction)? onChapterAction,
}) {
  final isSelectionMode = selectedChapterUrls.isNotEmpty;
  // The list layout marks each break inline, between the chapters it falls
  // between; the grid has no such spot, so it keeps one summary line on top.
  final missingChaptersSummary =
      chapters == null || layout != ChapterListLayout.grid
      ? null
      : missingChaptersSummarySliver(context, l10n, chapters);
  final gaps = chapters == null || layout == ChapterListLayout.grid
      ? (after: const <List<int>>[], before: const <int>[])
      : chapterGaps(chapters);

  return [
    if (branchSelector != null) SliverToBoxAdapter(child: branchSelector),
    SliverToBoxAdapter(
      child: Padding(
        padding: EdgeInsets.fromLTRB(onLeaveSeason == null ? 20 : 4, 16, 12, 8),
        child: Row(
          children: [
            if (onLeaveSeason != null)
              IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: l10n.seasonBack,
                onPressed: onLeaveSeason,
              ),
            Expanded(
              child: Text(
                chapters == null
                    ? l10n.chaptersHeading(mediaType)
                    : seasonHeading != null
                    ? '$seasonHeading · ${l10n.chapterCount(mediaType, chapters.length)}'
                    : l10n.chapterCount(mediaType, chapters.length),
                style: TextStyle(
                  fontFamily: context.displayFont,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: Icon(
                sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 20,
              ),
              tooltip: l10n.chapterMenuSort,
              onPressed: onToggleSort,
            ),
            IconButton(
              icon: const Icon(Icons.refresh, size: 20),
              tooltip: l10n.sourceBrowseRefreshChapters,
              onPressed: onRefresh,
            ),
            ?overflowMenu,
          ],
        ),
      ),
    ),
    if (duplicateCount > 0 || hidingDuplicates)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 12, 4),
          child: Row(
            children: [
              Icon(
                Icons.copy_all_outlined,
                size: 16,
                color: Theme.of(context).colorScheme.tertiary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.chapterListDuplicates(duplicateCount),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              TextButton(
                onPressed: onToggleDuplicates,
                child: Text(
                  hidingDuplicates
                      ? l10n.chapterListShowDuplicates
                      : l10n.chapterListHideDuplicates,
                ),
              ),
            ],
          ),
        ),
      ),
    ?missingChaptersSummary,
    if (chapters == null)
      const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8),
          child: ChapterListSkeleton(),
        ),
      )
    else if (chapters.isEmpty)
      SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              l10n.browseEmpty,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
        ),
      )
    else if (layout == ChapterListLayout.grid)
      SliverPadding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        sliver: SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 220,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            mainAxisExtent: 148,
          ),
          delegate: SliverChildBuilderDelegate((context, index) {
            final chapter = chapters[index];
            final isSelected = selectedChapterUrls.contains(chapter.url);
            return ChapterGridCell(
              chapter: chapter,
              dateLine: formatChapterDateLine(
                chapter,
                AppLocalizations.of(context)!,
              ),
              isSelected: isSelected,
              isSelectionMode: isSelectionMode,
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (hasChapterComments)
                    IconButton(
                      icon: const Icon(Icons.mode_comment_outlined, size: 18),
                      tooltip: l10n.sourceBrowseCommentsHeading,
                      onPressed: () => onOpenChapterComments(chapter),
                      visualDensity: VisualDensity.compact,
                      constraints: const BoxConstraints(
                        minWidth: 32,
                        minHeight: 32,
                      ),
                      padding: EdgeInsets.zero,
                    ),
                  if (libraryEntryId != null &&
                      sourceId != null &&
                      service != null)
                    ChapterDownloadButton(
                      libraryEntryId: libraryEntryId,
                      chapter: chapter,
                      sourceId: sourceId,
                      entryTitle: entryTitle,
                      service: service,
                    ),
                  if (chapter.locked || chapter.isTimeLocked)
                    const Icon(Icons.lock_outline, size: 18),
                ],
              ),
              onTap: () {
                if (isSelectionMode) {
                  onChapterTap?.call(chapter);
                } else {
                  onOpenChapter(chapter);
                }
              },
              onLongPress: () => onChapterLongPress?.call(chapter),
            );
          }, childCount: chapters.length),
        ),
      )
    else
      SliverList.builder(
        itemCount: chapters.length,
        itemBuilder: (context, index) {
          final chapter = chapters[index];
          final tile = ChapterListTile(
            chapter: chapter,
            isSelected: selectedChapterUrls.contains(chapter.url),
            isSelectionMode: isSelectionMode,
            hasChapterComments: hasChapterComments,
            libraryEntryId: libraryEntryId,
            sourceId: sourceId,
            entryTitle: entryTitle,
            service: service,
            onOpenChapter: onOpenChapter,
            onOpenChapterComments: onOpenChapterComments,
            onChapterLongPress: onChapterLongPress,
            onChapterTap: onChapterTap,
            swipeRight: gestures.chapterSwipeRight,
            swipeLeft: gestures.chapterSwipeLeft,
            onSwipe: onChapterAction,
          );
          final gap = gaps.after[index];
          final head = index == 0 ? gaps.before : const <int>[];
          if (gap.isEmpty && head.isEmpty) return tile;
          return Column(
            children: [
              if (head.isNotEmpty) ChapterGapMarker(missing: head),
              tile,
              if (gap.isNotEmpty) ChapterGapMarker(missing: gap),
            ],
          );
        },
      ),
  ];
}
