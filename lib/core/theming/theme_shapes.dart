import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/theming/font_catalog.dart';
import 'package:sumizuri/core/theming/theme_options.dart';

const _maxRadius = 40.0;
const _maxBorder = 4.0;

enum ShapeStyle { asymmetric, uniform, pill }

class ShapeSpec {
  const ShapeSpec(this.style, this.large, [this.small = 0]);

  final ShapeStyle style;
  final double large;
  final double small;

  BorderRadius get radius => switch (style) {
    ShapeStyle.asymmetric => BorderRadius.only(
      topLeft: Radius.circular(large),
      bottomRight: Radius.circular(large),
      topRight: Radius.circular(small),
      bottomLeft: Radius.circular(small),
    ),
    ShapeStyle.uniform => BorderRadius.circular(large),
    ShapeStyle.pill => BorderRadius.circular(999),
  };

  BorderRadius insetRadius(double by) {
    double d(double v) => (v - by).clamp(0, 999).toDouble();
    return switch (style) {
      ShapeStyle.asymmetric => BorderRadius.only(
        topLeft: Radius.circular(d(large)),
        bottomRight: Radius.circular(d(large)),
        topRight: Radius.circular(d(small)),
        bottomLeft: Radius.circular(d(small)),
      ),
      ShapeStyle.uniform => BorderRadius.circular(d(large)),
      ShapeStyle.pill => BorderRadius.circular(999),
    };
  }

  OutlinedBorder border({BorderSide side = BorderSide.none}) =>
      RoundedRectangleBorder(borderRadius: radius, side: side);

  ShapeSpec copyWith({ShapeStyle? style, double? large, double? small}) =>
      ShapeSpec(style ?? this.style, large ?? this.large, small ?? this.small);

  Map<String, Object?> toJson() => {
    'style': style.name,
    'large': large,
    if (style == ShapeStyle.asymmetric) 'small': small,
  };

