import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';
import 'package:sumizuri/core/widgets/controls/no_scrollbar.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/statistics/pages/profile_stats_calendar_page.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/widgets/anilist_tracker_tile.dart';
import 'package:sumizuri/features/profile/widgets/profile_dialogs.dart';
import 'package:sumizuri/features/profile/widgets/profile_header.dart';
import 'package:sumizuri/features/sync/pages/sync_settings_page.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  // Wide enough to lay the avatar header and stats bar side by side.
  static const _wideBreakpoint = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(activeProfileProvider).value;
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    const quickBar = ProfileStatsQuickBar();

    // Wide windows keep a readable column, with the app bar still across the whole width.
    final sideSpace = ((MediaQuery.sizeOf(context).width - 720) / 2).clamp(
      0.0,
      double.infinity,
    );

    return Scaffold(
      body: Stack(
        children: [
          const AmbientBloomBackground(),
          ScrollConfiguration(
            behavior: const NoScrollbarBehavior(),
            child: CustomScrollView(
              slivers: [
                // Leaves the way on scrolling down and comes back at the first scroll up.
                SliverAppBar(
                  floating: true,
                  snap: true,
                  title: Text(active?.name ?? l10n.profileTitle),
                  backgroundColor: Colors.transparent,
                  flexibleSpace: const WindowAmbient(),
                  scrolledUnderElevation: 0,
                  surfaceTintColor: Colors.transparent,
                  actions: [
                    IconButton(
                      icon: const Icon(Icons.swap_horiz),
                      tooltip: l10n.profileSwitch,
                      onPressed: () => showProfileSwitchDialog(context),
                    ),
                  ],
                ),
                SliverPadding(
                  padding: EdgeInsets.fromLTRB(
                    16 + sideSpace,
                    24,
                    16 + sideSpace,
                    context.layout.scrollBottomOf(context),
                  ),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      if (isWide)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            ProfileHeader(active: active, compact: true),
                            const SizedBox(width: 24),
                            Expanded(child: quickBar),
                          ],
                        )
                      else ...[
                        Center(child: ProfileHeader(active: active)),
                        const SizedBox(height: 18),
                        quickBar,
                      ],
                      const SizedBox(height: 18),
                      CustomPaint(
                        size: const Size(double.infinity, 8),
                        painter: BrushLinePainter(
                          curvy: context.options.effects.brushStrokes,
                          color: Theme.of(context).colorScheme.outlineVariant
                              .withValues(alpha: 0.6),
                        ),
                      ),
                      AppSectionLabel(label: l10n.profileActivitySectionTitle),
                      AppListRow(
                        icon: Icons.bar_chart_rounded,
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: l10n.profileStatsTitle,
                        subtitle: l10n.statsLibraryBreakdown,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfileStatsCalendarPage(initialTab: 0),
                          ),
                        ),
                      ),
                      AppListRow(
                        icon: Icons.calendar_month_rounded,
                        iconColor: Theme.of(context).colorScheme.primary,
                        title: l10n.profileCalendarTitle,
                        subtitle: l10n.profileCalendarSubtitle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const ProfileStatsCalendarPage(initialTab: 1),
                          ),
                        ),
                      ),
                      AppSectionLabel(label: l10n.profileTrackersSectionTitle),
                      const AniListTrackerTile(),
                      AppSectionLabel(label: l10n.profileSyncSectionTitle),
                      AppListRow(
                        icon: Icons.sync_outlined,
                        title: l10n.profileSyncSectionTitle,
                        subtitle: l10n.syncSubtitle,
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const SyncSettingsPage(),
                          ),
                        ),
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
