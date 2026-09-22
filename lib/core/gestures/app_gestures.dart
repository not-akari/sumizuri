import 'dart:convert';

import 'package:sumizuri/core/gestures/key_chord.dart';

enum LibraryCoverAction { open, select, none }

enum ChapterRowAction { toggleRead, download, toggleBookmark, select, none }

enum NavDoubleTapAction { search, none }

enum AppShortcut { nextTab, previousTab, search, openSettings }

const _keyF = 0x00000000066;
const _keyComma = 0x0000000002c;
const _keyPageUp = 0x100000000 + 0x308;
const _keyPageDown = 0x100000000 + 0x307;

class AppGestures {
  const AppGestures({
    this.libraryTap = LibraryCoverAction.open,
    this.libraryLongPress = LibraryCoverAction.select,
    this.libraryDoubleTap = LibraryCoverAction.none,
    this.chapterSwipeRight = ChapterRowAction.toggleRead,
    this.chapterSwipeLeft = ChapterRowAction.download,
    this.chapterLongPress = ChapterRowAction.select,
    this.navDoubleTap = NavDoubleTapAction.search,
    this.swipeBetweenTabs = true,
    this.shortcuts = _defaultShortcuts,
  });

  final LibraryCoverAction libraryTap;
  final LibraryCoverAction libraryLongPress;
  final LibraryCoverAction libraryDoubleTap;
  final ChapterRowAction chapterSwipeRight;
  final ChapterRowAction chapterSwipeLeft;
  final ChapterRowAction chapterLongPress;
  final NavDoubleTapAction navDoubleTap;
  final bool swipeBetweenTabs;
  final Map<AppShortcut, List<KeyChord>> shortcuts;

  static const _defaultShortcuts = {
    AppShortcut.nextTab: [KeyChord(_keyPageDown, ctrl: true)],
    AppShortcut.previousTab: [KeyChord(_keyPageUp, ctrl: true)],
    AppShortcut.search: [KeyChord(_keyF, ctrl: true)],
    AppShortcut.openSettings: [KeyChord(_keyComma, ctrl: true)],
  };

  static const defaults = AppGestures();

  AppShortcut? shortcutFor(KeyChord pressed) {
    for (final entry in shortcuts.entries) {
      if (entry.value.contains(pressed)) return entry.key;
    }
    return null;
  }

  AppGestures withShortcut(AppShortcut shortcut, KeyChord chord) {
    final next = {
      for (final entry in shortcuts.entries)
        entry.key: [
          for (final existing in entry.value)
            if (existing != chord) existing,
        ],
    };
    next[shortcut] = [...next[shortcut]!, chord];
    return copyWith(shortcuts: next);
  }

  AppGestures withoutShortcut(AppShortcut shortcut, KeyChord chord) {
    return copyWith(
      shortcuts: {
        for (final entry in shortcuts.entries)
          entry.key: [
            for (final existing in entry.value)
              if (entry.key != shortcut || existing != chord) existing,
          ],
      },
    );
  }

  AppGestures copyWith({
    LibraryCoverAction? libraryTap,
    LibraryCoverAction? libraryLongPress,
    LibraryCoverAction? libraryDoubleTap,
    ChapterRowAction? chapterSwipeRight,
    ChapterRowAction? chapterSwipeLeft,
    ChapterRowAction? chapterLongPress,
    NavDoubleTapAction? navDoubleTap,
    bool? swipeBetweenTabs,
    Map<AppShortcut, List<KeyChord>>? shortcuts,
  }) => AppGestures(
    libraryTap: libraryTap ?? this.libraryTap,
    libraryLongPress: libraryLongPress ?? this.libraryLongPress,
    libraryDoubleTap: libraryDoubleTap ?? this.libraryDoubleTap,
    chapterSwipeRight: chapterSwipeRight ?? this.chapterSwipeRight,
    chapterSwipeLeft: chapterSwipeLeft ?? this.chapterSwipeLeft,
    chapterLongPress: chapterLongPress ?? this.chapterLongPress,
    navDoubleTap: navDoubleTap ?? this.navDoubleTap,
    swipeBetweenTabs: swipeBetweenTabs ?? this.swipeBetweenTabs,
    shortcuts: shortcuts ?? this.shortcuts,
  );

  bool get isDefault => toJsonString() == defaults.toJsonString();

  Map<String, Object?> toJson() => {
    'library': {
      'tap': libraryTap.name,
      'longPress': libraryLongPress.name,
      'doubleTap': libraryDoubleTap.name,
    },
    'chapters': {
      'swipeRight': chapterSwipeRight.name,
      'swipeLeft': chapterSwipeLeft.name,
      'longPress': chapterLongPress.name,
    },
    'navigation': {
      'doubleTap': navDoubleTap.name,
      'swipeBetweenTabs': swipeBetweenTabs,
    },
    'shortcuts': {
      for (final entry in shortcuts.entries)
        entry.key.name: [for (final chord in entry.value) chord.toJson()],
    },
  };

  String toJsonString() => jsonEncode(toJson());

  static AppGestures fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? fromJson(decoded) : defaults;
    } on FormatException {
      return defaults;
    }
  }

  static T _pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
      values.where((v) => v.name == name).firstOrNull ?? fallback;

  static AppGestures fromJson(Map<dynamic, dynamic> json) {
    const d = defaults;
    final library = json['library'] is Map ? json['library'] as Map : const {};
    final chapters = json['chapters'] is Map
        ? json['chapters'] as Map
        : const {};
    final nav = json['navigation'] is Map
        ? json['navigation'] as Map
        : const {};

    final shortcuts = {..._defaultShortcuts};
    final rawShortcuts = json['shortcuts'];
    if (rawShortcuts is Map) {
      final claimed = <KeyChord>{};
      for (final shortcut in AppShortcut.values) {
        final list = rawShortcuts[shortcut.name];
        if (list is! List) continue;
        final chords = <KeyChord>[];
        for (final item in list) {
          final chord = KeyChord.fromJson(item);
          if (chord != null && claimed.add(chord)) chords.add(chord);
        }
        shortcuts[shortcut] = chords;
      }
    }

    return AppGestures(
      libraryTap: _pick(
        LibraryCoverAction.values,
        library['tap'],
        d.libraryTap,
      ),
      libraryLongPress: _pick(
        LibraryCoverAction.values,
        library['longPress'],
        d.libraryLongPress,
      ),
      libraryDoubleTap: _pick(
        LibraryCoverAction.values,
        library['doubleTap'],
        d.libraryDoubleTap,
      ),
      chapterSwipeRight: _pick(
        ChapterRowAction.values,
        chapters['swipeRight'],
        d.chapterSwipeRight,
      ),
      chapterSwipeLeft: _pick(
        ChapterRowAction.values,
        chapters['swipeLeft'],
        d.chapterSwipeLeft,
      ),
      chapterLongPress: _pick(
        ChapterRowAction.values,
        chapters['longPress'],
        d.chapterLongPress,
      ),
      navDoubleTap: _pick(
        NavDoubleTapAction.values,
        nav['doubleTap'],
        d.navDoubleTap,
      ),
      swipeBetweenTabs: nav['swipeBetweenTabs'] is bool
          ? nav['swipeBetweenTabs'] as bool
          : d.swipeBetweenTabs,
      shortcuts: shortcuts,
    );
  }
}
