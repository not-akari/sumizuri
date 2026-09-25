import 'package:flutter/material.dart';

import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/core/gestures/key_chord.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/controls/pick_row.dart';
import 'package:sumizuri/features/settings/widgets/reader_controls_widgets.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String _libraryLabel(AppLocalizations l10n, LibraryCoverAction action) =>
    switch (action) {
      LibraryCoverAction.open => l10n.libraryActionOpen,
      LibraryCoverAction.select => l10n.libraryActionSelect,
      LibraryCoverAction.none => l10n.readerControlsNothing,
    };

IconData _libraryIcon(LibraryCoverAction action) => switch (action) {
  LibraryCoverAction.open => Icons.open_in_new_rounded,
  LibraryCoverAction.select => Icons.check_circle_outline_rounded,
  LibraryCoverAction.none => Icons.block_outlined,
};

String _chapterLabel(AppLocalizations l10n, ChapterRowAction action) =>
    switch (action) {
      ChapterRowAction.toggleRead => l10n.chapterActionToggleRead,
      ChapterRowAction.download => l10n.chapterActionDownload,
      ChapterRowAction.toggleBookmark => l10n.chapterActionBookmark,
      ChapterRowAction.select => l10n.chapterActionSelect,
      ChapterRowAction.none => l10n.readerControlsNothing,
    };

IconData _chapterIcon(ChapterRowAction action) => switch (action) {
  ChapterRowAction.toggleRead => Icons.done_all_rounded,
  ChapterRowAction.download => Icons.download_outlined,
  ChapterRowAction.toggleBookmark => Icons.bookmark_border_rounded,
  ChapterRowAction.select => Icons.check_circle_outline_rounded,
  ChapterRowAction.none => Icons.block_outlined,
};

String _navLabel(AppLocalizations l10n, NavDoubleTapAction action) =>
    switch (action) {
      NavDoubleTapAction.search => l10n.navActionSearch,
      NavDoubleTapAction.none => l10n.readerControlsNothing,
    };

IconData _navIcon(NavDoubleTapAction action) => switch (action) {
  NavDoubleTapAction.search => Icons.search_rounded,
  NavDoubleTapAction.none => Icons.block_outlined,
};

String appShortcutLabel(AppLocalizations l10n, AppShortcut shortcut) =>
    switch (shortcut) {
      AppShortcut.nextTab => l10n.appShortcutNextTab,
      AppShortcut.previousTab => l10n.appShortcutPreviousTab,
      AppShortcut.search => l10n.appShortcutSearch,
      AppShortcut.openSettings => l10n.appShortcutOpenSettings,
    };

IconData _shortcutIcon(AppShortcut shortcut) => switch (shortcut) {
  AppShortcut.nextTab => Icons.arrow_forward_rounded,
  AppShortcut.previousTab => Icons.arrow_back_rounded,
  AppShortcut.search => Icons.search_rounded,
  AppShortcut.openSettings => Icons.settings_outlined,
};

/// What a touch, a long press or a swipe does around the app, and the keyboard
/// shortcuts of the desktop. Each choice is a row that shows what it does now
/// and opens the options when tapped.
class AppGesturesTab extends StatelessWidget {
  const AppGesturesTab({
    super.key,
    required this.gestures,
    required this.onChanged,
    required this.showShortcuts,
    required this.onAddShortcut,
  });

  final AppGestures gestures;
  final ValueChanged<AppGestures> onChanged;

