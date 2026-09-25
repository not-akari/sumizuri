import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/core/widgets/cards/reorderable_card_row.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

IconData _dashboardSectionIcon(DashboardSectionKind kind) => switch (kind) {
  DashboardSectionKind.updates => Icons.new_releases_outlined,
  DashboardSectionKind.history => Icons.history,
  DashboardSectionKind.library => Icons.collections_bookmark_outlined,
};

String _dashboardSectionLabel(
  DashboardSectionKind kind,
  AppLocalizations l10n,
) => switch (kind) {
  DashboardSectionKind.updates => l10n.updatesTitle,
  DashboardSectionKind.history => l10n.historyTitle,
  DashboardSectionKind.library => l10n.libraryTitle,
};

class DashboardSectionOrderEditor extends ConsumerWidget {
  const DashboardSectionOrderEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final order = ref.watch(dashboardSectionOrderProvider).value ?? const [];
    final pinned = ref.watch(navDestinationsProvider).value ?? const [];
    final repository = ref.read(settingsRepositoryProvider);

    bool isPinned(DashboardSectionKind kind) => switch (kind) {
      DashboardSectionKind.updates => pinned.contains(
        NavDestinationKind.updates,
      ),
      DashboardSectionKind.history => pinned.contains(
        NavDestinationKind.history,
      ),
      DashboardSectionKind.library => false,
    };
    final visible = [
      for (final kind in order)
        if (!isPinned(kind)) kind,
    ];

    void reorder(int oldIndex, int newIndex) {
      final moved = [...visible];
      moved.insert(newIndex, moved.removeAt(oldIndex));
      var next = 0;
      repository.setDashboardSectionOrder([
        for (final kind in order) isPinned(kind) ? kind : moved[next++],
      ]);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.homeScreenOrderHint,
          style: TextStyle(fontSize: 12, color: cs.outline),
        ),
        const SizedBox(height: 10),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: reorder,
          proxyDecorator: reorderableCardProxyDecorator,
          children: [
            for (final (index, kind) in visible.indexed)
              ReorderableCardRow(
                key: ValueKey(kind),
                dragIndex: index,
                icon: _dashboardSectionIcon(kind),
                title: Text(
                  _dashboardSectionLabel(kind, l10n),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
