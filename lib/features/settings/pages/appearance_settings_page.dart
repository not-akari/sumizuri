import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/navigation/squiggle_tab_bar.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/navigation/nav_destinations_editor.dart';
import 'package:sumizuri/features/settings/widgets/dashboard_section_order_editor.dart';
import 'package:sumizuri/features/settings/widgets/library_display_settings_body.dart';
import 'package:sumizuri/features/settings/widgets/list_style_chooser.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/widgets/background_look_panel.dart';
import 'package:sumizuri/features/settings/widgets/settings_scaffold.dart';
import 'package:sumizuri/features/settings/widgets/theme_settings_body.dart';

enum AppearanceSection {
  mode,
  theme,
  gridTileSize,
  navigation,
  homeScreenOrder,
  motion,
  background,
  listStyle,
}

/// The tabs the page is split into, so no one tab is a long scroll. The look
/// of the background itself belongs to a theme and is edited in its editor.
enum _AppearanceTab { theme, layout }

_AppearanceTab _tabOf(AppearanceSection section) => switch (section) {
  AppearanceSection.mode ||
  AppearanceSection.theme ||
  AppearanceSection.background => _AppearanceTab.theme,
  AppearanceSection.listStyle ||
  AppearanceSection.gridTileSize ||
  AppearanceSection.navigation ||
  AppearanceSection.homeScreenOrder ||
  AppearanceSection.motion => _AppearanceTab.layout,
};

class AppearanceSettingsPage extends ConsumerStatefulWidget {
  const AppearanceSettingsPage({super.key, this.highlight});

  final AppearanceSection? highlight;

  @override
  ConsumerState<AppearanceSettingsPage> createState() =>
      _AppearanceSettingsPageState();
}

class _AppearanceSettingsPageState
    extends ConsumerState<AppearanceSettingsPage> {
  final _sectionKeys = {
    for (final s in AppearanceSection.values) s: GlobalKey(),
  };
  AppearanceSection? _flashing;
  late _AppearanceTab _tab = widget.highlight == null
      ? _AppearanceTab.theme
      : _tabOf(widget.highlight!);

  @override
  void initState() {
    super.initState();
    final target = widget.highlight;
    if (target == null) return;
    WidgetsBinding.instance.addPostFrameCallback((_) => _highlight(target));
  }

  Future<void> _highlight(AppearanceSection target) async {
    final ctx = _sectionKeys[target]?.currentContext;
    if (ctx != null) {
      await Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        alignment: 0.1,
      );
    }
    if (!mounted) return;
    setState(() => _flashing = target);
    await Future<void>.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() => _flashing = null);
  }

  /// One labelled part of a tab. A body that draws its own rows is left as it
  /// is; a padded one gets the page gutter, with its rows taking no margin of
  /// their own so they are not indented twice.
  Widget _section(
    AppearanceSection id,
    String title,
    Widget body, {
    bool padded = true,
  }) {
    final theme = Theme.of(context);
    return AnimatedContainer(
      key: _sectionKeys[id],
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: _flashing == id
            ? theme.colorScheme.primaryContainer
            : Colors.transparent,
        borderRadius: context.shapes.item.radius,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AppSectionLabel(label: title),
          if (padded)
            AppRowStyle(
              horizontalMargin: 0,
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: context.layout.gutter,
                ),
                child: body,
              ),
            )
          else
            body,
        ],
      ),
    );
  }

  List<Widget> _tabBody(AppLocalizations l10n, bool reduceMotion) =>
      switch (_tab) {
        _AppearanceTab.theme => [
          _section(
            AppearanceSection.mode,
            l10n.appearanceModeSection,
            const ThemeModeSelector(),
          ),
          _section(
            AppearanceSection.theme,
            l10n.settingsThemeTile,
            const ThemeGalleryConnected(manage: true),
          ),
          _section(
            AppearanceSection.background,
            l10n.backgroundTitle,
            const BackgroundLookPanel(),
            padded: false,
          ),
        ],
        _AppearanceTab.layout => [
          _section(
            AppearanceSection.listStyle,
            l10n.listStyleTitle,
            const ListStyleChooser(),
          ),
          _section(
            AppearanceSection.gridTileSize,
            l10n.settingsGridTileSizeTile,
            const Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                LibraryDisplaySettingsBody(),
                LibraryDisplayPlacesBody(),
              ],
            ),
          ),
          _section(
            AppearanceSection.navigation,
            l10n.navCustomizationTitle,
            const NavDestinationsEditor(),
          ),
          _section(
            AppearanceSection.homeScreenOrder,
            l10n.homeScreenOrderTitle,
            const DashboardSectionOrderEditor(),
          ),
          _section(
            AppearanceSection.motion,
            l10n.appearanceTabAccessibility,
            AppListRow(
              icon: Icons.motion_photos_off_outlined,
              title: l10n.settingsReduceMotionTile,
              subtitle: l10n.settingsReduceMotionSubtitle,
              trailing: Switch(
                value: reduceMotion,
                onChanged: (value) =>
                    ref.read(settingsRepositoryProvider).setReduceMotion(value),
              ),
              onTap: () => ref
                  .read(settingsRepositoryProvider)
                  .setReduceMotion(!reduceMotion),
            ),
            padded: false,
          ),
        ],
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = ref.watch(reduceMotionProvider).value ?? false;
    return SettingsScaffold(
      title: Text(l10n.settingsSectionAppearance),
      body: Column(
        children: [
          SquiggleTabBar(
            labels: [l10n.settingsThemeTile, l10n.appearanceTabLayout],
            activeIndex: _tab.index,
            onSelected: (i) => setState(() => _tab = _AppearanceTab.values[i]),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(0, 4, 0, 96),
              children: _tabBody(l10n, reduceMotion),
            ),
          ),
        ],
      ),
    );
  }
}
