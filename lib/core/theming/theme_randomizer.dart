import 'dart:math';

import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/theming/font_catalog.dart';
import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';

/// The parts of a look that can be shuffled on their own.
enum RandomizeAspect {
  /// The colour palette, for both light and dark.
  colors,

  /// How rounded the corners are, and the border weight.
  shapes,

  /// The title and body typefaces.
  fonts,

  /// Density and how much room there is between things.
  spacing,

  /// Hand-drawn lines and cover shadows.
  effects,

  /// Icon tiles, arrows, and how solid the cards are.
  components,

  /// The background glow, its tint, and a gradient over it.
  background,
}

/// A random gradient for the background, as the settings store it.
class RandomGradient {
  const RandomGradient({
    required this.style,
    required this.angle,
    required this.colors,
    required this.strength,
  });

  final GradientStyle style;
  final int angle;
  final List<Color?> colors;

  /// Percent.
  final int strength;
}

const _adjectives = [
  'Quiet',
  'Mellow',
  'Bright',
  'Velvet',
  'Hazy',
  'Crisp',
  'Gentle',
  'Bold',
  'Dusky',
  'Lucid',
  'Soft',
  'Wild',
];

const _nouns = [
  'Lantern',
  'Harbor',
  'Maple',
  'Ember',
  'Tide',
  'Orchid',
  'Meadow',
  'Comet',
  'Willow',
  'Lotus',
  'Cinder',
  'Breeze',
];

/// Shuffles chosen parts of a theme and leaves the rest as they were.
///
/// Pass a seeded [Random] to get the same result twice.
class ThemeRandomizer {
  ThemeRandomizer([Random? random]) : _random = random ?? Random();

  final Random _random;

  double _between(double low, double high) =>
      low + _random.nextDouble() * (high - low);

  T _pick<T>(List<T> items) => items[_random.nextInt(items.length)];

  bool _chance(double probability) => _random.nextDouble() < probability;

  /// A name for a theme that was made by chance, such as "Mellow Lantern".
  String randomName() => '${_pick(_adjectives)} ${_pick(_nouns)}';

  /// [base] with each of [aspects] shuffled.
  CustomTheme apply(CustomTheme base, Set<RandomizeAspect> aspects) {
    var theme = base;
    if (aspects.contains(RandomizeAspect.colors)) {
      final palette = _palette();
      theme = theme.copyWith(light: palette.$1, dark: palette.$2);
    }
    // The gradient goes with the palette when there is a new one.
    final palette = theme.dark;
    if (aspects.contains(RandomizeAspect.shapes)) {
      theme = theme.copyWith(shapes: _shapes(theme.shapes));
    }
    var options = theme.options;
    if (aspects.contains(RandomizeAspect.fonts)) {
      options = options.copyWith(typography: _typography(options.typography));
    }
    if (aspects.contains(RandomizeAspect.spacing)) {
      options = options.copyWith(
        layout: ThemeLayout(
          density: _pick(LayoutDensity.values),
          spacing: double.parse(_between(0.9, 1.15).toStringAsFixed(2)),
        ),
      );
    }
    if (aspects.contains(RandomizeAspect.effects)) {
      options = options.copyWith(effects: _effects(options.effects));
    }
    if (aspects.contains(RandomizeAspect.components)) {
      options = options.copyWith(
        components: ThemeComponents(
          listChevron: _chance(0.7),
          listIconTiles: _chance(0.75),
          cardOpacity: double.parse(_between(0.6, 1.25).toStringAsFixed(2)),
          cardBorders: _chance(0.8),
        ),
      );
    }
    if (aspects.contains(RandomizeAspect.background)) {
      options = options.copyWith(
        effects: options.effects.copyWith(
          bloom: double.parse(_between(0.4, 1.6).toStringAsFixed(2)),
          backgroundTint: _chance(0.5)
              ? double.parse(_between(4, 28).toStringAsFixed(0))
              : null,
          clearTint: _chance(0.5),
        ),
        background: _background(palette),
      );
    }
    return theme.copyWith(options: options);
  }

  // ---- colours ----

  Color _hsl(double hue, double saturation, double lightness) =>
      HSLColor.fromAHSL(
        1,
        hue % 360,
        saturation.clamp(0.0, 1.0),
        lightness.clamp(0.0, 1.0),
      ).toColor();

  /// A palette built around one hue and two more that go with it, for light and dark.
  (ThemeColors, ThemeColors) _palette() {
    final hue = _random.nextDouble() * 360;
    // How far the other two hues sit from the first: close, opposite or a third apart.
    final (second, third) = switch (_random.nextInt(4)) {
      0 => (hue + 30, hue - 30),
      1 => (hue + 180, hue + 150),
      2 => (hue + 120, hue + 240),
      _ => (hue + 150, hue + 210),
    };
    final saturation = _between(0.45, 0.8);

    final dark = ThemeColors(
      primary: _hsl(hue, saturation, 0.66),
      primaryContainer: _hsl(hue, saturation * 0.6, 0.3),
      secondary: _hsl(second, saturation * 0.7, 0.64),
      tertiary: _hsl(third, saturation * 0.75, 0.68),
      surface: _hsl(hue, _between(0.18, 0.35), _between(0.06, 0.1)),
    );
    final light = ThemeColors(
      primary: _hsl(hue, saturation, 0.4),
      primaryContainer: _hsl(hue, saturation * 0.7, 0.86),
      secondary: _hsl(second, saturation * 0.6, 0.42),
      tertiary: _hsl(third, saturation * 0.65, 0.4),
      surface: _hsl(hue, _between(0.3, 0.5), _between(0.94, 0.97)),
    );
    return (light, dark);
  }

