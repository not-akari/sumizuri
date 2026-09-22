import 'dart:convert';

import 'package:sumizuri/core/gestures/key_chord.dart';

export 'package:sumizuri/core/gestures/key_chord.dart';

enum ReaderAction {
  nextPage,

  previousPage,

  pageRight,
  pageLeft,

  scrollDown,
  scrollUp,

  toggleOverlays,
  nextChapter,
  previousChapter,
  openSettings,

  toggleAutoScroll,
  autoScrollFaster,
  autoScrollSlower,

  openInBrowser,

  toggleBookmark,
}

enum TapLayout { paged, continuous }

const _keySpace = 0x00000000020;
const _keyEscape = 0x100000000 + 0x01b;
const _keyPageUp = 0x100000000 + 0x308;
const _keyPageDown = 0x100000000 + 0x307;
const _keyArrowDown = 0x100000000 + 0x301;
const _keyArrowLeft = 0x100000000 + 0x302;
const _keyArrowRight = 0x100000000 + 0x303;
const _keyArrowUp = 0x100000000 + 0x304;

class ScrollSteps {
  const ScrollSteps({
    this.arrowPixels = 100,
    this.pageFraction = 0.85,
    this.tapFraction = 0.6,
    this.holdSpeed = 700,
    this.autoSpeed = 60,
  });

  final double arrowPixels;

  final double pageFraction;

  final double tapFraction;

  final double holdSpeed;

  final double autoSpeed;

  static const arrowRange = (min: 20.0, max: 600.0);
  static const holdRange = (min: 100.0, max: 3000.0);
  static const autoRange = (min: 10.0, max: 600.0);
  static const fractionRange = (min: 0.1, max: 1.0);

  ScrollSteps copyWith({
    double? arrowPixels,
    double? pageFraction,
    double? tapFraction,
    double? holdSpeed,
    double? autoSpeed,
  }) => ScrollSteps(
    arrowPixels: arrowPixels ?? this.arrowPixels,
    pageFraction: pageFraction ?? this.pageFraction,
    tapFraction: tapFraction ?? this.tapFraction,
    holdSpeed: holdSpeed ?? this.holdSpeed,
    autoSpeed: autoSpeed ?? this.autoSpeed,
  );

  @override
  bool operator ==(Object other) =>
      other is ScrollSteps &&
      other.arrowPixels == arrowPixels &&
      other.pageFraction == pageFraction &&
      other.tapFraction == tapFraction &&
      other.holdSpeed == holdSpeed &&
      other.autoSpeed == autoSpeed;

  @override
  int get hashCode =>
      Object.hash(arrowPixels, pageFraction, tapFraction, holdSpeed, autoSpeed);

  Map<String, Object?> toJson() => {
    'arrowPixels': arrowPixels,
    'pageFraction': pageFraction,
    'tapFraction': tapFraction,
    'holdSpeed': holdSpeed,
    'autoSpeed': autoSpeed,
  };

  static ScrollSteps fromJson(Object? raw) {
    if (raw is! Map) return const ScrollSteps();
    double read(String key, double fallback, ({double min, double max}) range) {
      final v = raw[key];
      return v is num ? v.toDouble().clamp(range.min, range.max) : fallback;
    }

    const d = ScrollSteps();
    return ScrollSteps(
      arrowPixels: read('arrowPixels', d.arrowPixels, arrowRange),
      pageFraction: read('pageFraction', d.pageFraction, fractionRange),
      tapFraction: read('tapFraction', d.tapFraction, fractionRange),
      holdSpeed: read('holdSpeed', d.holdSpeed, holdRange),
      autoSpeed: read('autoSpeed', d.autoSpeed, autoRange),
    );
  }
}

class ReaderControls {
  const ReaderControls({
    required this.keys,
    required this.tapZones,
    this.scroll = const ScrollSteps(),
  });

  final Map<ReaderAction, List<KeyChord>> keys;

  final Map<TapLayout, List<ReaderAction?>> tapZones;

  final ScrollSteps scroll;

  static const zoneCount = 9;

  static const defaults = ReaderControls(
    keys: {
      ReaderAction.nextPage: [KeyChord(_keySpace), KeyChord(_keyPageDown)],
      ReaderAction.previousPage: [KeyChord(_keyPageUp)],
      ReaderAction.pageRight: [KeyChord(_keyArrowRight)],
      ReaderAction.pageLeft: [KeyChord(_keyArrowLeft)],
      ReaderAction.scrollDown: [KeyChord(_keyArrowDown)],
      ReaderAction.scrollUp: [KeyChord(_keyArrowUp)],
      ReaderAction.toggleOverlays: [KeyChord(_keyEscape)],
      ReaderAction.nextChapter: [],
      ReaderAction.previousChapter: [],
      ReaderAction.openSettings: [],
      ReaderAction.toggleAutoScroll: [],
      ReaderAction.autoScrollFaster: [],
      ReaderAction.autoScrollSlower: [],
      ReaderAction.openInBrowser: [],
      ReaderAction.toggleBookmark: [],
    },
    tapZones: {
      TapLayout.paged: [
        ReaderAction.pageLeft,
        ReaderAction.previousPage,
        ReaderAction.pageRight,
        ReaderAction.pageLeft,
        ReaderAction.toggleOverlays,
        ReaderAction.pageRight,
        ReaderAction.pageLeft,
        ReaderAction.nextPage,
        ReaderAction.pageRight,
      ],
      TapLayout.continuous: [
        ReaderAction.previousPage,
        ReaderAction.previousPage,
        ReaderAction.previousPage,
        ReaderAction.toggleOverlays,
        ReaderAction.toggleOverlays,
        ReaderAction.toggleOverlays,
        ReaderAction.nextPage,
        ReaderAction.nextPage,
        ReaderAction.nextPage,
      ],
    },
  );

