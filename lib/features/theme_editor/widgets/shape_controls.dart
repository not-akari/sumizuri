import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/shape_presets.dart';
import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/theme_editor/widgets/editor_kit.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The shape tab: how rounded things are, how heavy their edges are, and how
/// solid the cards and rows look.
class ShapeControls extends StatelessWidget {
  const ShapeControls({
    super.key,
    required this.shapes,
    required this.options,
    required this.onShapesChanged,
    required this.onOptionsChanged,
  });

  final ThemeShapes shapes;
  final ThemeOptions options;
  final ValueChanged<ThemeShapes> onShapesChanged;
  final ValueChanged<ThemeOptions> onOptionsChanged;

  String _label(AppLocalizations l10n, String key) => switch (key) {
    'card' => l10n.themeShapeCard,
    'item' => l10n.themeShapeItem,
    'cover' => l10n.themeShapeCover,
    'button' => l10n.themeShapeButton,
    'chip' => l10n.themeShapeChip,
    'iconTile' => l10n.themeShapeIconTile,
    'navBar' => l10n.themeShapeNavBar,
    'navIndicator' => l10n.themeShapeNavIndicator,
    _ => l10n.themeShapeDialog,
  };

  String _characterLabel(AppLocalizations l10n, ShapeCharacter c) =>
      switch (c) {
        ShapeCharacter.sharp => l10n.themeShapeCharacterSharp,
        ShapeCharacter.soft => l10n.themeShapeCharacterSoft,
        ShapeCharacter.round => l10n.themeShapeCharacterRound,
        ShapeCharacter.leaf => l10n.themeShapeCharacterLeaf,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final side = AppRowStyle.marginOf(context);
    final c = options.components;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSection(
          title: l10n.themeShapeStartFrom,
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: side, vertical: 4),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final character in ShapeCharacter.values)
                    OutlinedButton(
                      onPressed: () =>
                          onShapesChanged(shapesFor(character, shapes)),
                      child: Text(_characterLabel(l10n, character)),
                    ),
                ],
              ),
            ),
          ],
        ),
        EditorSection(
          title: l10n.themeShapeCorners,
          onReset: () => onShapesChanged(const ThemeShapes()),
          children: [
            for (final key in ThemeShapes.specKeys)
              _SpecCard(
                label: _label(l10n, key),
                spec: shapes.spec(key),
                onChanged: (spec) =>
                    onShapesChanged(shapes.withSpec(key, spec)),
              ),
            EditorSlider(
              label: l10n.themeShapeSheet,
              value: shapes.sheetRadius,
              min: 0,
              max: 32,
              divisions: 32,
              defaultValue: const ThemeShapes().sheetRadius,
              format: (v) => v.round().toString(),
              onChanged: (v) =>
                  onShapesChanged(shapes.copyWith(sheetRadius: v)),
            ),
            EditorSlider(
              label: l10n.themeShapeBorderWidth,
              value: shapes.borderWidth,
              min: 0,
              max: 3,
              divisions: 6,
              defaultValue: const ThemeShapes().borderWidth,
              format: (v) => v.toStringAsFixed(1),
              onChanged: (v) =>
                  onShapesChanged(shapes.copyWith(borderWidth: v)),
            ),
          ],
        ),
        EditorSection(
          title: l10n.themeGroupCards,
          onReset: () => onOptionsChanged(
            options.copyWith(
              components: c.copyWith(cardOpacity: 1, cardBorders: true),
            ),
          ),
          children: [
            EditorSlider(
              label: l10n.themeCardOpacity,
              hint: l10n.themeCardOpacityHint,
              value: c.cardOpacity,
              min: 0.3,
              max: 1.5,
              divisions: 24,
              defaultValue: 1,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => onOptionsChanged(
                options.copyWith(components: c.copyWith(cardOpacity: v)),
              ),
            ),
            AppSwitchRow(
              icon: Icons.crop_square,
              title: l10n.themeCardBorders,
              value: c.cardBorders,
              onChanged: (v) => onOptionsChanged(
                options.copyWith(components: c.copyWith(cardBorders: v)),
              ),
            ),
          ],
        ),
        EditorSection(
          title: l10n.themeGroupComponents,
          onReset: () => onOptionsChanged(
            options.copyWith(
              components: c.copyWith(listChevron: true, listIconTiles: true),
            ),
          ),
          children: [
            AppSwitchRow(
              icon: Icons.crop_din,
              title: l10n.themeListIconTiles,
              value: c.listIconTiles,
              onChanged: (v) => onOptionsChanged(
                options.copyWith(components: c.copyWith(listIconTiles: v)),
              ),
            ),
            AppSwitchRow(
              icon: Icons.chevron_right_rounded,
              title: l10n.themeListChevron,
              value: c.listChevron,
              onChanged: (v) => onOptionsChanged(
                options.copyWith(components: c.copyWith(listChevron: v)),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
      ],
    );
  }
}

/// The corners of one kind of thing: a small sample of the shape, its style,
/// and how big the corner is.
class _SpecCard extends StatelessWidget {
  const _SpecCard({
    required this.label,
    required this.spec,
    required this.onChanged,
  });

  final String label;
  final ShapeSpec spec;
  final ValueChanged<ShapeSpec> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AppCard(
      tone: AppCardTone.inset,
      margin: EdgeInsets.symmetric(
        horizontal: AppRowStyle.marginOf(context),
        vertical: 4,
      ),
      padding: const EdgeInsets.fromLTRB(14, 12, 10, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 28,
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.18),
                  border: Border.all(color: cs.primary),
                  borderRadius: spec.radius,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AppChoice<ShapeStyle>.map(
            compact: true,
            options: {
              ShapeStyle.asymmetric: l10n.themeShapeStyleAsymmetric,
              ShapeStyle.uniform: l10n.themeShapeStyleUniform,
              ShapeStyle.pill: l10n.themeShapeStylePill,
            },
            value: spec.style,
            onChanged: (style) => onChanged(spec.copyWith(style: style)),
          ),
          if (spec.style != ShapeStyle.pill)
            _MiniSlider(
              label: spec.style == ShapeStyle.asymmetric
                  ? l10n.themeShapeLarge
                  : l10n.themeShapeRadius,
              value: spec.large,
              max: 32,
              onChanged: (v) => onChanged(spec.copyWith(large: v)),
            ),
          if (spec.style == ShapeStyle.asymmetric)
            _MiniSlider(
              label: l10n.themeShapeSmall,
              value: spec.small,
              max: 16,
              onChanged: (v) => onChanged(spec.copyWith(small: v)),
            ),
        ],
      ),
    );
  }
}

class _MiniSlider extends StatelessWidget {
  const _MiniSlider({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
  });

  final String label;
  final double value;
  final double max;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        SizedBox(
          width: 104,
          child: Text(
            label,
            style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
          ),
        ),
        Expanded(
          child: Slider(
            value: value.clamp(0, max).toDouble(),
            max: max,
            divisions: max.round(),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text(
            value.round().toString(),
            textAlign: TextAlign.end,
            style: TextStyle(fontSize: 12.5, color: cs.outline),
          ),
        ),
      ],
    );
  }
}