  // ---- shapes ----

  ThemeShapes _shapes(ThemeShapes current) {
    // One character for the whole theme, so the corners agree with each other.
    final character = _pick(['sharp', 'soft', 'round', 'leaf']);
    double size(double low, double high) =>
        double.parse(_between(low, high).toStringAsFixed(0));

    ShapeSpec spec(double scale) => switch (character) {
      'sharp' => ShapeSpec(ShapeStyle.uniform, size(2, 5) * scale),
      'soft' => ShapeSpec(ShapeStyle.uniform, size(10, 16) * scale),
      'round' => ShapeSpec(ShapeStyle.uniform, size(20, 28) * scale),
      _ => ShapeSpec(ShapeStyle.asymmetric, size(16, 26) * scale, size(2, 6)),
    };

    var shapes = current
        .withSpec('card', spec(1))
        .withSpec('item', spec(0.85))
        .withSpec('cover', spec(0.7))
        .withSpec('iconTile', ShapeSpec(ShapeStyle.uniform, size(6, 14)))
        .withSpec('dialog', spec(1.2))
        .withSpec('button', spec(0.8))
        .withSpec('chip', spec(0.8));
    // Round themes sometimes take pill buttons and chips.
    if (character == 'round' && _chance(0.6)) {
      shapes = shapes
          .withSpec('button', const ShapeSpec(ShapeStyle.pill, 0))
          .withSpec('chip', const ShapeSpec(ShapeStyle.pill, 0));
    }
    shapes = shapes
        .withSpec(
          'navBar',
          character == 'sharp'
              ? ShapeSpec(ShapeStyle.uniform, size(2, 6))
              : const ShapeSpec(ShapeStyle.pill, 0),
        )
        .withSpec('navIndicator', spec(0.7));
    final sheet = switch (character) {
      'sharp' => size(6, 10),
      'soft' => size(16, 22),
      'round' => size(26, 32),
      _ => size(20, 28),
    };
    return shapes.copyWith(
      sheetRadius: sheet,
      borderWidth: _pick([0.5, 1.0, 1.0, 1.5, 2.0]),
    );
  }

  // ---- fonts ----

  static const _titleFonts = [
    '',
    'google:Lora',
    'google:Merriweather',
    'google:Playfair Display',
    'google:Shippori Mincho',
    'google:Zen Antique',
    'google:Caveat',
    'google:Zen Kurenaido',
    'google:Poppins',
  ];

  static const _bodyFonts = [
    '',
    'google:Inter',
    'google:Nunito',
    'google:Work Sans',
    'google:Poppins',
    'google:Quicksand',
  ];

  ThemeTypography _typography(ThemeTypography current) {
    // Only fonts the app already offers, so nothing has to be downloaded that the picker would not show.
    final known = {for (final f in googleFontChoices) f.value};
    String pickFrom(List<String> options) {
      final usable = [
        for (final o in options)
          if (o.isEmpty || known.contains(o)) o,
      ];
      return _pick(usable);
    }

    return current.copyWith(
      displayFont: pickFrom(_titleFonts),
      bodyFont: pickFrom(_bodyFonts),
    );
  }

  // ---- effects ----

  ThemeEffects _effects(ThemeEffects current) =>
      current.copyWith(brushStrokes: _chance(0.6), coverShadow: _chance(0.4));

  ThemeBackground _background(ThemeColors from) {
    final g = gradient(from: from);
    return ThemeBackground(
      gradient: _chance(0.7),
      gradientStyle: g.style,
      gradientAngle: g.angle.toDouble(),
      gradientColors: g.colors,
      gradientStrength: g.strength / 100,
    );
  }

  // ---- gradient ----

  /// A gradient for the background. When [from] is given its primary and
  /// tertiary colours (usually the palette just made) are what it is built
  /// from, so it goes with the theme; otherwise it picks its own hues.
  RandomGradient gradient({ThemeColors? from}) {
    final hue = _random.nextDouble() * 360;
    final Color first =
        from?.primary ?? _hsl(hue, _between(0.5, 0.8), _between(0.35, 0.5));
    final Color second =
        from?.tertiary ??
        _hsl(
          hue + _pick([40, 150, 180]),
          _between(0.5, 0.8),
          _between(0.3, 0.5),
        );
    final radial = _chance(0.3);
    return RandomGradient(
      style: radial ? GradientStyle.radial : GradientStyle.linear,
      angle: _random.nextInt(360),
      colors: [
        first,
        second,
        _chance(0.3)
            ? _hsl(hue + 90, _between(0.4, 0.7), _between(0.1, 0.25))
            : null,
      ],
      strength: 40 + _random.nextInt(36),
    );
  }
}
