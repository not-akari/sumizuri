import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/content/entry_progress_bar.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/utils/formatting/series_status_bucket.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';

const coverAspectRatio = 2 / 3;

class LibraryCoverThumbnail extends StatelessWidget {
  const LibraryCoverThumbnail({
    super.key,
    this.coverUrl,
    this.customCoverPath,
    this.width = 42,
  });

  final String? coverUrl;
  final String? customCoverPath;
  final double width;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: context.shapes.cover.radius,
      child: SizedBox(
        width: width,
        height: width / coverAspectRatio,
        child: CoverImage(
          url: coverUrl,
          filePath: customCoverPath,
          iconSize: 18,
        ),
      ),
    );
  }
}

/// Where the title of a tile goes: under the cover, over the foot of it, or nowhere.
enum CoverTileVariant { comfortable, compact, coverOnly }

/// The status of a series in words, or null when it is not known.
String? coverStatusText(String? status, AppLocalizations l10n) =>
    switch (classifySeriesStatus(status)) {
      SeriesStatusBucket.ongoing => l10n.categorySmartRuleStatusOngoing,
      SeriesStatusBucket.completed => l10n.categorySmartRuleStatusCompleted,
      SeriesStatusBucket.hiatus => l10n.categorySmartRuleStatusHiatus,
      SeriesStatusBucket.unknown => null,
    };

class MangaCoverTile extends StatelessWidget {
  const MangaCoverTile({
    super.key,
    required this.title,
    this.coverUrl,
    this.customCoverPath,
    this.unreadCount,
    this.downloadedCount,
    this.status,
    this.onTap,
    this.onLongPress,
    this.onDoubleTap,
    this.heroTag,
    this.selected = false,
    this.selectable = false,
    this.caption,
    this.marked = false,
    this.variant = CoverTileVariant.comfortable,
    this.progress,
  });

  /// How much of the title is read, from 0 to 1, or null to show no bar.
  final double? progress;

  /// Where the title is drawn.
  final CoverTileVariant variant;

  /// A line under the title for anything else worth knowing, such as progress.
  final String? caption;

  /// Shows a bookmark on the cover for a title the viewer already keeps.
  final bool marked;

  final String title;
  final String? coverUrl;
  final String? customCoverPath;
  final int? unreadCount;

  final int? downloadedCount;

  final String? status;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  final VoidCallback? onDoubleTap;

  final bool selected;
  final bool selectable;

  final Object? heroTag;

  // Drawn on a black badge, so the theme colour is lightened to stay readable.
  Color? _statusColor(SeriesStatusBucket bucket, ColorScheme cs) {
    Color soft(Color c) => Color.lerp(c, Colors.white, 0.5)!;
    return switch (bucket) {
      SeriesStatusBucket.hiatus => soft(cs.primary),
      SeriesStatusBucket.completed => soft(cs.tertiary),
      SeriesStatusBucket.ongoing || SeriesStatusBucket.unknown => null,
    };
  }

  String? _statusLabel(SeriesStatusBucket bucket, AppLocalizations l10n) =>
      switch (bucket) {
        SeriesStatusBucket.ongoing => l10n.categorySmartRuleStatusOngoing,
        SeriesStatusBucket.completed => l10n.categorySmartRuleStatusCompleted,
        SeriesStatusBucket.hiatus => l10n.categorySmartRuleStatusHiatus,
        SeriesStatusBucket.unknown => null,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final statusText = _statusLabel(classifySeriesStatus(status), l10n);
    final label = [
      title,
      if (unreadCount != null && unreadCount! > 0)
        l10n.coverUnreadChapters(unreadCount!),
      if (downloadedCount != null && downloadedCount! > 0)
        l10n.coverDownloadedChapters(downloadedCount!),
      ?statusText,
    ].join(', ');
    return Semantics(
      container: true,
      button: true,
      selected: selected,
      label: label,
      onTap: onTap,
      onLongPress: onLongPress,
      excludeSemantics: true,
      child: _content(context),
    );
  }

