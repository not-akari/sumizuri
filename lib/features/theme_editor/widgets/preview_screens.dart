import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';
import 'package:sumizuri/core/widgets/navigation/island_nav_bar.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/features/library/pages/history_screen.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/features/library/widgets/chapter_feed_tile.dart';
import 'package:sumizuri/features/theme_editor/data/preview_samples.dart';
import 'package:sumizuri/features/theme_editor/widgets/preview_screens_more.dart';

enum PreviewScreen {
  library,
  updates,
  history,
  browse,
  detail,
  settings,
  components,
}

const previewNavScreens = [
  PreviewScreen.library,
  PreviewScreen.updates,
  PreviewScreen.history,
  PreviewScreen.browse,
  PreviewScreen.settings,
];

Widget buildPreviewNavBar(
  BuildContext context,
  PreviewScreen screen,
  ValueChanged<PreviewScreen> onChanged,
) => IslandNavBar(
  destinations: [
    IslandNavDestination(
      icon: Icons.menu_book,
      tooltip: AppLocalizations.of(context)!.mediaTypeMangaTitle,
    ),
    IslandNavDestination(
      icon: Icons.update_outlined,
      tooltip: AppLocalizations.of(context)!.updatesTitle,
    ),
    IslandNavDestination(
      icon: Icons.history_outlined,
      tooltip: AppLocalizations.of(context)!.historyTitle,
    ),
    IslandNavDestination(
      icon: Icons.explore_outlined,
      tooltip: AppLocalizations.of(context)!.browseTitle,
    ),
    IslandNavDestination(
      icon: Icons.settings_outlined,
      tooltip: AppLocalizations.of(context)!.settingsTitle,
    ),
  ],
  selectedIndex: previewNavScreens.indexOf(screen),
  onSelected: (i) => onChanged(previewNavScreens[i]),
);

Widget buildPreviewScreen(BuildContext context, PreviewScreen screen) =>
    switch (screen) {
      PreviewScreen.library => const _LibrarySample(),
      PreviewScreen.updates => const _UpdatesSample(),
      PreviewScreen.history => const _HistorySample(),
      PreviewScreen.browse => const PreviewBrowseSample(),
      PreviewScreen.detail => const PreviewDetailSample(),
      PreviewScreen.settings => const PreviewSettingsSample(),
      PreviewScreen.components => const PreviewComponentsSample(),
    };

class _LibrarySample extends ConsumerWidget {
  const _LibrarySample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final samples = ref.watch(previewSamplesProvider);
    final cs = Theme.of(context).colorScheme;
    return Stack(
      children: [
        ListView(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            20,
            context.layout.gutter,
            96,
          ),
          children: [
            Text(
              AppLocalizations.of(context)!.libraryTitle,
              style: TextStyle(
                fontFamily: context.displayFont,
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: cs.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              AppLocalizations.of(context)!.libraryTagline,
              style: TextStyle(fontSize: 12.5, color: cs.outline),
            ),
            const SizedBox(height: 8),
            CustomPaint(
              size: const Size(double.infinity, 8),
              painter: BrushLinePainter(
                curvy: context.options.effects.brushStrokes,
                color: cs.outlineVariant.withValues(alpha: 0.6),
              ),
            ),
            const SquiggleTabBar(
              labels: ['All', 'Reading', 'Completed', 'Planned'],
              activeIndex: 1,
              compact: true,
            ),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 10,
              childAspectRatio: 0.55,
              children: [
                for (final (i, sample) in samples.indexed)
                  MangaCoverTile(
                    // Shown whatever the setting is, so the look can be judged here.
                    progress: [0.62, 0.18, 1.0][i % 3],
                    title: sample.title,
                    coverUrl: sample.coverUrl,
                    customCoverPath: sample.customCoverPath,
                    unreadCount: sample.unreadCount,
                    status: sample.status,
                    onTap: () {},
                  ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _PageTitle extends StatelessWidget {
  const _PageTitle(this.title, this.subtitle);

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        20,
        context.layout.gutter,
        8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontFamily: context.displayFont,
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 12.5, color: cs.outline)),
        ],
      ),
    );
  }
}

class _UpdatesSample extends ConsumerWidget {
  const _UpdatesSample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final samples = ref.watch(previewSamplesProvider);
    const times = ['2h ago', '5h ago', 'Yesterday'];
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const _PageTitle('Updates', 'New chapters from your library.'),
        for (final (i, s) in samples.indexed)
          ChapterFeedTile(
            coverUrl: s.coverUrl,
            customCoverPath: s.customCoverPath,
            entryTitle: s.title,
            chapterNumber: 120.0 + i * 7,
            chapterTitle: null,
            timeLabel: times[i],
            onTap: () {},
          ),
      ],
    );
  }
}

class _HistorySample extends ConsumerWidget {
  const _HistorySample();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final samples = ref.watch(previewSamplesProvider);
    final now = DateTime.now();
    return ListView(
      padding: const EdgeInsets.only(bottom: 96),
      children: [
        const _PageTitle('History', 'What you read, most recent first.'),
        for (final (i, s) in samples.indexed)
          TimelineBurstTile(
            burst: ReadingTimelineBurst(
              libraryEntryId: -1 - i,
              entryTitle: s.title,
              entryCoverUrl: s.coverUrl,
              customCoverPath: s.customCoverPath,
              sourceId: '',
              externalId: '',
              date: now,
              isReRead: i == 2,
              chapterNumbers: [for (var n = 0; n < 3 - i; n++) 40.0 + n],
              lastReadAt: now.subtract(Duration(hours: 3 + i * 9)),
            ),
            onTap: () {},
          ),
      ],
    );
  }
}
