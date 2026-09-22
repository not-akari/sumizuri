import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/core/gestures/key_chord.dart';
import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/window/native_title_bar.dart';
import 'package:sumizuri/core/widgets/navigation/animated_indexed_stack.dart';
import 'package:sumizuri/core/widgets/navigation/bottom_bar_nav.dart';
import 'package:sumizuri/core/widgets/navigation/island_nav_bar.dart';
import 'package:sumizuri/core/widgets/navigation/nav_rail.dart';
import 'package:sumizuri/core/widgets/cards/profile_avatar_button.dart';
import 'package:sumizuri/core/widgets/navigation/side_drawer_nav.dart';
import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/core/navigation/shortcut_link.dart';
import 'package:sumizuri/features/profile/models/profile.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/pages/browse_screen.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/extensions/pages/global_search_page.dart';
import 'package:sumizuri/features/library/pages/history_screen.dart';
import 'package:sumizuri/features/library/pages/library_screen.dart';
import 'package:sumizuri/features/library/pages/updates_screen.dart';
import 'package:sumizuri/core/navigation/nav_destination_presentation.dart';
import 'package:sumizuri/features/profile/pages/profile_page.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/pages/settings_screen.dart';

const _compactBreakpoint = 600.0;

// How far the floating tab bar reaches up from the bottom edge.
const _floatingBarReach = 16.0 + 56.0 + 8.0;

/// Tells pages under the tab bar where the screen bottom starts, so lists leave room.
class _ClearFloatingBar extends StatelessWidget {
  const _ClearFloatingBar({required this.enabled, required this.child});