  Widget _content(BuildContext context) {
    final theme = Theme.of(context);
    final panelShape = context.shapes.cover.radius;
    final panelShapeInner = context.shapes.cover.insetRadius(1);
    final l10n = AppLocalizations.of(context)!;
    final statusBucket = classifySeriesStatus(status);
    final statusLabel = _statusLabel(statusBucket, l10n);
    final statusColor =
        _statusColor(statusBucket, theme.colorScheme) ?? Colors.white70;
    final titleStyle = theme.textTheme.bodySmall;

    final look = context.options.progress;
    final showBar =
        progress != null && EntryProgressBar.visible(progress!, look);
    // With no room below the cover, the bar goes on it.
    final barOnCover =
        showBar &&
        (look.placement == ProgressPlacement.onCover ||
            variant != CoverTileVariant.comfortable);
    final barBelow = showBar && !barOnCover;
    // Whatever sits at the foot of the cover moves up out of the bar's way.
    final barLift = barOnCover ? look.thickness + 4 : 0.0;
    final titleHeight =
        (titleStyle?.fontSize ?? 12) * (titleStyle?.height ?? 1.3) * 2;
    final cover = AspectRatio(
      aspectRatio: coverAspectRatio,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: panelShape,
          boxShadow: context.options.effects.coverShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
          border: Border.all(
            color: selected
                ? theme.colorScheme.primary
                : theme.colorScheme.outlineVariant,
            width: selected ? 2.5 : 1,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: panelShapeInner,
              child: CoverImage(url: coverUrl, filePath: customCoverPath),
            ),
            if (selected)
              ClipRRect(
                borderRadius: panelShapeInner,
                child: Container(color: Colors.black.withValues(alpha: 0.35)),
              ),
            if (selectable)
              Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected ? theme.colorScheme.primary : Colors.white,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            if (marked && !selectable)
              Positioned(
                top: 6,
                left: 6,
                child: Icon(
                  Icons.bookmark,
                  size: 20,
                  color: theme.colorScheme.primary,
                  shadows: const [Shadow(color: Colors.black54, blurRadius: 4)],
                ),
              ),
            if (unreadCount != null && unreadCount! > 0)
              Positioned(
                top: 6,
                right: 6,
                child: Transform.rotate(
                  angle: -0.12,
                  child: Container(
                    width: 24,
                    height: 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.primary,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      '$unreadCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            if (downloadedCount != null && downloadedCount! > 0)
              Positioned(
                right: 6,
                bottom:
                    (variant == CoverTileVariant.compact
                        ? (caption == null ? 46 : 58)
                        : 6) +
                    barLift,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.download_done_rounded,
                          size: 11,
                          color: Colors.white70,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          '$downloadedCount',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white70,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            if (statusLabel != null && variant == CoverTileVariant.comfortable)
              Positioned(
                left: 6,
                bottom: 6 + barLift,

                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.72),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 2,
                    ),
                    child: Text(
                      statusLabel.toUpperCase(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ),
            if (variant == CoverTileVariant.compact)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: panelShapeInner,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    // The whole width of the cover, whatever the title is.
                    child: SizedBox(
                      width: double.infinity,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [Colors.transparent, Colors.black87],
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(6, 22, 6, 6 + barLift),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              if (caption != null)
                                Text(
                                  caption!,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: Colors.white70,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (barOnCover)
              Positioned(
                left: 6,
                right: 6,
                bottom: 6,
                child: EntryProgressBar(progress: progress!, onCover: true),
              ),
          ],
        ),
      ),
    );
    if (variant != CoverTileVariant.comfortable) {
      // The cover is the whole tile.
      return PressableScale(
        onTap: onTap,
        onLongPress: onLongPress,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          onDoubleTap: onDoubleTap,
          borderRadius: panelShape,
          child: heroTag == null ? cover : Hero(tag: heroTag!, child: cover),
        ),
      );
    }
    return PressableScale(
      onTap: onTap,
      onLongPress: onLongPress,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        onDoubleTap: onDoubleTap,
        borderRadius: panelShape,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: heroTag == null
                  ? cover
                  : Hero(tag: heroTag!, child: cover),
            ),
            if (barBelow)
              Padding(
                padding: const EdgeInsets.only(top: 5),
                child: EntryProgressBar(progress: progress!),
              ),
            const SizedBox(height: 6),
            SizedBox(
              height: titleHeight,
              child: Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
            ),
            if (caption != null)
              Text(
                caption!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
