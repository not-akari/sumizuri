import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/feed_row.dart';
import 'package:sumizuri/core/widgets/content/entry_progress_bar.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/widgets/chapter_feed_scaffold.dart';
import 'package:sumizuri/features/library/widgets/display_style_sheet.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.mediaType, this.title});

  final MediaType? mediaType;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientScaffold(
      title: Text(title ?? l10n.historyTitle),
      actions: [
        IconButton(
          icon: const Icon(Icons.view_module_outlined),
          tooltip: l10n.libraryDisplayButtonTooltip,
          onPressed: () => showDisplayStyleSheet(
            context,
            title: l10n.libraryDisplayHistoryPage,
            setting: Settings.historyDisplayStyle,
            provider: historyDisplayStyleProvider,
          ),
        ),
      ],
      body: HistoryFeedList(mediaType: mediaType),
    );
  }
}

class HistoryFeedList extends ConsumerWidget {
  const HistoryFeedList({super.key, required this.mediaType});

  final MediaType? mediaType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final style =
        ref.watch(historyDisplayStyleProvider).value ??
        LibraryDisplayStyle.list;
    final bursts = ref.watch(timelineBurstsProvider(mediaType: mediaType));
    // Batch query for progress across all entries in the feed.
    final progressByEntry = ref
        .watch(
          furthestReadManyProvider(
            furthestReadManyKey([
              for (final b in bursts.value ?? const []) b.libraryEntryId,
            ]),
          ),
        )
        .value;

    return ChapterFeedScaffold<ReadingTimelineBurst>(
      value: bursts,
      style: style,
      emptyMessage: l10n.historyEmpty,
      dateOf: (item) => item.lastReadAt,
      itemBuilder: (context, item, style) {
        void open() => openLibraryEntry(
          context,
          ref,
          libraryEntryId: item.libraryEntryId,
          title: item.entryTitle,
          coverUrl: item.entryCoverUrl,
          sourceId: item.sourceId,
          externalId: item.externalId,
        );
        final progress = progressByEntry?[item.libraryEntryId];
        if (style.isGrid) {
          return MangaCoverTile(
            variant: switch (style) {
              LibraryDisplayStyle.compactGrid => CoverTileVariant.compact,
              LibraryDisplayStyle.coverGrid => CoverTileVariant.coverOnly,
              _ => CoverTileVariant.comfortable,
            },
            title: item.entryTitle,
            coverUrl: item.entryCoverUrl,
            customCoverPath: item.customCoverPath,
            caption: timelineBurstText(l10n, item, mediaType),
            progress: progress,
            onTap: open,
          );
        }
        return TimelineBurstTile(
          burst: item,
          mediaType: mediaType,
          progress: progress,
          dense: style == LibraryDisplayStyle.compactList,
          onTap: open,
        );
      },
    );
  }
}

/// What was read in one sitting, in the person's language.
String timelineBurstText(
  AppLocalizations l10n,
  ReadingTimelineBurst burst,
  MediaType? mediaType,
) {
  final from = formatChapterNumber(burst.minChapter);
  final to = formatChapterNumber(burst.maxChapter);
  final single = burst.isSingleChapter;
  if (mediaType == MediaType.anime) {
    return burst.isReRead
        ? (single
              ? l10n.timelineRewatchedSingle(from)
              : l10n.timelineRewatchedRange(from, to))
        : (single
              ? l10n.timelineWatchedSingle(from)
              : l10n.timelineWatchedRange(from, to));
  }
  return burst.isReRead
      ? (single
            ? l10n.timelineRereadSingle(from)
            : l10n.timelineRereadRange(from, to))
      : (single
            ? l10n.timelineReadSingle(from)
            : l10n.timelineReadRange(from, to));
}

class TimelineBurstTile extends StatelessWidget {
  const TimelineBurstTile({
    super.key,
    required this.burst,
    required this.onTap,
    this.mediaType,
    this.progress,
    this.dense = false,
  });

  final ReadingTimelineBurst burst;

  final MediaType? mediaType;
  final VoidCallback onTap;

  /// How much of the title is read, from 0 to 1.
  final double? progress;

  /// A smaller cover, so more rows fit.
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final look = context.options.progress;
    final showBar =
        progress != null && EntryProgressBar.visible(progress!, look);

    return FeedRow(
      onTap: onTap,
      leading: LibraryCoverThumbnail(
        coverUrl: burst.entryCoverUrl,
        customCoverPath: burst.customCoverPath,
        width: dense ? 32 : 42,
      ),
      title: burst.entryTitle,
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (burst.isReRead)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 5,
                    vertical: 1,
                  ),
                  margin: const EdgeInsets.only(right: 6),
                  decoration: BoxDecoration(
                    color: cs.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    l10n.timelineRereadBadge,
                    style: TextStyle(
                      color: cs.onTertiaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              Expanded(
                child: Text(
                  timelineBurstText(l10n, burst, mediaType),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (showBar) ...[
            const SizedBox(height: 4),
            EntryProgressBar(progress: progress!),
          ],
        ],
      ),
      trailing: Text(
        formatRelativeDate(l10n, burst.lastReadAt),
        style: TextStyle(fontSize: 11.5, color: cs.outline),
      ),
    );
  }
}