  ReaderAction? actionForKey(KeyChord pressed) {
    for (final entry in keys.entries) {
      if (entry.value.contains(pressed)) return entry.key;
    }
    return null;
  }

  ReaderAction? actionForTap(TapLayout layout, double x, double y) {
    int band(double v) => v < 0.3 ? 0 : (v > 0.7 ? 2 : 1);
    return tapZones[layout]![band(y) * 3 + band(x)];
  }

  /// Chord on action, removing it from any other action so a key never does two things.
  ReaderControls withKey(ReaderAction action, KeyChord chord) {
    final next = {
      for (final entry in keys.entries)
        entry.key: [
          for (final existing in entry.value)
            if (existing != chord) existing,
        ],
    };
    next[action] = [...next[action]!, chord];
    return ReaderControls(keys: next, tapZones: tapZones, scroll: scroll);
  }

  ReaderControls withoutKey(ReaderAction action, KeyChord chord) {
    final next = {
      for (final entry in keys.entries)
        entry.key: [
          for (final existing in entry.value)
            if (entry.key != action || existing != chord) existing,
        ],
    };
    return ReaderControls(keys: next, tapZones: tapZones, scroll: scroll);
  }

  ReaderControls withKeysReset(ReaderAction action) {
    final next = {...keys};
    final taken = {
      for (final entry in keys.entries)
        if (entry.key != action) ...entry.value,
    };
    next[action] = [
      for (final chord in defaults.keys[action]!)
        if (!taken.contains(chord)) chord,
    ];
    return ReaderControls(keys: next, tapZones: tapZones, scroll: scroll);
  }

  ReaderControls withTapZone(TapLayout layout, int zone, ReaderAction? action) {
    final list = [...tapZones[layout]!];
    list[zone] = action;
    return ReaderControls(
      keys: keys,
      tapZones: {...tapZones, layout: list},
      scroll: scroll,
    );
  }

  ReaderControls withTapLayoutReset(TapLayout layout) => ReaderControls(
    keys: keys,
    tapZones: {...tapZones, layout: defaults.tapZones[layout]!},
    scroll: scroll,
  );

  ReaderControls withKeysAllReset() =>
      ReaderControls(keys: defaults.keys, tapZones: tapZones, scroll: scroll);

  ReaderControls withScroll(ScrollSteps steps) =>
      ReaderControls(keys: keys, tapZones: tapZones, scroll: steps);

  bool get isDefault => toJsonString() == defaults.toJsonString();

  Map<String, Object?> toJson() => {
    'format': 1,
    'keys': {
      for (final entry in keys.entries)
        entry.key.name: [for (final chord in entry.value) chord.toJson()],
    },
    'tapZones': {
      for (final entry in tapZones.entries)
        entry.key.name: [for (final action in entry.value) action?.name],
    },
    'scroll': scroll.toJson(),
  };

  String toJsonString() => jsonEncode(toJson());

  static ReaderControls fromJsonString(String? raw) {
    if (raw == null || raw.trim().isEmpty) return defaults;
    try {
      final decoded = jsonDecode(raw);
      return decoded is Map ? fromJson(decoded) : defaults;
    } on FormatException {
      return defaults;
    }
  }

  static ReaderControls fromJson(Map<dynamic, dynamic> json) {
    final keys = {...defaults.keys};
    final rawKeys = json['keys'];
    if (rawKeys is Map) {
      final claimed = <KeyChord>{};
      for (final action in ReaderAction.values) {
        final list = rawKeys[action.name];
        if (list is! List) continue;
        final chords = <KeyChord>[];
        for (final item in list) {
          final chord = KeyChord.fromJson(item);
          if (chord != null && claimed.add(chord)) chords.add(chord);
        }
        keys[action] = chords;
      }
    }

    final zones = {...defaults.tapZones};
    final rawZones = json['tapZones'];
    if (rawZones is Map) {
      for (final layout in TapLayout.values) {
        final list = rawZones[layout.name];
        if (list is! List || list.length != zoneCount) continue;
        zones[layout] = [
          for (final item in list)
            ReaderAction.values.where((a) => a.name == item).firstOrNull,
        ];
      }
    }
    return ReaderControls(
      keys: keys,
      tapZones: zones,
      scroll: ScrollSteps.fromJson(json['scroll']),
    );
  }
}
