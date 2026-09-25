import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/utils/formatting/chapter_number.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/library/models/category_membership.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/widgets/dashboard_items.dart';
import 'package:sumizuri/features/library/widgets/dashboard_section.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _maxCards = 8;

/// The titles read last, to pick up where they were left.
class LibraryContinueReadingRow extends ConsumerWidget {
  const LibraryContinueReadingRow({super.key, this.mediaType, this.categoryId});

  final MediaType? mediaType;

  final int? categoryId;

  String _chapterLabel(AppLocalizations l10n, ReadingTimelineBurst burst) {
    final number = formatChapterNumber(burst.chapterNumbers.last);
    final title = burst.latestChapterTitle;
    if (title != null && title.isNotEmpty) return '$number — $title';
    return mediaType == MediaType.anime
        ? l10n.episodeShort(number)
        : l10n.chapterShort(number);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final bursts = ref.watch(timelineBurstsProvider(mediaType: mediaType));
    final categoryMembership =
        ref.watch(allEntryCategoryIdsProvider).value ?? const {};
    final style =
        ref.watch(homeContinueStyleProvider).value ?? DashboardShelfStyle.shelf;

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
                furthestReadManyKey([
                  for (final burst in shown) burst.libraryEntryId,
                ]),
              ),
            )
            .value;
        return DashboardSection(
          title: mediaType == MediaType.anime
              ? l10n.libraryContinueWatching
              : l10n.libraryContinueReading,
          child: DashboardItems(
            style: style,
            items: [
              for (final burst in shown)
                DashboardItem(
                  title: burst.entryTitle,
                  coverUrl: burst.entryCoverUrl,
                  customCoverPath: burst.customCoverPath,
                  caption: _chapterLabel(l10n, burst),
                  progress: progressByEntry?[burst.libraryEntryId],
                  onTap: () => openLibraryEntry(
                    context,
                    ref,
                    libraryEntryId: burst.libraryEntryId,
                    title: burst.entryTitle,
                    coverUrl: burst.entryCoverUrl,
                    sourceId: burst.sourceId,
                    externalId: burst.externalId,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
