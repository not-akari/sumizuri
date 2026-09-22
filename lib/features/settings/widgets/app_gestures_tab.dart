import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/core/gestures/key_chord.dart';
import 'package:sumizuri/features/settings/widgets/reader_controls_widgets.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String _libraryLabel(AppLocalizations l10n, LibraryCoverAction action) =>
    switch (action) {
      LibraryCoverAction.open => l10n.libraryActionOpen,
      LibraryCoverAction.select => l10n.libraryActionSelect,
      LibraryCoverAction.none => l10n.readerControlsNothing,
    };

String _chapterLabel(AppLocalizations l10n, ChapterRowAction action) =>
    switch (action) {
      ChapterRowAction.toggleRead => l10n.chapterActionToggleRead,
      ChapterRowAction.download => l10n.chapterActionDownload,
      ChapterRowAction.toggleBookmark => l10n.chapterActionBookmark,
      ChapterRowAction.select => l10n.chapterActionSelect,
      ChapterRowAction.none => l10n.readerControlsNothing,
    };

String _navLabel(AppLocalizations l10n, NavDoubleTapAction action) =>
    switch (action) {
      NavDoubleTapAction.search => l10n.navActionSearch,
      NavDoubleTapAction.none => l10n.readerControlsNothing,
    };

String appShortcutLabel(AppLocalizations l10n, AppShortcut shortcut) =>
    switch (shortcut) {
      AppShortcut.nextTab => l10n.appShortcutNextTab,
      AppShortcut.previousTab => l10n.appShortcutPreviousTab,
      AppShortcut.search => l10n.appShortcutSearch,
      AppShortcut.openSettings => l10n.appShortcutOpenSettings,
    };

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
    final text = Theme.of(context).textTheme;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        8,
        context.layout.gutter,
        96,
      ),
      children: [
        AppInlineHeading(l10n.appGesturesLibrary),
        _ChoiceRow<LibraryCoverAction>(
          label: l10n.appGesturesTap,
          value: gestures.libraryTap,
          values: LibraryCoverAction.values,
          labelOf: (v) => _libraryLabel(l10n, v),
          onChanged: (v) => onChanged(gestures.copyWith(libraryTap: v)),
        ),
        _ChoiceRow<LibraryCoverAction>(
          label: l10n.appGesturesLongPress,
          value: gestures.libraryLongPress,
          values: LibraryCoverAction.values,
          labelOf: (v) => _libraryLabel(l10n, v),
          onChanged: (v) => onChanged(gestures.copyWith(libraryLongPress: v)),
        ),
        _ChoiceRow<LibraryCoverAction>(
          label: l10n.appGesturesDoubleTap,
          value: gestures.libraryDoubleTap,
          values: LibraryCoverAction.values,
          labelOf: (v) => _libraryLabel(l10n, v),
          onChanged: (v) => onChanged(gestures.copyWith(libraryDoubleTap: v)),
        ),
        AppInlineHeading(l10n.appGesturesChapters),
        _ChoiceRow<ChapterRowAction>(
          label: l10n.appGesturesSwipeRight,
          value: gestures.chapterSwipeRight,
          values: ChapterRowAction.values,
          labelOf: (v) => _chapterLabel(l10n, v),
          onChanged: (v) => onChanged(gestures.copyWith(chapterSwipeRight: v)),
        ),
        _ChoiceRow<ChapterRowAction>(
          label: l10n.appGesturesSwipeLeft,
          value: gestures.chapterSwipeLeft,
          values: ChapterRowAction.values,
          labelOf: (v) => _chapterLabel(l10n, v),
          onChanged: (v) => onChanged(gestures.copyWith(chapterSwipeLeft: v)),
        ),
        _ChoiceRow<ChapterRowAction>(
          label: l10n.appGesturesLongPress,
          value: gestures.chapterLongPress,
          values: ChapterRowAction.values,
          labelOf: (v) => _chapterLabel(l10n, v),
          onChanged: (v) => onChanged(gestures.copyWith(chapterLongPress: v)),
        ),
        AppInlineHeading(l10n.appGesturesNavigation),
        _ChoiceRow<NavDoubleTapAction>(
          label: l10n.appGesturesNavDoubleTap,
          value: gestures.navDoubleTap,
          values: NavDoubleTapAction.values,
          labelOf: (v) => _navLabel(l10n, v),
          onChanged: (v) => onChanged(gestures.copyWith(navDoubleTap: v)),
        ),
        AppToggleTile(
          dense: false,
          title: l10n.appGesturesSwipeTabs,
          subtitle: l10n.appGesturesSwipeTabsHint,
          value: gestures.swipeBetweenTabs,
          onChanged: (v) => onChanged(gestures.copyWith(swipeBetweenTabs: v)),
        ),
        if (showShortcuts) ...[
          AppInlineHeading(l10n.appGesturesShortcuts),
          for (final shortcut in AppShortcut.values) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    appShortcutLabel(l10n, shortcut),
                    style: text.bodyMedium,
                  ),
                ),
                IconButton(
                  tooltip: l10n.readerControlsAddKey,
                  icon: const Icon(Icons.add),
                  onPressed: () => onAddShortcut(shortcut),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: gestures.shortcuts[shortcut]!.isEmpty
                  ? Text(l10n.readerControlsNotSet, style: text.bodySmall)
                  : Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        for (final KeyChord chord
                            in gestures.shortcuts[shortcut]!)
                          InputChip(
                            label: Text(chordLabel(chord)),
                            onDeleted: () => onChanged(
                              gestures.withoutShortcut(shortcut, chord),
                            ),
                          ),
                      ],
                    ),
            ),
          ],
        ],
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: () => onChanged(AppGestures.defaults),
            child: Text(l10n.appGesturesReset),
          ),
        ),
      ],
    );
  }
}

class _ChoiceRow<T> extends StatelessWidget {
  const _ChoiceRow({
    required this.label,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.onChanged,
  });

  final String label;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          AppChoice<T>.of(
            style: AppChoiceStyle.menu,
            expanded: false,
            values: values,
            label: labelOf,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
