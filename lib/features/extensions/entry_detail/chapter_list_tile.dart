import 'package:sumizuri/features/extensions/entry_detail/entry_media_wording.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/reader/models/chapter_lock_checker.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_widgets.dart';

Widget? formatChapterSubtitle(MChapter chapter, AppLocalizations l10n) {
  final countdown = formatUnlockCountdown(l10n, chapter.unlocksAt);
  final parts = [
    if (chapter.number != null) '#${formatChapterNumber(chapter.number!)}',
    if (chapter.dateUploaded != null)
      formatRelativeDate(l10n, chapter.dateUploaded!),
    ?countdown,
  ];
  return parts.isEmpty ? null : Text(parts.join(' · '));
}

Widget? buildChapterSubtitleWithProgress(
  MChapter chapter,
  ColorScheme cs,
  AppLocalizations l10n,
) {
  final text = formatChapterSubtitle(chapter, l10n);
  final progress = chapter.progress;
  if (chapter.read || progress == null || progress <= 0) return text;

  final bar = Padding(
    padding: const EdgeInsets.only(top: 4),
    child: ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: progress.clamp(0.0, 1.0),
        minHeight: 3,
        backgroundColor: cs.surfaceContainerHighest,
        color: cs.primary,
      ),
    ),
  );

  if (text == null) return bar;
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [text, bar],
  );
}

class ChapterListTile extends StatelessWidget {
  const ChapterListTile({
    super.key,
    required this.chapter,
    required this.isSelected,
    required this.isSelectionMode,
    required this.hasChapterComments,
    required this.libraryEntryId,
    required this.sourceId,
    required this.entryTitle,
    required this.service,
    required this.onOpenChapter,
    required this.onOpenChapterComments,
    this.onChapterLongPress,
    this.onChapterTap,
    this.swipeRight = ChapterRowAction.toggleRead,
    this.swipeLeft = ChapterRowAction.download,
    this.onSwipe,
  });

  final MChapter chapter;
  final bool isSelected;
  final bool isSelectionMode;
  final bool hasChapterComments;
  final int? libraryEntryId;
  final String? sourceId;
  final String entryTitle;
  final dynamic service;
  final void Function(MChapter) onOpenChapter;
  final void Function(MChapter) onOpenChapterComments;
  final void Function(MChapter)? onChapterLongPress;
  final void Function(MChapter)? onChapterTap;

  final ChapterRowAction swipeRight;
  final ChapterRowAction swipeLeft;
  final void Function(MChapter, ChapterRowAction)? onSwipe;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;

    final shapes = context.shapes;
    final listTileWidget = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: isSelected
            ? cs.primaryContainer.withValues(alpha: 0.5)
            : cs.surfaceContainerHighest.withValues(alpha: 0.4),
        shape: shapes.item.border(
          side: BorderSide(
            color: isSelected ? cs.primary : cs.outlineVariant,
            width: isSelected ? 1.5 : shapes.borderWidth,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
            if (isSelectionMode) {
              onChapterTap?.call(chapter);
            } else {
              onOpenChapter(chapter);
            }
          },
          onLongPress: () => onChapterLongPress?.call(chapter),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 6, 10),
            child: Row(
              children: [
                if (isSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(right: 10),
                    child: Icon(
                      isSelected
                          ? Icons.check_circle_rounded
                          : Icons.radio_button_unchecked_rounded,
                      size: 22,
                      color: isSelected ? cs.primary : cs.outline,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: chapter.read ? Colors.transparent : cs.primary,
                      ),
                    ),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        chapter.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: chapter.read
                              ? FontWeight.w500
                              : FontWeight.w600,
                          color: chapter.read
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                      if (buildChapterSubtitleWithProgress(
                            chapter,
                            cs,
                            AppLocalizations.of(context)!,
                          )
                          case final subtitle?)
                        DefaultTextStyle(
                          style: TextStyle(fontSize: 12, color: cs.outline),
                          child: Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: subtitle,
                          ),
                        ),
                    ],
                  ),
                ),
                if (chapter.bookmarked)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Icon(Icons.bookmark, size: 20, color: cs.primary),
                  ),
                if (hasChapterComments)
                  IconButton(
                    icon: const Icon(Icons.mode_comment_outlined, size: 20),
                    tooltip: l10n.sourceBrowseCommentsHeading,
                    onPressed: () => onOpenChapterComments(chapter),
                  ),
                if (libraryEntryId != null &&
                    sourceId != null &&
                    service != null)
                  ChapterDownloadButton(
                    libraryEntryId: libraryEntryId!,
                    chapter: chapter,
                    sourceId: sourceId!,
                    entryTitle: entryTitle,
                    service: service,
                  ),
                if (chapter.locked || chapter.isTimeLocked)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.lock_outline,
                      size: 20,
                      color: cs.outline,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );

    if (isSelectionMode) {
      return listTileWidget;
    }

    final rightOn = swipeRight != ChapterRowAction.none;
    final leftOn = swipeLeft != ChapterRowAction.none;
    if (!rightOn && !leftOn) return listTileWidget;

    return Dismissible(
      key: ValueKey(chapter.url),
      direction: rightOn && leftOn
          ? DismissDirection.horizontal
          : rightOn
          ? DismissDirection.startToEnd
          : DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        onSwipe?.call(
          chapter,
          direction == DismissDirection.startToEnd ? swipeRight : swipeLeft,
        );
        return false;
      },
      background: _swipeBackground(context, swipeRight, Alignment.centerLeft),
      secondaryBackground: _swipeBackground(
        context,
        swipeLeft,
        Alignment.centerRight,
      ),
      child: listTileWidget,
    );
  }

  Widget _swipeBackground(
    BuildContext context,
    ChapterRowAction action,
    Alignment alignment,
  ) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final shapes = context.shapes;
    final (icon, label, fill, ink) = switch (action) {
      ChapterRowAction.toggleRead => (
        chapter.read ? Icons.remove_done : Icons.done_all,
        chapter.read
            ? l10n.markUnread(EntryMediaType.of(context))
            : l10n.markRead(EntryMediaType.of(context)),
        chapter.read ? cs.secondaryContainer : cs.primaryContainer,
        chapter.read ? cs.onSecondaryContainer : cs.onPrimaryContainer,
      ),
      ChapterRowAction.download => (
        Icons.download_rounded,
        l10n.chapterDownloadSelected,
        cs.tertiaryContainer,
        cs.onTertiaryContainer,
      ),
      ChapterRowAction.toggleBookmark => (
        chapter.bookmarked
            ? Icons.bookmark_remove_outlined
            : Icons.bookmark_add_outlined,
        chapter.bookmarked
            ? l10n.chapterSwipeUnbookmark
            : l10n.chapterSwipeBookmark,
        cs.secondaryContainer,
        cs.onSecondaryContainer,
      ),
      _ => (
        Icons.check_circle_outline,
        l10n.chapterSwipeSelect,
        cs.surfaceContainerHighest,
        cs.onSurface,
      ),
    };
    final children = [
      Icon(icon, color: ink),
      const SizedBox(width: 8),
      Text(
        label,
        style: TextStyle(color: ink, fontWeight: FontWeight.w600),
      ),
    ];
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      alignment: alignment,
      decoration: BoxDecoration(color: fill, borderRadius: shapes.item.radius),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: alignment == Alignment.centerRight
            ? children.reversed.toList()
            : children,
      ),
    );
  }
}
