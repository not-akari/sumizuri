import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/core/navigation/nav_destination_presentation.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/cards/reorderable_card_row.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// Where the app's destinations go and how they are laid out: the style of
/// the navigation, then one list of what is in it (drag to reorder, switch off
/// to hide) with everything hidden listed underneath to switch back on.
class NavDestinationsEditor extends ConsumerWidget {
  const NavDestinationsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final side = AppRowStyle.marginOf(context);
    final mode = ref.watch(libraryModeProvider).value ?? AppLibraryMode.unified;
    final enabledTypes = ref.watch(enabledMediaTypesProvider).orMangaOnly;
    final destinations = ref.watch(navDestinationsProvider).value ?? const [];
    final navStyle = ref.watch(navStyleProvider).value ?? AppNavStyle.auto;
    final repository = ref.read(settingsRepositoryProvider);

    bool isFixed(NavDestinationKind k) =>
        k == NavDestinationKind.settings || k == NavDestinationKind.profile;

    // What can be shown but is not, in the order the app offers them.
    final hidden = [
      for (final kind in navDestinationPoolFor(mode, enabledTypes))
        if (!isFixed(kind) && !destinations.contains(kind)) kind,
    ];

    void toggle(NavDestinationKind kind, bool included) {
      final next = [...destinations];
      if (included) {
        if (!next.contains(kind)) next.add(kind);
      } else {
        next.remove(kind);
      }
      repository.setNavDestinations(next);

      final mediaType = kind.mediaType;
      if (mediaType == null) return;
      if (included) {
        repository.setEnabledMediaTypes({...enabledTypes, mediaType});
      } else if (enabledTypes.length > 1) {
        repository.setEnabledMediaTypes({...enabledTypes}..remove(mediaType));
      }
    }

    void reorder(int oldIndex, int newIndex) {
      final next = [...destinations];
      final item = next.removeAt(oldIndex);
      next.insert(newIndex, item);
      repository.setNavDestinations(next);
    }

    Text name(NavDestinationKind kind) => Text(
      navDestinationLabel(kind, l10n),
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          tone: AppCardTone.inset,
          margin: EdgeInsets.symmetric(horizontal: side, vertical: 4),
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                l10n.navStyleTitle,
                style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              AppChoice<AppNavStyle>(
                style: AppChoiceStyle.pills,
                options: [
                  AppChoiceOption(
                    AppNavStyle.auto,
                    l10n.navStyleAuto,
                    icon: Icons.auto_awesome_outlined,
                  ),
                  AppChoiceOption(
                    AppNavStyle.island,
                    l10n.navStyleIsland,
                    icon: Icons.blur_circular,
                  ),
                  AppChoiceOption(
                    AppNavStyle.bottomBar,
                    l10n.navStyleBottomBar,
                    icon: Icons.view_agenda_outlined,
                  ),
                  AppChoiceOption(
                    AppNavStyle.rail,
                    l10n.navStyleRail,
                    icon: Icons.vertical_split_outlined,
                  ),
                  AppChoiceOption(
                    AppNavStyle.drawer,
                    l10n.navStyleDrawer,
                    icon: Icons.menu_open,
                  ),
                ],
                value: navStyle,
                onChanged: repository.setNavStyle,
              ),
            ],
          ),
        ),
        AppSectionLabel(label: l10n.navSectionShown),
        Padding(
          padding: EdgeInsets.fromLTRB(side, 0, side, 6),
          child: Text(
            l10n.navCustomizationHint,
            style: TextStyle(fontSize: 12, height: 1.4, color: cs.outline),
          ),
        ),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: reorder,
          proxyDecorator: reorderableCardProxyDecorator,
          children: [
            for (final (index, kind) in destinations.indexed)
              ReorderableCardRow(
                key: ValueKey(kind),
                dragIndex: index,
                icon: navDestinationIcon(kind),
                title: name(kind),
                subtitle: isFixed(kind) ? l10n.navAlwaysShown : null,
                trailing: [
                  if (isFixed(kind))
                    Icon(Icons.lock_outline, size: 18, color: cs.outline)
                  else
                    Switch(value: true, onChanged: (_) => toggle(kind, false)),
                ],
              ),
          ],
        ),
        if (hidden.isNotEmpty) ...[
          AppSectionLabel(label: l10n.navSectionHidden),
          for (final kind in hidden)
            ReorderableCardRow(
              icon: navDestinationIcon(kind),
              title: name(kind),
              dimmed: true,
              onTap: () => toggle(kind, true),
              trailing: [
                Switch(value: false, onChanged: (_) => toggle(kind, true)),
              ],
            ),
        ],
      ],
    );
  }
}
