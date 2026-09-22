import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/navigation/nav_destinations_editor.dart';
import 'package:sumizuri/features/settings/widgets/dashboard_section_order_editor.dart';
import 'package:sumizuri/features/settings/widgets/library_grid_tile_size_settings_body.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/widgets/background_look_panel.dart';
import 'package:sumizuri/features/settings/widgets/theme_settings_body.dart';

enum AppearanceSection {
  mode,
  theme,
  gridTileSize,
  navigation,
  homeScreenOrder,
  motion,
  background,
}

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              16,
              context.layout.gutter,
              8,
            ),
            child: Text(
              title.toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                fontSize: 11.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
                color: theme.colorScheme.outline,
              ),
            ),
          ),
          padded
              ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: context.layout.gutter,
                  ),
                  child: body,
                )
              : body,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = ref.watch(reduceMotionProvider).value ?? false;
    return AmbientScaffold(
      title: Text(l10n.settingsSectionAppearance),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(0, 8, 0, 96),
        // Capped so rows and cards stay a readable width on wide windows.
        children: [
          Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                  _section(
                    AppearanceSection.gridTileSize,
                    l10n.settingsGridTileSizeTile,
                    const LibraryGridTileSizeSettingsBody(),
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
                    l10n.settingsReduceMotionTile,
                    AppListRow(
                      icon: Icons.motion_photos_off_outlined,
                      title: l10n.settingsReduceMotionTile,
                      subtitle: l10n.settingsReduceMotionSubtitle,
                      trailing: Switch(
                        value: reduceMotion,
                        onChanged: (value) => ref
                            .read(settingsRepositoryProvider)
                            .setReduceMotion(value),
                      ),
                    ),
                    padded: false,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
