import 'package:sumizuri/core/theming/font_catalog.dart' show removedFonts;
import 'package:sumizuri/core/theming/custom_theme.dart';

enum LayoutDensity { compact, comfortable, spacious }

double _num(
  Map json,
  String path,
  String key,
  double fallback,
  double min,
  double max,
) {
  final raw = json[key];
  if (raw == null) return fallback;
  if (raw is! num) throw ThemeFormatException('"$path.$key" must be a number');
  return raw.toDouble().clamp(min, max).toDouble();
}

bool _bool(Map json, String path, String key, bool fallback) {
  final raw = json[key];
  if (raw == null) return fallback;
  if (raw is! bool) {
    throw ThemeFormatException('"$path.$key" must be true or false');
  }
  return raw;
}

T _enum<T extends Enum>(
  Map json,
  String path,
  String key,
  List<T> values,
  T fallback,
) {
  final raw = json[key];
  if (raw == null) return fallback;
  for (final v in values) {
    if (v.name == raw) return v;
  }
  final names = values.map((v) => v.name).join(', ');
  throw ThemeFormatException('"$path.$key" must be one of: $names');
}

/// Font family names come from a file, so they are trimmed and length-limited.
String _fontName(Map json, String path, String key, String fallback) {
  final raw = json[key];
  if (raw == null) return fallback;
  if (raw is! String) throw ThemeFormatException('"$path.$key" must be text');
  return raw.trim().length > 64 ? raw.trim().substring(0, 64) : raw.trim();
}

Map _obj(Object? json, String path) {
  if (json == null) return const {};
  if (json is! Map) throw ThemeFormatException('"$path" must be an object');
  return json;
}

class ThemeTypography {
  const ThemeTypography({
    this.displayFont = '',
    this.bodyFont = '',
    this.textScale = 1,
  });

  final String displayFont;

  final String bodyFont;
  final double textScale;

  ThemeTypography copyWith({
    String? displayFont,
    String? bodyFont,
    double? textScale,
  }) => ThemeTypography(
    displayFont: displayFont ?? this.displayFont,
    bodyFont: bodyFont ?? this.bodyFont,
    textScale: textScale ?? this.textScale,
  );

  Map<String, Object?> toJson() => {
    'displayFont': displayFont,
    'bodyFont': bodyFont,
    'textScale': textScale,
  };

