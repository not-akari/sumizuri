import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ShapeControls extends StatelessWidget {
  const ShapeControls({
    super.key,
    required this.shapes,
    required this.onChanged,
  });

  final ThemeShapes shapes;
  final ValueChanged<ThemeShapes> onChanged;

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final key in ThemeShapes.specKeys)
          _SpecRow(
            label: _label(l10n, key),
            spec: shapes.spec(key),
            onChanged: (spec) => onChanged(shapes.withSpec(key, spec)),
          ),
        _SliderRow(
          label: l10n.themeShapeSheet,
          value: shapes.sheetRadius,
          max: 32,
          onChanged: (v) => onChanged(shapes.copyWith(sheetRadius: v)),
        ),
        _SliderRow(
          label: l10n.themeShapeBorderWidth,
          value: shapes.borderWidth,
          max: 3,
          divisions: 6,
          onChanged: (v) => onChanged(shapes.copyWith(borderWidth: v)),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            8,
            context.layout.gutter,
            0,
          ),
          child: Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () => onChanged(const ThemeShapes()),
              icon: Icon(Icons.restart_alt, size: 18, color: cs.primary),
              label: Text(l10n.themeShapeReset),
            ),
          ),
        ),
      ],
    );
  }
}

class _SpecRow extends StatelessWidget {
  const _SpecRow({
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        10,
        context.layout.gutter,
        2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 26,
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
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              AppChoice<ShapeStyle>.map(
                expanded: false,
                compact: true,
                options: {
                  ShapeStyle.asymmetric: l10n.themeShapeStyleAsymmetric,
                  ShapeStyle.uniform: l10n.themeShapeStyleUniform,
                  ShapeStyle.pill: l10n.themeShapeStylePill,
                },
                value: spec.style,
                onChanged: (style) => onChanged(spec.copyWith(style: style)),
              ),
            ],
          ),
          if (spec.style != ShapeStyle.pill)
            _SliderRow(
              label: spec.style == ShapeStyle.asymmetric
                  ? l10n.themeShapeLarge
                  : l10n.themeShapeRadius,
              value: spec.large,
              max: 32,
              inset: 0,
              onChanged: (v) => onChanged(spec.copyWith(large: v)),
            ),
          if (spec.style == ShapeStyle.asymmetric)
            _SliderRow(
              label: l10n.themeShapeSmall,
              value: spec.small,
              max: 16,
              inset: 0,
              onChanged: (v) => onChanged(spec.copyWith(small: v)),
            ),
        ],
      ),
    );
  }
}

class _SliderRow extends StatelessWidget {
  const _SliderRow({
    required this.label,
    required this.value,
    required this.max,
    required this.onChanged,
    this.divisions,
    this.inset = 20,
  });

  final String label;
  final double value;
  final double max;
  final int? divisions;
  final double inset;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: EdgeInsets.fromLTRB(inset, 0, inset, 0),
      child: Row(
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
            ),
          ),
          Expanded(
            child: Slider(
              value: value.clamp(0, max).toDouble(),
              max: max,
              divisions: divisions ?? max.round(),
              onChanged: onChanged,
            ),
          ),
          SizedBox(
            width: 34,
            child: Text(
              value == value.roundToDouble()
                  ? value.round().toString()
                  : value.toStringAsFixed(1),
              textAlign: TextAlign.end,
              style: TextStyle(fontSize: 12.5, color: cs.outline),
            ),
          ),
        ],
      ),
    );
  }
}
