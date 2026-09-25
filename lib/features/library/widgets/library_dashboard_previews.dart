import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/pages/history_screen.dart';
import 'package:sumizuri/features/library/pages/updates_screen.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/widgets/dashboard_items.dart';
import 'package:sumizuri/features/library/widgets/dashboard_section.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String dashboardHeroTag(String section, int libraryEntryId) =>
    'dash-$section-$libraryEntryId';

class UpdatesPreviewSection extends ConsumerWidget {
  const UpdatesPreviewSection({super.key, required this.mediaType});

  final MediaType? mediaType;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final updates = ref.watch(libraryUpdatesProvider(mediaType: mediaType));
    final style =
        ref.watch(homeUpdatesStyleProvider).value ?? DashboardShelfStyle.shelf;

    return updates.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stackTrace) => const SizedBox.shrink(),
      data: (items) {
        if (items.isEmpty) return const SizedBox.shrink();

        // One title once, with how many new chapters it has.
        final newChapterCounts = <int, int>{};
        final preview = <UpdateChapterSummary>[];
        for (final item in items) {
          final count = (newChapterCounts[item.libraryEntryId] ?? 0) + 1;
          newChapterCounts[item.libraryEntryId] = count;
          if (count == 1) preview.add(item);
        }

        return DashboardSection(
          title: l10n.updatesTitle,
          onSeeAll: () => Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UpdatesScreen(mediaType: mediaType),
            ),
          ),
          child: DashboardItems(
            style: style,
            items: [
              for (final item in preview.take(10))
                DashboardItem(
                  title: item.entryTitle,
                  coverUrl: item.entryCoverUrl,
                  customCoverPath: item.customCoverPath,
                  badge: newChapterCounts[item.libraryEntryId],
                  heroTag: dashboardHeroTag('updates', item.libraryEntryId),
                  onTap: () => openLibraryEntry(
                    context,
                    ref,
                    libraryEntryId: item.libraryEntryId,
                    title: item.entryTitle,
                    coverUrl: item.entryCoverUrl,
                    sourceId: item.sourceId,
                    externalId: item.externalId,
                    heroTag: dashboardHeroTag('updates', item.libraryEntryId),
                  ),
                ),
            ],
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
    final style =
        ref.watch(homeHistoryStyleProvider).value ?? DashboardShelfStyle.grid;

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
          child: DashboardItems(
            style: style,
            items: [
              for (final item in preview)
                DashboardItem(
                  title: item.entryTitle,
                  coverUrl: item.entryCoverUrl,
                  customCoverPath: item.customCoverPath,
                  heroTag: dashboardHeroTag('history', item.libraryEntryId),
                  onTap: () => openLibraryEntry(
                    context,
                    ref,
                    libraryEntryId: item.libraryEntryId,
                    title: item.entryTitle,
                    coverUrl: item.entryCoverUrl,
                    sourceId: item.sourceId,
                    externalId: item.externalId,
                    heroTag: dashboardHeroTag('history', item.libraryEntryId),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