  factory ThemeTypography.fromJson(Object? json) {
    final m = _obj(json, 'typography');
    const d = ThemeTypography();
    // A font that is no longer bundled (or an older "serif" / "sans") reads as the default.
    String kept(String font) => removedFonts.contains(font) ? '' : font;
    return ThemeTypography(
      displayFont: kept(
        _fontName(m, 'typography', 'displayFont', d.displayFont),
      ),
      bodyFont: kept(_fontName(m, 'typography', 'bodyFont', d.bodyFont)),
      textScale: _num(m, 'typography', 'textScale', d.textScale, 0.8, 1.4),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeTypography &&
      other.displayFont == displayFont &&
      other.bodyFont == bodyFont &&
      other.textScale == textScale;

  @override
  int get hashCode => Object.hash(displayFont, bodyFont, textScale);
}

class ThemeLayout {
  const ThemeLayout({
    this.density = LayoutDensity.comfortable,
    this.spacing = 1,
  });

  final LayoutDensity density;

  final double spacing;

  ThemeLayout copyWith({LayoutDensity? density, double? spacing}) =>
      ThemeLayout(
        density: density ?? this.density,
        spacing: spacing ?? this.spacing,
      );

  Map<String, Object?> toJson() => {
    'density': density.name,
    'spacing': spacing,
  };

  factory ThemeLayout.fromJson(Object? json) {
    final m = _obj(json, 'layout');
    const d = ThemeLayout();
    return ThemeLayout(
      density: _enum(m, 'layout', 'density', LayoutDensity.values, d.density),
      spacing: _num(m, 'layout', 'spacing', d.spacing, 0.6, 1.6),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeLayout &&
      other.density == density &&
      other.spacing == spacing;

  @override
  int get hashCode => Object.hash(density, spacing);
}

class ThemeEffects {
  const ThemeEffects({
    this.bloom = 1,
    this.brushStrokes = true,
    this.coverShadow = false,
    this.backgroundTint,
    this.oledDark = false,
  });

  final double bloom;

  final bool brushStrokes;
  final bool coverShadow;

  final double? backgroundTint;

  final bool oledDark;

  ThemeEffects copyWith({
    double? bloom,
    bool? brushStrokes,
    bool? coverShadow,
    double? backgroundTint,
    bool clearTint = false,
    bool? oledDark,
  }) => ThemeEffects(
    bloom: bloom ?? this.bloom,
    brushStrokes: brushStrokes ?? this.brushStrokes,
    coverShadow: coverShadow ?? this.coverShadow,
    backgroundTint: clearTint ? null : (backgroundTint ?? this.backgroundTint),
    oledDark: oledDark ?? this.oledDark,
  );

  Map<String, Object?> toJson() => {
    'bloom': bloom,
    'brushStrokes': brushStrokes,
    'coverShadow': coverShadow,
    'backgroundTint': backgroundTint,
    'oledDark': oledDark,
  };

  factory ThemeEffects.fromJson(Object? json) {
    final m = _obj(json, 'effects');
    const d = ThemeEffects();
    return ThemeEffects(
      bloom: _num(m, 'effects', 'bloom', d.bloom, 0, 2),
      brushStrokes: _bool(m, 'effects', 'brushStrokes', d.brushStrokes),
      coverShadow: _bool(m, 'effects', 'coverShadow', d.coverShadow),
      backgroundTint: m['backgroundTint'] == null
          ? null
          : _num(m, 'effects', 'backgroundTint', 0, 0, 40),
      oledDark: _bool(m, 'effects', 'oledDark', d.oledDark),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeEffects &&
      other.bloom == bloom &&
      other.brushStrokes == brushStrokes &&
      other.coverShadow == coverShadow &&
      other.backgroundTint == backgroundTint &&
      other.oledDark == oledDark;

  @override
  int get hashCode =>
      Object.hash(bloom, brushStrokes, coverShadow, backgroundTint, oledDark);
}

class ThemeMotion {
  const ThemeMotion({
    this.hoverScale = 1.02,
    this.pressScale = 0.96,
    this.transitionSpeed = 1,
  });

  final double hoverScale;
  final double pressScale;

  final double transitionSpeed;

  ThemeMotion copyWith({
    double? hoverScale,
    double? pressScale,
    double? transitionSpeed,
  }) => ThemeMotion(
    hoverScale: hoverScale ?? this.hoverScale,
    pressScale: pressScale ?? this.pressScale,
    transitionSpeed: transitionSpeed ?? this.transitionSpeed,
  );

  Map<String, Object?> toJson() => {
    'hoverScale': hoverScale,
    'pressScale': pressScale,
    'transitionSpeed': transitionSpeed,
  };

  factory ThemeMotion.fromJson(Object? json) {
    final m = _obj(json, 'motion');
    const d = ThemeMotion();
    return ThemeMotion(
      hoverScale: _num(m, 'motion', 'hoverScale', d.hoverScale, 1, 1.12),
      pressScale: _num(m, 'motion', 'pressScale', d.pressScale, 0.8, 1),
      transitionSpeed: _num(
        m,
        'motion',
        'transitionSpeed',
        d.transitionSpeed,
        0.5,
        2,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeMotion &&
      other.hoverScale == hoverScale &&
      other.pressScale == pressScale &&
      other.transitionSpeed == transitionSpeed;

  @override
  int get hashCode => Object.hash(hoverScale, pressScale, transitionSpeed);
}

class ThemeComponents {
  const ThemeComponents({this.listChevron = true, this.listIconTiles = true});

  final bool listChevron;
  final bool listIconTiles;

  ThemeComponents copyWith({bool? listChevron, bool? listIconTiles}) =>
      ThemeComponents(
        listChevron: listChevron ?? this.listChevron,
        listIconTiles: listIconTiles ?? this.listIconTiles,
      );

  Map<String, Object?> toJson() => {
    'listChevron': listChevron,
    'listIconTiles': listIconTiles,
  };

  factory ThemeComponents.fromJson(Object? json) {
    final m = _obj(json, 'components');
    const d = ThemeComponents();
    return ThemeComponents(
      listChevron: _bool(m, 'components', 'listChevron', d.listChevron),
      listIconTiles: _bool(m, 'components', 'listIconTiles', d.listIconTiles),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeComponents &&
      other.listChevron == listChevron &&
      other.listIconTiles == listIconTiles;

  @override
  int get hashCode => Object.hash(listChevron, listIconTiles);
}

class ThemeOptions {
  const ThemeOptions({
    this.typography = const ThemeTypography(),
    this.layout = const ThemeLayout(),
    this.effects = const ThemeEffects(),
    this.motion = const ThemeMotion(),
    this.components = const ThemeComponents(),
  });

  final ThemeTypography typography;
  final ThemeLayout layout;
  final ThemeEffects effects;
  final ThemeMotion motion;
  final ThemeComponents components;

  ThemeOptions copyWith({
    ThemeTypography? typography,
    ThemeLayout? layout,
    ThemeEffects? effects,
    ThemeMotion? motion,
    ThemeComponents? components,
  }) => ThemeOptions(
    typography: typography ?? this.typography,
    layout: layout ?? this.layout,
    effects: effects ?? this.effects,
    motion: motion ?? this.motion,
    components: components ?? this.components,
  );

  Map<String, Object?> toJson() => {
    'typography': typography.toJson(),
    'layout': layout.toJson(),
    'effects': effects.toJson(),
    'motion': motion.toJson(),
    'components': components.toJson(),
  };

  factory ThemeOptions.fromJson(Map json) => ThemeOptions(
    typography: ThemeTypography.fromJson(json['typography']),
    layout: ThemeLayout.fromJson(json['layout']),
    effects: ThemeEffects.fromJson(json['effects']),
    motion: ThemeMotion.fromJson(json['motion']),
    components: ThemeComponents.fromJson(json['components']),
  );

  @override
  bool operator ==(Object other) =>
      other is ThemeOptions &&
      other.typography == typography &&
      other.layout == layout &&
      other.effects == effects &&
      other.motion == motion &&
      other.components == components;

  @override
  int get hashCode =>
      Object.hash(typography, layout, effects, motion, components);
}
