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

/// How wide the side bands of the tap grid are and how tall the top and
/// bottom ones are, as a fraction of the screen. What is left is the centre.
class TapGeometry {
  const TapGeometry({this.edgeX = 0.3, this.edgeY = 0.3});

  final double edgeX;
  final double edgeY;

  static const range = (min: 0.15, max: 0.45);

  TapGeometry copyWith({double? edgeX, double? edgeY}) =>
      TapGeometry(edgeX: edgeX ?? this.edgeX, edgeY: edgeY ?? this.edgeY);

  @override
  bool operator ==(Object other) =>
      other is TapGeometry && other.edgeX == edgeX && other.edgeY == edgeY;

  @override
  int get hashCode => Object.hash(edgeX, edgeY);

  Map<String, Object?> toJson() => {'x': edgeX, 'y': edgeY};

  static TapGeometry fromJson(Object? raw) {
    if (raw is! Map) return const TapGeometry();
    double read(String key) {
      final v = raw[key];
      return v is num
          ? v.toDouble().clamp(range.min, range.max)
          : const TapGeometry().edgeX;
    }

    return TapGeometry(edgeX: read('x'), edgeY: read('y'));
  }
}

/// Ready-made tap layouts, so a good arrangement is one tap away.
enum TapPreset {
  /// Sides turn the page, the middle shows the controls.
  standard,

  /// Only the left and right strips turn the page.
  edges,

  /// Back on the left and top, forward on the right and bottom.
  lShaped,

  /// A big middle, so a stray tap rarely turns the page.
  wideCenter,

  /// Nothing turns the page; swipes and keys do, the middle shows the controls.
  menuOnly,
}

class ReaderControls {
  const ReaderControls({
    required this.keys,
    required this.tapZones,
    this.scroll = const ScrollSteps(),
    this.geometry = const {},
  });

  final Map<ReaderAction, List<KeyChord>> keys;

  final Map<TapLayout, List<ReaderAction?>> tapZones;

  final ScrollSteps scroll;

  /// The size of the tap bands, per layout. A layout with none has the usual.
  final Map<TapLayout, TapGeometry> geometry;

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

  TapGeometry geometryOf(TapLayout layout) =>
      geometry[layout] ?? const TapGeometry();

  ReaderAction? actionForKey(KeyChord pressed) {
    for (final entry in keys.entries) {
      if (entry.value.contains(pressed)) return entry.key;
    }
    return null;
  }

  /// The action of the zone under a tap at [x], [y] (both 0 to 1).
  ReaderAction? actionForTap(TapLayout layout, double x, double y) {
    final g = geometryOf(layout);
    int band(double v, double edge) => v < edge ? 0 : (v > 1 - edge ? 2 : 1);
    return tapZones[layout]![band(y, g.edgeY) * 3 + band(x, g.edgeX)];
  }

  ReaderControls _copy({
    Map<ReaderAction, List<KeyChord>>? keys,
    Map<TapLayout, List<ReaderAction?>>? tapZones,
    ScrollSteps? scroll,
    Map<TapLayout, TapGeometry>? geometry,
  }) => ReaderControls(
    keys: keys ?? this.keys,
    tapZones: tapZones ?? this.tapZones,
    scroll: scroll ?? this.scroll,
    geometry: geometry ?? this.geometry,
  );

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
    return _copy(keys: next);
  }

  ReaderControls withoutKey(ReaderAction action, KeyChord chord) {
    final next = {
      for (final entry in keys.entries)
        entry.key: [
          for (final existing in entry.value)
            if (entry.key != action || existing != chord) existing,
        ],
    };
    return _copy(keys: next);
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
    return _copy(keys: next);
  }

  ReaderControls withTapZone(TapLayout layout, int zone, ReaderAction? action) {
    final list = [...tapZones[layout]!];
    list[zone] = action;
    return _copy(tapZones: {...tapZones, layout: list});
  }

  /// The zones and the band sizes of [layout] back to the usual.
  ReaderControls withTapLayoutReset(TapLayout layout) => _copy(
    tapZones: {...tapZones, layout: defaults.tapZones[layout]!},
    geometry: {...geometry}..remove(layout),
  );

  /// The left and right of [layout] swapped, for the other hand. A zone that
  /// turns to the left is then on the right, and the other way round.
  ReaderControls withTapMirrored(TapLayout layout) {
    final zones = tapZones[layout]!;
    return _copy(
      tapZones: {
        ...tapZones,
        layout: [
          for (var row = 0; row < 3; row++)
            for (var col = 0; col < 3; col++) zones[row * 3 + (2 - col)],
        ],
      },
    );
  }

  /// The size of the tap bands of [layout].
  ReaderControls withGeometry(TapLayout layout, TapGeometry value) =>
      _copy(geometry: {...geometry, layout: value});

  /// [layout] laid out as [preset] says.
  ReaderControls withPreset(TapLayout layout, TapPreset preset) {
    const p = ReaderAction.previousPage;
    const n = ReaderAction.nextPage;
    const o = ReaderAction.toggleOverlays;
    final paged = layout == TapLayout.paged;
    final zones = switch (preset) {
      TapPreset.standard || TapPreset.wideCenter => defaults.tapZones[layout]!,
      TapPreset.edges =>
        paged
            ? const [
                ReaderAction.pageLeft,
                o,
                ReaderAction.pageRight,
                ReaderAction.pageLeft,
                o,
                ReaderAction.pageRight,
                ReaderAction.pageLeft,
                o,
                ReaderAction.pageRight,
              ]
            : const [p, o, p, null, o, null, n, o, n],
      TapPreset.lShaped => const [p, p, p, p, o, n, n, n, n],
      TapPreset.menuOnly => const [
        null,
        null,
        null,
        null,
        o,
        null,
        null,
        null,
        null,
      ],
    };
    final geo = preset == TapPreset.wideCenter
        ? const TapGeometry(edgeX: 0.2, edgeY: 0.2)
        : const TapGeometry();
    return _copy(
      tapZones: {...tapZones, layout: zones},
      geometry: {...geometry, layout: geo},
    );
  }

  ReaderControls withKeysAllReset() => _copy(keys: defaults.keys);

  ReaderControls withScroll(ScrollSteps steps) => _copy(scroll: steps);

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
    // Only what was changed, so a file from before this still reads the same.
    if (geometry.values.any((g) => g != const TapGeometry()))
      'geometry': {
        for (final entry in geometry.entries)
          if (entry.value != const TapGeometry())
            entry.key.name: entry.value.toJson(),
      },
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

    final geometry = <TapLayout, TapGeometry>{};
    final rawGeometry = json['geometry'];
    if (rawGeometry is Map) {
      for (final layout in TapLayout.values) {
        final value = rawGeometry[layout.name];
        if (value != null) geometry[layout] = TapGeometry.fromJson(value);
      }
    }
    return ReaderControls(
      keys: keys,
      tapZones: zones,
      scroll: ScrollSteps.fromJson(json['scroll']),
      geometry: geometry,
    );
  }
}
