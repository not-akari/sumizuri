import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/library/widgets/dashboard_section.dart';
import 'package:sumizuri/features/library/pages/history_screen.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/library/widgets/update_cover_card.dart';
import 'package:sumizuri/features/library/pages/updates_screen.dart';

String dashboardHeroTag(String section, int libraryEntryId) =>
    'dash-$section-$libraryEntryId';

class UpdatesPreviewSection extends ConsumerWidget {
  const UpdatesPreviewSection({super.key, required this.mediaType});

  final MediaType? mediaType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final updates = ref.watch(libraryUpdatesProvider(mediaType: mediaType));
    final tileWidth =
        (ref.watch(libraryGridTileSizeProvider).value ??
                LibraryGridTileSize.medium)
            .maxExtent;

    return updates.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final newChapterCounts = <int, int>{};
        final preview = <UpdateChapterSummary>[];
        for (final item in items) {
          final count = (newChapterCounts[item.libraryEntryId] ?? 0) + 1;
          newChapterCounts[item.libraryEntryId] = count;
          if (count == 1) preview.add(item);
        }
        final limited = preview.take(10).toList();

        return DashboardSection(
          title: l10n.updatesTitle,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UpdatesScreen(mediaType: mediaType),
            ),
          ),
          child: SizedBox(
            height: tileWidth * 1.5,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: limited.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = limited[index];
                final heroTag = dashboardHeroTag(
                  'updates',
                  item.libraryEntryId,
                );
                return Hero(
                  tag: heroTag,
                  child: UpdateCoverCard(
                    title: item.entryTitle,
                    coverUrl: item.entryCoverUrl,
                    customCoverPath: item.customCoverPath,
                    newChapterCount: newChapterCounts[item.libraryEntryId],
                    width: tileWidth,
                    onTap: () => openLibraryEntry(
                      context,
                      ref,
                      libraryEntryId: item.libraryEntryId,
                      title: item.entryTitle,
                      coverUrl: item.entryCoverUrl,
                      sourceId: item.sourceId,
                      externalId: item.externalId,
                      heroTag: heroTag,
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class HistoryPreviewSection extends ConsumerWidget {
  const HistoryPreviewSection({super.key, required this.mediaType});

  final MediaType? mediaType;

  static const _previewCount = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final history = ref.watch(libraryHistoryProvider(mediaType: mediaType));
    final tileSize =
        ref.watch(libraryGridTileSizeProvider).value ??
        LibraryGridTileSize.medium;

    return history.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        final seenEntries = <int>{};
        final preview = <HistoryChapterSummary>[];
        for (final item in items) {
          if (seenEntries.add(item.libraryEntryId)) preview.add(item);
          if (preview.length >= _previewCount) break;
        }

        return DashboardSection(
          title: l10n.historyTitle,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => HistoryScreen(mediaType: mediaType),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: tileSize.maxExtent,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.55,
              ),
              itemCount: preview.length,
              itemBuilder: (context, index) {
                final item = preview[index];
                final heroTag = dashboardHeroTag(
                  'history',
                  item.libraryEntryId,
                );
                return MangaCoverTile(
                  title: item.entryTitle,
                  coverUrl: item.entryCoverUrl,
                  customCoverPath: item.customCoverPath,
                  heroTag: heroTag,
                  onTap: () => openLibraryEntry(
                    context,
                    ref,
                    libraryEntryId: item.libraryEntryId,
                    title: item.entryTitle,
                    coverUrl: item.entryCoverUrl,
                    sourceId: item.sourceId,
                    externalId: item.externalId,
                    heroTag: heroTag,
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