  factory ShapeSpec.fromJson(Object? json, String path, ShapeSpec fallback) {
    if (json == null) return fallback;
    if (json is! Map) throw ThemeFormatException('"$path" must be an object');
    var style = fallback.style;
    final rawStyle = json['style'];
    if (rawStyle != null) {
      final match = ShapeStyle.values.where((s) => s.name == rawStyle);
      if (match.isEmpty) {
        throw ThemeFormatException(
          '"$path.style" must be asymmetric, uniform or pill',
        );
      }
      style = match.first;
    }
    double number(String key, double current) {
      final raw = json[key];
      if (raw == null) return current;
      if (raw is! num) {
        throw ThemeFormatException('"$path.$key" must be a number');
      }
      return raw.toDouble().clamp(0, _maxRadius).toDouble();
    }

    return ShapeSpec(
      style,
      number('large', fallback.large),
      number('small', fallback.small),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ShapeSpec &&
      other.style == style &&
      other.large == large &&
      other.small == small;

  @override
  int get hashCode => Object.hash(style, large, small);
}

class ThemeShapes {
  const ThemeShapes({
    this.card = const ShapeSpec(ShapeStyle.asymmetric, 14, 4),
    this.item = const ShapeSpec(ShapeStyle.asymmetric, 12, 4),
    this.cover = const ShapeSpec(ShapeStyle.asymmetric, 10, 3),
    this.button = const ShapeSpec(ShapeStyle.asymmetric, 10, 3),
    this.chip = const ShapeSpec(ShapeStyle.asymmetric, 10, 3),
    this.iconTile = const ShapeSpec(ShapeStyle.uniform, 10),
    this.dialog = const ShapeSpec(ShapeStyle.asymmetric, 20, 4),
    this.navBar = const ShapeSpec(ShapeStyle.pill, 0),
    this.navIndicator = const ShapeSpec(ShapeStyle.asymmetric, 16, 6),
    this.sheetRadius = 20,
    this.borderWidth = 1,
  });

  final ShapeSpec card;
  final ShapeSpec item;
  final ShapeSpec cover;
  final ShapeSpec button;
  final ShapeSpec chip;
  final ShapeSpec iconTile;
  final ShapeSpec dialog;
  final ShapeSpec navBar;
  final ShapeSpec navIndicator;
  final double sheetRadius;
  final double borderWidth;

  static const specKeys = [
    'card',
    'item',
    'cover',
    'button',
    'chip',
    'iconTile',
    'dialog',
    'navBar',
    'navIndicator',
  ];

  ShapeSpec spec(String key) => switch (key) {
    'card' => card,
    'item' => item,
    'cover' => cover,
    'button' => button,
    'chip' => chip,
    'iconTile' => iconTile,
    'navBar' => navBar,
    'navIndicator' => navIndicator,
    _ => dialog,
  };

  ThemeShapes withSpec(String key, ShapeSpec value) => ThemeShapes(
    card: key == 'card' ? value : card,
    item: key == 'item' ? value : item,
    cover: key == 'cover' ? value : cover,
    button: key == 'button' ? value : button,
    chip: key == 'chip' ? value : chip,
    iconTile: key == 'iconTile' ? value : iconTile,
    dialog: key == 'dialog' ? value : dialog,
    navBar: key == 'navBar' ? value : navBar,
    navIndicator: key == 'navIndicator' ? value : navIndicator,
    sheetRadius: sheetRadius,
    borderWidth: borderWidth,
  );

  ThemeShapes copyWith({double? sheetRadius, double? borderWidth}) =>
      ThemeShapes(
        card: card,
        item: item,
        cover: cover,
        button: button,
        chip: chip,
        iconTile: iconTile,
        dialog: dialog,
        navBar: navBar,
        navIndicator: navIndicator,
        sheetRadius: sheetRadius ?? this.sheetRadius,
        borderWidth: borderWidth ?? this.borderWidth,
      );

  Map<String, Object?> toJson() => {
    for (final key in specKeys) key: spec(key).toJson(),
    'sheetRadius': sheetRadius,
    'borderWidth': borderWidth,
  };

  factory ThemeShapes.fromJson(Object? json) {
    const defaults = ThemeShapes();
    if (json == null) return defaults;
    if (json is! Map) {
      throw const ThemeFormatException('"shape" must be an object');
    }
    var result = defaults;
    for (final key in specKeys) {
      result = result.withSpec(
        key,
        ShapeSpec.fromJson(json[key], 'shape.$key', defaults.spec(key)),
      );
    }
    double number(String key, double current, double max) {
      final raw = json[key];
      if (raw == null) return current;
      if (raw is! num) {
        throw ThemeFormatException('"shape.$key" must be a number');
      }
      return raw.toDouble().clamp(0, max).toDouble();
    }

    return result.copyWith(
      sheetRadius: number('sheetRadius', defaults.sheetRadius, _maxRadius),
      borderWidth: number('borderWidth', defaults.borderWidth, _maxBorder),
    );
  }

  @override
  bool operator ==(Object other) =>
      other is ThemeShapes &&
      other.card == card &&
      other.item == item &&
      other.cover == cover &&
      other.button == button &&
      other.chip == chip &&
      other.iconTile == iconTile &&
      other.dialog == dialog &&
      other.navBar == navBar &&
      other.navIndicator == navIndicator &&
      other.sheetRadius == sheetRadius &&
      other.borderWidth == borderWidth;

  @override
  int get hashCode => Object.hash(
    card,
    item,
    cover,
    button,
    chip,
    iconTile,
    dialog,
    navBar,
    navIndicator,
    sheetRadius,
    borderWidth,
  );
}

class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    this.shapes = const ThemeShapes(),
    this.options = const ThemeOptions(),
  });

  final ThemeShapes shapes;
  final ThemeOptions options;

  @override
  AppTokens copyWith({ThemeShapes? shapes, ThemeOptions? options}) => AppTokens(
    shapes: shapes ?? this.shapes,
    options: options ?? this.options,
  );

  @override
  AppTokens lerp(AppTokens? other, double t) =>
      t < 0.5 ? this : (other ?? this);
}

extension AppTokensContext on BuildContext {
  AppTokens get _tokens =>
      Theme.of(this).extension<AppTokens>() ?? const AppTokens();

  ThemeShapes get shapes => _tokens.shapes;

  ThemeOptions get options => _tokens.options;

  String? get displayFont =>
      resolveFontFamily(_tokens.options.typography.displayFont);
}
