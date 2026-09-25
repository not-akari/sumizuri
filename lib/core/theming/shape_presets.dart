import 'package:sumizuri/core/theming/theme_shapes.dart';

/// A whole set of corners chosen together, so a theme's shapes agree with
/// each other. Each is a starting point the individual corners can be
/// adjusted from.
enum ShapeCharacter { sharp, soft, round, leaf }

/// The shapes of [character], built on [base] so anything not part of the
/// character (the border weight) is kept.
ThemeShapes shapesFor(ShapeCharacter character, ThemeShapes base) {
  ShapeSpec spec(double size, {double scale = 1}) => switch (character) {
    ShapeCharacter.sharp => ShapeSpec(ShapeStyle.uniform, 3 * scale),
    ShapeCharacter.soft => ShapeSpec(ShapeStyle.uniform, 13 * scale),
    ShapeCharacter.round => ShapeSpec(ShapeStyle.uniform, 24 * scale),
    ShapeCharacter.leaf => ShapeSpec(ShapeStyle.asymmetric, 20 * scale, 4),
  };

  var shapes = base
      .withSpec('card', spec(1))
      .withSpec('item', spec(1, scale: 0.85))
      .withSpec('cover', spec(1, scale: 0.7))
      .withSpec(
        'iconTile',
        ShapeSpec(ShapeStyle.uniform, switch (character) {
          ShapeCharacter.sharp => 3,
          ShapeCharacter.soft => 10,
          ShapeCharacter.round => 14,
          ShapeCharacter.leaf => 10,
        }),
      )
      .withSpec('dialog', spec(1, scale: 1.2))
      .withSpec('button', spec(1, scale: 0.8))
      .withSpec('chip', spec(1, scale: 0.8))
      .withSpec('navIndicator', spec(1, scale: 0.7));
  if (character == ShapeCharacter.round) {
    shapes = shapes
        .withSpec('button', const ShapeSpec(ShapeStyle.pill, 0))
        .withSpec('chip', const ShapeSpec(ShapeStyle.pill, 0));
  }
  shapes = shapes.withSpec(
    'navBar',
    character == ShapeCharacter.sharp
        ? const ShapeSpec(ShapeStyle.uniform, 4)
        : const ShapeSpec(ShapeStyle.pill, 0),
  );
  return shapes.copyWith(
    sheetRadius: switch (character) {
      ShapeCharacter.sharp => 8,
      ShapeCharacter.soft => 18,
      ShapeCharacter.round => 30,
      ShapeCharacter.leaf => 24,
    },
  );
}
