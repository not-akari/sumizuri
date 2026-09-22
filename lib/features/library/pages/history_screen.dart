import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/cards/feed_row.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/widgets/chapter_feed_scaffold.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key, this.mediaType, this.title});

  final MediaType? mediaType;
  final String? title;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AmbientScaffold(
      title: Text(title ?? l10n.historyTitle),
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
    final bursts = ref.watch(timelineBurstsProvider(mediaType: mediaType));
    // Batch query for progress across all entries in the feed.
    final progressByEntry = ref
        .watch(
          furthestReadManyProvider(
            furthestReadManyKey(
              [for (final b in bursts.value ?? const []) b.libraryEntryId],
            ),
          ),
        )
        .value;

    return ChapterFeedScaffold<ReadingTimelineBurst>(
      value: bursts,
      emptyMessage: l10n.historyEmpty,
      dateOf: (item) => item.lastReadAt,
      itemBuilder: (context, item) => TimelineBurstTile(
        burst: item,
        mediaType: mediaType,
        progress: progressByEntry?[item.libraryEntryId],
        onTap: () => openLibraryEntry(
          context,
          ref,
          libraryEntryId: item.libraryEntryId,
          title: item.entryTitle,
          coverUrl: item.entryCoverUrl,
          sourceId: item.sourceId,
          externalId: item.externalId,
        ),
      ),
    );
  }
}

class TimelineBurstTile extends StatelessWidget {
  const TimelineBurstTile({
    super.key,
    required this.burst,
    required this.onTap,
    this.mediaType,
    this.progress,
  });

  final ReadingTimelineBurst burst;

  final MediaType? mediaType;
  final VoidCallback onTap;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final String burstText;
    final watched = mediaType == MediaType.anime;
    if (watched) {
      final from = formatChapterNumber(burst.minChapter);
      final to = formatChapterNumber(burst.maxChapter);
      burstText = burst.isReRead
          ? (burst.isSingleChapter
                ? l10n.timelineRewatchedSingle(from)
                : l10n.timelineRewatchedRange(from, to))
          : (burst.isSingleChapter
                ? l10n.timelineWatchedSingle(from)
                : l10n.timelineWatchedRange(from, to));
    } else if (burst.isReRead) {
      burstText = burst.isSingleChapter
          ? l10n.timelineRereadSingle(formatChapterNumber(burst.minChapter))
          : l10n.timelineRereadRange(
              formatChapterNumber(burst.minChapter),
              formatChapterNumber(burst.maxChapter),
            );
    } else {
      burstText = burst.isSingleChapter
          ? l10n.timelineReadSingle(formatChapterNumber(burst.minChapter))
          : l10n.timelineReadRange(
              formatChapterNumber(burst.minChapter),
              formatChapterNumber(burst.maxChapter),
            );
    }

    final timeLabel = formatRelativeDate(
      AppLocalizations.of(context)!,
      burst.lastReadAt,
    );
    final cs = Theme.of(context).colorScheme;

    return FeedRow(
      onTap: onTap,
      leading: LibraryCoverThumbnail(
        coverUrl: burst.entryCoverUrl,
        customCoverPath: burst.customCoverPath,
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
                  burstText,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (progress != null) ...[
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 3,
                backgroundColor: cs.outlineVariant,
                valueColor: AlwaysStoppedAnimation(cs.primary),
              ),
            ),
          ],
        ],
      ),
      trailing: Text(
        timeLabel,
        style: TextStyle(fontSize: 11.5, color: cs.outline),
      ),
    );
  }
}
