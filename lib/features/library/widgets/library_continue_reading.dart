import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/library/models/category_membership.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _maxCards = 8;

class LibraryContinueReadingRow extends ConsumerWidget {
  const LibraryContinueReadingRow({super.key, this.mediaType, this.categoryId});

  final MediaType? mediaType;

  final int? categoryId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bursts = ref.watch(timelineBurstsProvider(mediaType: mediaType));
    final categoryMembership =
        ref.watch(allEntryCategoryIdsProvider).value ?? const {};

    return bursts.when(
      loading: () => const SizedBox.shrink(),
      error: (_, _) => const SizedBox.shrink(),
      data: (items) {
        final chosen = categoryId;
        bool matchesCategory(int entryId) =>
            chosen == null || isInCategory(categoryMembership, entryId, chosen);
        final seenEntryIds = <int>{};
        final shown = <ReadingTimelineBurst>[];
        for (final burst in items) {
          if (!matchesCategory(burst.libraryEntryId)) continue;
          if (seenEntryIds.add(burst.libraryEntryId)) shown.add(burst);
          if (shown.length == _maxCards) break;
        }
        if (shown.isEmpty) return const SizedBox.shrink();
        final progressByEntry = ref
            .watch(
              furthestReadManyProvider(
                furthestReadManyKey(
                  [for (final burst in shown) burst.libraryEntryId],
                ),
              ),
            )
            .value;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 0, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                mediaType == MediaType.anime
                    ? l10n.libraryContinueWatching
                    : l10n.libraryContinueReading,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              IntrinsicHeight(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      for (var i = 0; i < shown.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        _ContinueReadingCard(
                          burst: shown[i],
                          mediaType: mediaType,
                          progress: progressByEntry?[shown[i].libraryEntryId],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _ContinueReadingCard extends ConsumerWidget {
  const _ContinueReadingCard({
    required this.burst,
    required this.mediaType,
    required this.progress,
  });

  final ReadingTimelineBurst burst;
  final MediaType? mediaType;
  final double? progress;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final chapterLabel = burst.latestChapterTitle?.isNotEmpty ?? false
        ? '${formatChapterNumber(burst.chapterNumbers.last)} — ${burst.latestChapterTitle}'
        : (mediaType == MediaType.anime
              ? l10n.episodeShort(
                  formatChapterNumber(burst.chapterNumbers.last),
                )
              : 'Ch. ${formatChapterNumber(burst.chapterNumbers.last)}');

    return PressableScale(
      onTap: () => openLibraryEntry(
        context,
        ref,
        libraryEntryId: burst.libraryEntryId,
        title: burst.entryTitle,
        coverUrl: burst.entryCoverUrl,
        sourceId: burst.sourceId,
        externalId: burst.externalId,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: context.shapes.cover.radius,
          onTap: () => openLibraryEntry(
            context,
            ref,
            libraryEntryId: burst.libraryEntryId,
            title: burst.entryTitle,
            coverUrl: burst.entryCoverUrl,
            sourceId: burst.sourceId,
            externalId: burst.externalId,
          ),
          child: SizedBox(
            width: 128,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AspectRatio(
                  aspectRatio: coverAspectRatio,
                  child: ClipRRect(
                    borderRadius: context.shapes.cover.radius,
                    child: CoverImage(
                      url: burst.entryCoverUrl,
                      filePath: burst.customCoverPath,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(4, 8, 4, 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        burst.entryTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        chapterLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      if (progress != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(3),
                          child: LinearProgressIndicator(
                            value: progress,
                            minHeight: 3,
                            backgroundColor: cs.outlineVariant,
                            valueColor: AlwaysStoppedAnimation(cs.primary),
                          ),
                        )
                      else
                        Text(
                          formatRelativeDate(
                            AppLocalizations.of(context)!,
                            burst.lastReadAt,
                          ),
                          style: TextStyle(fontSize: 10.5, color: cs.outline),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
