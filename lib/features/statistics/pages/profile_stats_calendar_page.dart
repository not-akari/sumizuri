import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/statistics/tabs/calendar_tab.dart';
import 'package:sumizuri/features/statistics/tabs/statistics_tab.dart';

class ProfileStatsCalendarPage extends ConsumerStatefulWidget {
  const ProfileStatsCalendarPage({super.key, this.initialTab = 0});

  final int initialTab;

  static const _wideBreakpoint = 900.0;

  @override
  ConsumerState<ProfileStatsCalendarPage> createState() =>
      _ProfileStatsCalendarPageState();
}

class _ProfileStatsCalendarPageState
    extends ConsumerState<ProfileStatsCalendarPage> {
  late int _tab = widget.initialTab.clamp(0, 1);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final activeProfile = ref.watch(activeProfileProvider).value;
    final title = activeProfile != null
        ? '${activeProfile.name} • ${l10n.profileStatsTitle}'
        : l10n.profileStatsTitle;
    final isWide =
        MediaQuery.sizeOf(context).width >=
        ProfileStatsCalendarPage._wideBreakpoint;

    if (isWide) {
      return AmbientScaffold(
        title: Text(title),
        body: Row(
          children: [
            const Expanded(child: StatisticsTab()),
            VerticalDivider(width: 1, color: cs.outlineVariant),
            const Expanded(child: CalendarTab()),
          ],
        ),
      );
    }

    return AmbientScaffold(
      title: Text(title),
      body: Column(
        children: [
          SquiggleTabBar(
            labels: [l10n.profileStatsTitle, l10n.profileCalendarTitle],
            activeIndex: _tab,
            showUnderline: false,
            onSelected: (i) => setState(() => _tab = i),
          ),
          Expanded(
            child: IndexedStack(
              index: _tab,
              children: const [StatisticsTab(), CalendarTab()],
            ),
          ),
        ],
      ),
    );
  }
}
