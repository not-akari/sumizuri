import 'dart:ui' show Color;

import 'package:sumizuri/core/theming/font_catalog.dart' show removedFonts;
import 'package:sumizuri/core/theming/custom_theme.dart';

enum LayoutDensity { compact, comfortable, spacious }

enum GradientStyle { linear, radial }

/// How the bar that shows how far a title has been read is drawn.
enum ProgressStyle {
  /// A plain filled line.
  line,

  /// A dark track with a glowing head that fades out behind it.
  glow,

  /// A filled bar with slanting stripes.
  striped,

  /// A row of separate steps.
  segments,
}

/// Where the progress bar sits on a title's cover.
enum ProgressPlacement { onCover, belowCover }

enum ProgressColorMode { accent, gradient, custom }

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
  const ThemeComponents({
    this.listChevron = true,
    this.listIconTiles = true,
    this.cardOpacity = 1,
    this.cardBorders = true,
  });

  final bool listChevron;
  final bool listIconTiles;

  /// How solid the cards are, as a multiple of each card's usual fill. Below
  /// 1 they let the background through; above 1 they are denser.
  final double cardOpacity;

  /// Whether cards have a thin outline.
  final bool cardBorders;

  ThemeComponents copyWith({
    bool? listChevron,
    bool? listIconTiles,
    double? cardOpacity,
    bool? cardBorders,
  }) => ThemeComponents(
    listChevron: listChevron ?? this.listChevron,
    listIconTiles: listIconTiles ?? this.listIconTiles,
    cardOpacity: cardOpacity ?? this.cardOpacity,
    cardBorders: cardBorders ?? this.cardBorders,
  );

  Map<String, Object?> toJson() => {
    'listChevron': listChevron,
    'listIconTiles': listIconTiles,
    'cardOpacity': cardOpacity,
    'cardBorders': cardBorders,
  };

  factory ThemeComponents.fromJson(Object? json) {
    final m = _obj(json, 'components');
    const d = ThemeComponents();
    return ThemeComponents(
      listChevron: _bool(m, 'components', 'listChevron', d.listChevron),
      listIconTiles: _bool(m, 'components', 'listIconTiles', d.listIconTiles),
      cardOpacity: _num(
        m,
        'components',
        'cardOpacity',
        d.cardOpacity,
        0.3,
        1.5,
      ),
      cardBorders: _bool(m, 'components', 'cardBorders', d.cardBorders),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeComponents &&
      other.listChevron == listChevron &&
      other.listIconTiles == listIconTiles &&
      other.cardOpacity == cardOpacity &&
      other.cardBorders == cardBorders;

  @override
  int get hashCode =>
      Object.hash(listChevron, listIconTiles, cardOpacity, cardBorders);
}

/// The look of the bar that shows how far a title has been read. Whether it is
/// shown at all is the person's own choice; how it looks belongs to the theme.
class ThemeProgress {
  const ThemeProgress({
    this.style = ProgressStyle.line,
    this.placement = ProgressPlacement.onCover,
    this.colorMode = ProgressColorMode.accent,
    this.customColor = 0xFFFF7043,
    this.thickness = 4,
    this.rounded = true,
    this.trackOpacity = 0.35,
    this.glow = 0.6,
    this.animate = false,
    this.showPercent = false,
    this.hideEmpty = true,
    this.hideComplete = false,
  });

  final ProgressStyle style;
  final ProgressPlacement placement;
  final ProgressColorMode colorMode;

  /// The colour used when [colorMode] is custom, as an ARGB value.
  final int customColor;

  /// How tall the bar is, in logical pixels.
  final double thickness;

  /// Round ends, or square.
  final bool rounded;

  /// How visible the empty part of the bar is, 0 for none.
  final double trackOpacity;

  /// How far the glow reaches, for the glow style.
  final double glow;

  /// Whether the stripes of the striped style move.
  final bool animate;

  /// Whether a list row also says the percentage.
  final bool showPercent;

  /// No bar for a title nothing was read of.
  final bool hideEmpty;

  /// No bar for a title that is read to the end.
  final bool hideComplete;

  static const thicknessRange = (min: 2.0, max: 14.0);

  ThemeProgress copyWith({
    ProgressStyle? style,
    ProgressPlacement? placement,
    ProgressColorMode? colorMode,
    int? customColor,
    double? thickness,
    bool? rounded,
    double? trackOpacity,
    double? glow,
    bool? animate,
    bool? showPercent,
    bool? hideEmpty,
    bool? hideComplete,
  }) => ThemeProgress(
    style: style ?? this.style,
    placement: placement ?? this.placement,
    colorMode: colorMode ?? this.colorMode,
    customColor: customColor ?? this.customColor,
    thickness: thickness ?? this.thickness,
    rounded: rounded ?? this.rounded,
    trackOpacity: trackOpacity ?? this.trackOpacity,
    glow: glow ?? this.glow,
    animate: animate ?? this.animate,
    showPercent: showPercent ?? this.showPercent,
    hideEmpty: hideEmpty ?? this.hideEmpty,
    hideComplete: hideComplete ?? this.hideComplete,
  );

  Map<String, Object?> toJson() => {
    'style': style.name,
    'placement': placement.name,
    'colorMode': colorMode.name,
    'customColor': customColor,
    'thickness': thickness,
    'rounded': rounded,
    'trackOpacity': trackOpacity,
    'glow': glow,
    'animate': animate,
    'showPercent': showPercent,
    'hideEmpty': hideEmpty,
    'hideComplete': hideComplete,
  };

  factory ThemeProgress.fromJson(Object? json) {
    final m = _obj(json, 'progress');
    const d = ThemeProgress();
    return ThemeProgress(
      style: _enum(m, 'progress', 'style', ProgressStyle.values, d.style),
      placement: _enum(
        m,
        'progress',
        'placement',
        ProgressPlacement.values,
        d.placement,
      ),
      colorMode: _enum(
        m,
        'progress',
        'colorMode',
        ProgressColorMode.values,
        d.colorMode,
      ),
      customColor: _num(
        m,
        'progress',
        'customColor',
        d.customColor.toDouble(),
        0,
        4294967295,
      ).toInt(),
      thickness: _num(
        m,
        'progress',
        'thickness',
        d.thickness,
        thicknessRange.min,
        thicknessRange.max,
      ),
      rounded: _bool(m, 'progress', 'rounded', d.rounded),
      trackOpacity: _num(m, 'progress', 'trackOpacity', d.trackOpacity, 0, 1),
      glow: _num(m, 'progress', 'glow', d.glow, 0, 1),
      animate: _bool(m, 'progress', 'animate', d.animate),
      showPercent: _bool(m, 'progress', 'showPercent', d.showPercent),
      hideEmpty: _bool(m, 'progress', 'hideEmpty', d.hideEmpty),
      hideComplete: _bool(m, 'progress', 'hideComplete', d.hideComplete),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeProgress &&
      other.style == style &&
      other.placement == placement &&
      other.colorMode == colorMode &&
      other.customColor == customColor &&
      other.thickness == thickness &&
      other.rounded == rounded &&
      other.trackOpacity == trackOpacity &&
      other.glow == glow &&
      other.animate == animate &&
      other.showPercent == showPercent &&
      other.hideEmpty == hideEmpty &&
      other.hideComplete == hideComplete;

  @override
  int get hashCode => Object.hash(
    style,
    placement,
    colorMode,
    customColor,
    thickness,
    rounded,
    trackOpacity,
    glow,
    animate,
    showPercent,
    hideEmpty,
    hideComplete,
  );
}

/// What is painted behind the app: an optional gradient over the soft colour washes.
class ThemeBackground {
  const ThemeBackground({
    this.gradient = false,
    this.gradientStyle = GradientStyle.linear,
    this.gradientAngle = 135,
    this.gradientColors = const [null, null, null],
    this.gradientStrength = 0.4,
  });

  final bool gradient;
  final GradientStyle gradientStyle;

  /// Degrees. For a linear gradient, the direction it runs: 0 is left to
  /// right and 90 is top to bottom. For a radial one, where its centre sits
  /// around the middle of the window.
  final double gradientAngle;

  /// Up to three colours. An empty slot is filled from the theme: the first
  /// two follow its primary and tertiary colours, and an empty third is left out.
  final List<Color?> gradientColors;

  /// How opaque the gradient is over the background, 0 to 1.
  final double gradientStrength;

  /// The colours to paint with, empty slots filled from [primary] and [tertiary].
  List<Color> resolve({required Color primary, required Color tertiary}) => [
    gradientColors[0] ?? primary,
    gradientColors[1] ?? tertiary,
    ?gradientColors[2],
  ];

  ThemeBackground copyWith({
    bool? gradient,
    GradientStyle? gradientStyle,
    double? gradientAngle,
    List<Color?>? gradientColors,
    double? gradientStrength,
  }) => ThemeBackground(
    gradient: gradient ?? this.gradient,
    gradientStyle: gradientStyle ?? this.gradientStyle,
    gradientAngle: gradientAngle ?? this.gradientAngle,
    gradientColors: gradientColors ?? this.gradientColors,
    gradientStrength: gradientStrength ?? this.gradientStrength,
  );

  /// One slot changed, the others kept.
  ThemeBackground withColor(int slot, Color? color) => copyWith(
    gradientColors: [
      for (var i = 0; i < 3; i++) i == slot ? color : gradientColors[i],
    ],
  );

  Map<String, Object?> toJson() => {
    'gradient': gradient,
    'gradientStyle': gradientStyle.name,
    'gradientAngle': gradientAngle,
    'gradientColors': [
      for (final c in gradientColors) c == null ? null : colorToHex(c),
    ],
    'gradientStrength': gradientStrength,
  };

  factory ThemeBackground.fromJson(Object? json) {
    final m = _obj(json, 'background');
    const d = ThemeBackground();
    final raw = m['gradientColors'];
    var colors = d.gradientColors;
    if (raw != null) {
      if (raw is! List || raw.length > 3) {
        throw const ThemeFormatException(
          '"background.gradientColors" must be a list of up to 3 colors',
        );
      }
      colors = [
        for (var i = 0; i < 3; i++)
          i < raw.length && raw[i] != null
              ? (raw[i] is String ? parseHexColor(raw[i] as String) : null) ??
                    (throw ThemeFormatException(
                      '"background.gradientColors[$i]" is not a valid color',
                    ))
              : null,
      ];
    }
    return ThemeBackground(
      gradient: _bool(m, 'background', 'gradient', d.gradient),
      gradientStyle: _enum(
        m,
        'background',
        'gradientStyle',
        GradientStyle.values,
        d.gradientStyle,
      ),
      gradientAngle: _num(
        m,
        'background',
        'gradientAngle',
        d.gradientAngle,
        0,
        360,
      ),
      gradientColors: colors,
      gradientStrength: _num(
        m,
        'background',
        'gradientStrength',
        d.gradientStrength,
        0.05,
        1,
      ),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeBackground &&
      other.gradient == gradient &&
      other.gradientStyle == gradientStyle &&
      other.gradientAngle == gradientAngle &&
      other.gradientStrength == gradientStrength &&
      _sameColors(other.gradientColors, gradientColors);

  @override
  int get hashCode => Object.hash(
    gradient,
    gradientStyle,
    gradientAngle,
    gradientStrength,
    Object.hashAll(gradientColors),
  );

  static bool _sameColors(List<Color?> a, List<Color?> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}

class ThemeOptions {
  const ThemeOptions({
    this.typography = const ThemeTypography(),
    this.layout = const ThemeLayout(),
    this.effects = const ThemeEffects(),
    this.motion = const ThemeMotion(),
    this.components = const ThemeComponents(),
    this.background = const ThemeBackground(),
    this.progress = const ThemeProgress(),
  });

  final ThemeTypography typography;
  final ThemeLayout layout;
  final ThemeEffects effects;
  final ThemeMotion motion;
  final ThemeComponents components;
  final ThemeBackground background;
  final ThemeProgress progress;

  ThemeOptions copyWith({
    ThemeTypography? typography,
    ThemeLayout? layout,
    ThemeEffects? effects,
    ThemeMotion? motion,
    ThemeComponents? components,
    ThemeBackground? background,
    ThemeProgress? progress,
  }) => ThemeOptions(
    typography: typography ?? this.typography,
    layout: layout ?? this.layout,
    effects: effects ?? this.effects,
    motion: motion ?? this.motion,
    components: components ?? this.components,
    background: background ?? this.background,
    progress: progress ?? this.progress,
  );

  Map<String, Object?> toJson() => {
    'typography': typography.toJson(),
    'layout': layout.toJson(),
    'effects': effects.toJson(),
    'motion': motion.toJson(),
    'components': components.toJson(),
    'background': background.toJson(),
    'progress': progress.toJson(),
  };

  factory ThemeOptions.fromJson(Map json) => ThemeOptions(
    typography: ThemeTypography.fromJson(json['typography']),
    layout: ThemeLayout.fromJson(json['layout']),
    effects: ThemeEffects.fromJson(json['effects']),
    motion: ThemeMotion.fromJson(json['motion']),
    components: ThemeComponents.fromJson(json['components']),
    background: ThemeBackground.fromJson(json['background']),
    progress: ThemeProgress.fromJson(json['progress']),
  );

  @override
  bool operator ==(Object other) =>
      other is ThemeOptions &&
      other.typography == typography &&
      other.layout == layout &&
      other.effects == effects &&
      other.motion == motion &&
      other.components == components &&
      other.background == background &&
      other.progress == progress;

  @override
  int get hashCode => Object.hash(
    typography,
    layout,
    effects,
    motion,
    components,
    background,
    progress,
  );
}