  final bool showShortcuts;
  final ValueChanged<AppShortcut> onAddShortcut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final gutter = context.layout.gutter;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 720),
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 96),
          children: [
            AppSectionLabel(label: l10n.appGesturesLibrary),
            PickRow<LibraryCoverAction>(
              icon: Icons.touch_app_outlined,
              title: l10n.appGesturesTap,
              value: gestures.libraryTap,
              values: LibraryCoverAction.values,
              labelOf: (v) => _libraryLabel(l10n, v),
              iconOf: _libraryIcon,
              onChanged: (v) => onChanged(gestures.copyWith(libraryTap: v)),
            ),
            PickRow<LibraryCoverAction>(
              icon: Icons.pan_tool_alt_outlined,
              title: l10n.appGesturesLongPress,
              value: gestures.libraryLongPress,
              values: LibraryCoverAction.values,
              labelOf: (v) => _libraryLabel(l10n, v),
              iconOf: _libraryIcon,
              onChanged: (v) =>
                  onChanged(gestures.copyWith(libraryLongPress: v)),
            ),
            PickRow<LibraryCoverAction>(
              icon: Icons.ads_click_outlined,
              title: l10n.appGesturesDoubleTap,
              value: gestures.libraryDoubleTap,
              values: LibraryCoverAction.values,
              labelOf: (v) => _libraryLabel(l10n, v),
              iconOf: _libraryIcon,
              onChanged: (v) =>
                  onChanged(gestures.copyWith(libraryDoubleTap: v)),
            ),
            AppSectionLabel(label: l10n.appGesturesChapters),
            PickRow<ChapterRowAction>(
              icon: Icons.swipe_right_alt_rounded,
              title: l10n.appGesturesSwipeRight,
              value: gestures.chapterSwipeRight,
              values: ChapterRowAction.values,
              labelOf: (v) => _chapterLabel(l10n, v),
              iconOf: _chapterIcon,
              onChanged: (v) =>
                  onChanged(gestures.copyWith(chapterSwipeRight: v)),
            ),
            PickRow<ChapterRowAction>(
              icon: Icons.swipe_left_alt_rounded,
              title: l10n.appGesturesSwipeLeft,
              value: gestures.chapterSwipeLeft,
              values: ChapterRowAction.values,
              labelOf: (v) => _chapterLabel(l10n, v),
              iconOf: _chapterIcon,
              onChanged: (v) =>
                  onChanged(gestures.copyWith(chapterSwipeLeft: v)),
            ),
            PickRow<ChapterRowAction>(
              icon: Icons.pan_tool_alt_outlined,
              title: l10n.appGesturesLongPress,
              value: gestures.chapterLongPress,
              values: ChapterRowAction.values,
              labelOf: (v) => _chapterLabel(l10n, v),
              iconOf: _chapterIcon,
              onChanged: (v) =>
                  onChanged(gestures.copyWith(chapterLongPress: v)),
            ),
            AppSectionLabel(label: l10n.appGesturesNavigation),
            PickRow<NavDoubleTapAction>(
              icon: Icons.ads_click_outlined,
              title: l10n.appGesturesNavDoubleTap,
              value: gestures.navDoubleTap,
              values: NavDoubleTapAction.values,
              labelOf: (v) => _navLabel(l10n, v),
              iconOf: _navIcon,
              onChanged: (v) => onChanged(gestures.copyWith(navDoubleTap: v)),
            ),
            AppSwitchRow(
              icon: Icons.swipe_rounded,
              title: l10n.appGesturesSwipeTabs,
              subtitle: l10n.appGesturesSwipeTabsHint,
              value: gestures.swipeBetweenTabs,
              onChanged: (v) =>
                  onChanged(gestures.copyWith(swipeBetweenTabs: v)),
            ),
            if (showShortcuts) ...[
              AppSectionLabel(label: l10n.appGesturesShortcuts),
              for (final shortcut in AppShortcut.values)
                AppListRow(
                  icon: _shortcutIcon(shortcut),
                  title: appShortcutLabel(l10n, shortcut),
                  subtitleWidget: Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: ChordChips(
                      chords: <KeyChord>[...gestures.shortcuts[shortcut]!],
                      onRemove: (chord) =>
                          onChanged(gestures.withoutShortcut(shortcut, chord)),
                    ),
                  ),
                  trailing: IconButton(
                    tooltip: l10n.readerControlsAddKey,
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () => onAddShortcut(shortcut),
                  ),
                  onTap: () => onAddShortcut(shortcut),
                ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton(
                onPressed: () => onChanged(AppGestures.defaults),
                child: Text(l10n.appGesturesReset),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
