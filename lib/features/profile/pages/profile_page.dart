import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/no_scrollbar.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/profile/widgets/profile_activity.dart';
import 'package:sumizuri/features/profile/widgets/profile_dialogs.dart';
import 'package:sumizuri/features/profile/widgets/profile_header.dart';
import 'package:sumizuri/features/statistics/pages/profile_stats_calendar_page.dart';
import 'package:sumizuri/features/sync/pages/sync_settings_page.dart';
import 'package:sumizuri/features/trackers/data/tracker_client_config.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_tile.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  // Wide enough to put the profile card beside its sections.
  static const _wideBreakpoint = 900.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final active = ref.watch(activeProfileProvider).value;
    final width = MediaQuery.sizeOf(context).width;
    final isWide = width >= _wideBreakpoint;
    final gutter = context.layout.gutter;

    void open(Widget page) =>
        Navigator.of(context)
            .push(MaterialPageRoute<void>(builder: (_) => page));

    // Everything the profile leads to, as the same soft cards the settings use.
    final shortcuts = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(label: l10n.profileActivitySectionTitle),
        AppListRow(
          icon: Icons.bar_chart_rounded,
          iconColor: cs.primary,
          title: l10n.profileStatsTitle,
          subtitle: l10n.statsLibraryBreakdown,
          onTap: () => open(const ProfileStatsCalendarPage(initialTab: 0)),
        ),
        AppListRow(
          icon: Icons.calendar_month_rounded,
          iconColor: cs.primary,
          title: l10n.profileCalendarTitle,
          subtitle: l10n.profileCalendarSubtitle,
          onTap: () => open(const ProfileStatsCalendarPage(initialTab: 1)),
        ),
        AppSectionLabel(label: l10n.profileTrackersSectionTitle),
        const TrackerTile(kind: TrackerKind.anilist),
        if (malConfigured) const TrackerTile(kind: TrackerKind.mal),
        AppSectionLabel(label: l10n.profileSyncSectionTitle),
        AppListRow(
          icon: Icons.sync_outlined,
          iconColor: cs.primary,
          title: l10n.profileSyncSectionTitle,
          subtitle: l10n.syncSubtitle,
          onTap: () => open(const SyncSettingsPage()),
        ),
      ],
    );

    final hero = ProfileHeroCard(active: active, wide: isWide);

    // Reading and watching, kept out of history, progress and statistics.
    // It belongs to the profile, since those are what it keeps clean.
    final incognito = AppSwitchRow(
      icon: Icons.visibility_off_outlined,
      title: l10n.incognitoTitle,
      subtitle: l10n.incognitoHint,
      value: ref.watch(incognitoModeProvider).value ?? false,
      onChanged: ref.read(settingsRepositoryProvider).setIncognito,
    );
    final recent = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(label: l10n.profileRecentActivity),
        const ProfileActivityCard(),
        const ProfileMostReadShelf(),
      ],
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
                  title: Text(l10n.profileTitle),
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
                SliverToBoxAdapter(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxWidth: isWide ? 1120 : 640,
                      ),
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                          gutter,
                          12,
                          gutter,
                          context.layout.scrollBottomOf(context, 32),
                        ),
                        // The cards carry no side margin: the page places them.
                        child: AppRowStyle(
                          horizontalMargin: 0,
                          child: isWide
                              ? Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    hero,
                                    const SizedBox(height: 8),
                                    incognito,
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(flex: 3, child: recent),
                                        const SizedBox(width: 28),
                                        Expanded(flex: 2, child: shortcuts),
                                      ],
                                    ),
                                  ],
                                )
                              : Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    hero,
                                    incognito,
                                    recent,
                                    shortcuts,
                                  ],
                                ),
                        ),
                      ),
                    ),
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