  final bool enabled;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    final media = MediaQuery.of(context);
    final bottom = media.padding.bottom < _floatingBarReach
        ? _floatingBarReach
        : media.padding.bottom;
    return MediaQuery(
      data: media.copyWith(
        padding: media.padding.copyWith(bottom: bottom),
        viewPadding: media.viewPadding.copyWith(bottom: bottom),
      ),
      child: child,
    );
  }
}

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _index = 0;

  List<NavDestinationKind> _destinations = const [];
  AppGestures _gestures = AppGestures.defaults;

  @override
  void initState() {
    super.initState();
    if (isDesktopWindowPlatform) {
      HardwareKeyboard.instance.addHandler(_onKey);
    }
    // Process shortcut links arriving before shell is built (cold start).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final kind = ref.read(requestedNavDestinationProvider);
      if (kind == null) return;
      ref.read(requestedNavDestinationProvider.notifier).clear();
      final at = _destinations.indexOf(kind);
      if (at >= 0) setState(() => _index = at);
    });
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_onKey);
    super.dispose();
  }

  bool _onKey(KeyEvent event) {
    if (event is! KeyDownEvent || !mounted) return false;
    if (ModalRoute.of(context)?.isCurrent != true) return false;
    final keyboard = HardwareKeyboard.instance;
    final shortcut = _gestures.shortcutFor(
      KeyChord(
        event.logicalKey.keyId,
        ctrl: keyboard.isControlPressed,
        shift: keyboard.isShiftPressed,
        alt: keyboard.isAltPressed,
        meta: keyboard.isMetaPressed,
      ),
    );
    if (shortcut == null || _destinations.isEmpty) return false;
    final count = _destinations.length;
    switch (shortcut) {
      case AppShortcut.nextTab:
        setState(() => _index = (_index + 1) % count);
      case AppShortcut.previousTab:
        setState(() => _index = (_index - 1 + count) % count);
      case AppShortcut.search:
        _openSearch(_destinations[_index < count ? _index : 0]);
      case AppShortcut.openSettings:
        final settings = _destinations.indexOf(NavDestinationKind.settings);
        if (settings >= 0) setState(() => _index = settings);
    }
    return true;
  }

  void _openSearch(NavDestinationKind current) {
    final mediaType =
        current.mediaType ??
        _destinations.map((k) => k.mediaType).nonNulls.firstOrNull;
    if (mediaType == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GlobalSearchPage(mediaType: mediaType)),
    );
  }

  Widget _pageFor(NavDestinationKind kind, AppLocalizations l10n) {
    final mediaType = kind.mediaType;
    if (mediaType != null) {
      return LibraryScreen(
        mediaType: mediaType,
        title: navDestinationLabel(kind, l10n),
      );
    }
    return switch (kind) {
      NavDestinationKind.library => const LibraryScreen(),
      NavDestinationKind.updates => const UpdatesScreen(),
      NavDestinationKind.history => const HistoryScreen(),
      NavDestinationKind.browse => const BrowseScreen(),
      NavDestinationKind.profile => const ProfilePage(),
      NavDestinationKind.settings => const SettingsScreen(),
      NavDestinationKind.mangaLibrary ||
      NavDestinationKind.novelLibrary ||
      NavDestinationKind.animeLibrary => throw StateError('handled above'),
    };
  }

  void _onDoubleTap(NavDestinationKind kind) {
    if (_gestures.navDoubleTap == NavDoubleTapAction.none) return;
    final mediaType = kind.mediaType;
    if (mediaType == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => GlobalSearchPage(mediaType: mediaType)),
    );
  }

  AppNavStyle _effectiveStyle(AppNavStyle setting, double width) {
    if (setting != AppNavStyle.auto) return setting;
    return width < _compactBreakpoint ? AppNavStyle.island : AppNavStyle.rail;
  }

  List<IslandNavDestination> _islandDestinations(
    List<NavDestinationKind> destinations,
    AppLocalizations l10n,
    Profile? activeProfile,
  ) => [
    for (final kind in destinations)
      IslandNavDestination(
        icon: navDestinationIcon(kind),
        tooltip: navDestinationLabel(kind, l10n),

        onDoubleTap:
            kind.mediaType != null &&
                _gestures.navDoubleTap != NavDoubleTapAction.none
            ? () => _onDoubleTap(kind)
            : null,

        avatar: kind == NavDestinationKind.profile
            ? ProfileAvatar(profile: activeProfile, size: 22)
            : null,
      ),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    ref.watch(installedSourcesProvider);
    final destinations =
        ref.watch(navDestinationsProvider).value ??
        const [NavDestinationKind.settings];
    final navStyleSetting =
        ref.watch(navStyleProvider).value ?? AppNavStyle.auto;
    final activeProfile = ref.watch(activeProfileProvider).value;
    _gestures = ref.watch(appGesturesProvider).value ?? AppGestures.defaults;
    _destinations = destinations;

    // Switch to requested destination if present in current destination list.
    ref.listen(requestedNavDestinationProvider, (_, kind) {
      if (kind == null) return;
      ref.read(requestedNavDestinationProvider.notifier).clear();
      final at = destinations.indexOf(kind);
      if (at >= 0) setState(() => _index = at);
    });

    final index = _index < destinations.length ? _index : 0;

    final pages = [
      for (final kind in destinations)
        KeyedSubtree(key: ValueKey(kind), child: _pageFor(kind, l10n)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final style = _effectiveStyle(navStyleSetting, constraints.maxWidth);

        if (style == AppNavStyle.island || style == AppNavStyle.bottomBar) {
          final content = Stack(
            children: [
              Positioned.fill(
                child: GestureDetector(
                  onHorizontalDragEnd: !_gestures.swipeBetweenTabs
                      ? null
                      : (details) {
                          final velocity = details.primaryVelocity ?? 0;
                          if (velocity.abs() < 200) return;
                          final next = velocity < 0 ? index + 1 : index - 1;
                          if (next >= 0 && next < destinations.length) {
                            setState(() => _index = next);
                          }
                        },
                  child: _ClearFloatingBar(
                    enabled: style == AppNavStyle.island,
                    child: AnimatedIndexedStack(
                      index: index,
                      motion: AnimatedStackMotion.slide,

                      duration: AppMotion.fast,
                      children: pages,
                    ),
                  ),
                ),
              ),
              if (style == AppNavStyle.island)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 16,
                  child: Center(
                    child: IslandNavBar(
                      destinations: _islandDestinations(
                        destinations,
                        l10n,
                        activeProfile,
                      ),
                      selectedIndex: index,
                      onSelected: (i) => setState(() => _index = i),
                    ),
                  ),
                ),
            ],
          );

          return Scaffold(
            body: style == AppNavStyle.island
                ? content
                : Column(children: [Expanded(child: content)]),
            bottomNavigationBar: style == AppNavStyle.bottomBar
                ? BottomBarNav(
                    destinations: _islandDestinations(
                      destinations,
                      l10n,
                      activeProfile,
                    ),
                    selectedIndex: index,
                    onSelected: (i) => setState(() => _index = i),
                  )
                : null,
          );
        }

        return Scaffold(
          body: Row(
            children: [
              if (style == AppNavStyle.drawer)
                SideDrawerNav(
                  destinations: _islandDestinations(
                    destinations,
                    l10n,
                    activeProfile,
                  ),
                  selectedIndex: index,
                  onSelected: (i) => setState(() => _index = i),
                )
              else
                SumizuriNavRail(
                  destinations: _islandDestinations(
                    destinations,
                    l10n,
                    activeProfile,
                  ),
                  selectedIndex: index,
                  onSelected: (i) => setState(() => _index = i),
                ),
              const VerticalDivider(width: 1),
              Expanded(
                child: AnimatedIndexedStack(
                  index: index,
                  motion: AnimatedStackMotion.depth,
                  duration: AppMotion.fast,
                  children: pages,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
