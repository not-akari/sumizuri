import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/content/entry_progress_bar.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// A title as one row: a small cover, the title, a line about it, and its
/// counts at the end. The list form of [MangaCoverTile], and it takes the same
/// things, so the two can be swapped for one another.
class MangaCoverListRow extends StatelessWidget {
  const MangaCoverListRow({
    super.key,
    required this.title,
    this.coverUrl,
    this.customCoverPath,
    this.subtitle,
    this.caption,
    this.unreadCount,
    this.downloadedCount,
    this.status,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.heroTag,
    this.selected = false,
    this.selectable = false,
    this.marked = false,
    this.dense = false,
    this.progress,
  });

  /// How much of the title is read, from 0 to 1, or null to show no bar.
  final double? progress;

  final String title;
  final String? coverUrl;
  final String? customCoverPath;

  /// What the title is on, such as its source.
  final String? subtitle;

  /// Anything else worth knowing, such as progress.
  final String? caption;
  final int? unreadCount;
  final int? downloadedCount;
  final String? status;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onDoubleTap;
  final Object? heroTag;
  final bool selected;
  final bool selectable;

  /// Shows a bookmark for a title the viewer already keeps.
  final bool marked;

  /// One line and a smaller cover, so more rows fit.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final statusText = coverStatusText(status, l10n);
    final meta = [
      ?statusText,
      if (subtitle != null && subtitle!.isNotEmpty) subtitle!,
      if (caption != null && caption!.isNotEmpty) caption!,
    ].join(' · ');

    Widget thumb = LibraryCoverThumbnail(
      coverUrl: coverUrl,
      customCoverPath: customCoverPath,
      width: dense ? 32 : 46,
    );
    if (heroTag != null) thumb = Hero(tag: heroTag!, child: thumb);
    thumb = Stack(
      clipBehavior: Clip.none,
      children: [
        thumb,
        if (selectable)
          Positioned(
            left: 2,
            top: 2,
            child: Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 18,
              color: selected ? cs.primary : Colors.white,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          )
        else if (marked)
          Positioned(
            left: 2,
            top: 0,
            child: Icon(
              Icons.bookmark,
              size: 16,
              color: cs.primary,
              shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
            ),
          ),
      ],
    );

    final unread = unreadCount != null && unreadCount! > 0;
    final downloaded = downloadedCount != null && downloadedCount! > 0;

    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: [
        title,
        if (unread) l10n.coverUnreadChapters(unreadCount!),
        if (downloaded) l10n.coverDownloadedChapters(downloadedCount!),
        ?statusText,
      ].join(', '),
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: Material(
        color: selected
            ? cs.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onDoubleTap: onDoubleTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: context.layout.gutter,
              vertical: dense ? 5 : 8,
            ),
            child: Row(
              children: [
                thumb,
                SizedBox(width: dense ? 12 : 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: dense ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (meta.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            meta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ),
                      if (progress != null &&
                          EntryProgressBar.visible(
                            progress!,
                            context.options.progress,
                          ))
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: EntryProgressBar(progress: progress!),
                              ),
                              if (context.options.progress.showPercent) ...[
                                const SizedBox(width: 8),
                                Text(
                                  '${(progress! * 100).round()}%',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                if (downloaded) ...[
                  const SizedBox(width: 8),
                  Icon(
                    Icons.download_done_rounded,
                    size: 14,
                    color: cs.onSurfaceVariant,
                  ),
                  const SizedBox(width: 2),
                  Text(
                    '$downloadedCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
                if (unread) ...[
                  const SizedBox(width: 8),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      color: cs.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      child: Text(
                        '$unreadCount',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: cs.onPrimary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
