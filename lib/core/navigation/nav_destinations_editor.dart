import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/cards/reorderable_card_row.dart';
import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';
import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/core/navigation/nav_destination_presentation.dart';

class NavDestinationsEditor extends ConsumerWidget {
  const NavDestinationsEditor({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final titleStyle = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: cs.onSurface,
    );
    final hintStyle = TextStyle(fontSize: 12, color: cs.outline);
    final mode = ref.watch(libraryModeProvider).value ?? AppLibraryMode.unified;
    final enabledTypes = ref.watch(enabledMediaTypesProvider).orMangaOnly;
    final destinations = ref.watch(navDestinationsProvider).value ?? const [];
    final navStyle = ref.watch(navStyleProvider).value ?? AppNavStyle.auto;
    final repository = ref.read(settingsRepositoryProvider);

    final pickableKinds = navDestinationPoolFor(mode, enabledTypes).where(
      (k) =>
          k != NavDestinationKind.settings && k != NavDestinationKind.profile,
    );

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

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.navStyleTitle, style: titleStyle),
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
        const SizedBox(height: 24),
        Text(l10n.navCustomizationHint, style: hintStyle),
        const SizedBox(height: 14),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final kind in pickableKinds)
              TogglePill(
                icon: navDestinationIcon(kind),
                label: navDestinationLabel(kind, l10n),
                selected: destinations.contains(kind),
                onTap: () => toggle(kind, !destinations.contains(kind)),
              ),
          ],
        ),
        const SizedBox(height: 24),
        Text(l10n.navCustomizationDragHint, style: titleStyle),
        const SizedBox(height: 10),
        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),

          buildDefaultDragHandles: false,
          onReorderItem: reorder,
          proxyDecorator: reorderableCardProxyDecorator,
          children: [
            for (final (index, kind) in destinations.indexed)
              Padding(
                key: ValueKey(kind),
                padding: const EdgeInsets.only(bottom: 8),
                child: ReorderableCardRow(
                  dragIndex: index,
                  icon: navDestinationIcon(kind),
                  title: Text(
                    navDestinationLabel(kind, l10n),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }
}
