import 'dart:math';

import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_randomizer.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/theme_editor/widgets/color_picker_dialog.dart';
import 'package:sumizuri/features/theme_editor/widgets/editor_kit.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class _GradientPreset {
  const _GradientPreset(
    this.name,
    this.style,
    this.angle,
    this.colors,
    this.strength,
  );

  final String Function(AppLocalizations l10n) name;
  final GradientStyle style;
  final double angle;
  final List<Color?> colors;
  final double strength;
}

final _presets = <_GradientPreset>[
  _GradientPreset(
    (l) => l.gradientPresetDusk,
    GradientStyle.linear,
    135,
    const [Color(0xFF5B3F8C), Color(0xFFE0715B), null],
    0.6,
  ),
  _GradientPreset(
    (l) => l.gradientPresetSakura,
    GradientStyle.linear,
    120,
    const [Color(0xFFE58FB0), Color(0xFF6D4F9A), null],
    0.55,
  ),
  _GradientPreset(
    (l) => l.gradientPresetOcean,
    GradientStyle.linear,
    160,
    const [Color(0xFF1F7A99), Color(0xFF0B1F3A), null],
    0.65,
  ),
  _GradientPreset(
    (l) => l.gradientPresetForest,
    GradientStyle.linear,
    145,
    const [Color(0xFF2E7A56), Color(0xFF0F2A1E), null],
    0.6,
  ),
  _GradientPreset(
    (l) => l.gradientPresetEmber,
    GradientStyle.linear,
    90,
    const [Color(0xFFC2410C), Color(0xFF2A0E05), null],
    0.6,
  ),
  _GradientPreset(
    (l) => l.gradientPresetAurora,
    GradientStyle.radial,
    300,
    const [Color(0xFF3DDC97), Color(0xFF5B5BD6), Color(0xFF0B132B)],
    0.55,
  ),
  _GradientPreset(
    (l) => l.gradientPresetSunrise,
    GradientStyle.linear,
    45,
    const [Color(0xFFFFB86B), Color(0xFFC23B6B), Color(0xFF3A1C71)],
    0.55,
  ),
  _GradientPreset(
    (l) => l.gradientPresetMono,
    GradientStyle.linear,
    135,
    const [Color(0xFF8A8A8A), Color(0xFF1A1A1A), null],
    0.5,
  ),
];

/// The background tab: the soft glow, the tint, and an optional gradient.
/// [primary] and [tertiary] are what an empty gradient colour falls back to,
/// shown so the swatches say what they will be.
class BackgroundEditor extends StatelessWidget {
  const BackgroundEditor({
    super.key,
    required this.options,
    required this.onChanged,
    required this.primary,
    required this.tertiary,
    required this.secondary,
  });

  final ThemeOptions options;
  final ValueChanged<ThemeOptions> onChanged;
  final Color primary;
  final Color secondary;
  final Color tertiary;

  Widget _presetChip(
    BuildContext context,
    AppLocalizations l10n,
    _GradientPreset preset,
  ) {
    final cs = Theme.of(context).colorScheme;
    final colors = [for (final c in preset.colors) ?c];
    return InkWell(
      onTap: () => onChanged(
        options.copyWith(
          background: options.background.copyWith(
            gradient: true,
            gradientStyle: preset.style,
            gradientAngle: preset.angle,
            gradientColors: preset.colors,
            gradientStrength: preset.strength,
          ),
        ),
      ),
      borderRadius: context.shapes.chip.radius,
      child: Container(
        width: 84,
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          borderRadius: context.shapes.chip.radius,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(6),
                gradient: preset.style == GradientStyle.radial
                    ? RadialGradient(
                        center: const Alignment(0.3, -0.3),
                        radius: 1,
                        colors: colors,
                      )
                    : LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: colors,
                      ),
              ),
            ),
            const SizedBox(height: 5),
            Text(
              preset.name(l10n),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11.5, color: cs.onSurface),
            ),
          ],
        ),
      ),
    );
  }

  Widget _swatch(
    BuildContext context, {
    required String label,
    required Color shown,
    required bool custom,
    required bool optional,
    required VoidCallback onPick,
    required VoidCallback onClear,
  }) {
    final cs = Theme.of(context).colorScheme;
    final empty = optional && !custom;
    return Expanded(
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              InkWell(
                onTap: onPick,
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  width: 56,
                  height: 42,
                  decoration: BoxDecoration(
                    color: empty ? null : shown,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  alignment: Alignment.center,
                  child: empty
                      ? Icon(Icons.add, size: 18, color: cs.outline)
                      : null,
                ),
              ),
              if (custom)
                Positioned(
                  top: -6,
                  right: -6,
                  child: InkWell(
                    onTap: onClear,
                    child: CircleAvatar(
                      radius: 9,
                      backgroundColor: cs.surfaceContainerHighest,
                      child: Icon(Icons.close, size: 12, color: cs.onSurface),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final side = AppRowStyle.marginOf(context);
    final e = options.effects;
    final b = options.background;

    void setBackground(ThemeBackground next) =>
        onChanged(options.copyWith(background: next));

    Future<void> pick(int slot) async {
      final fallback = [primary, tertiary, secondary][slot];
      final chosen = await showColorPickerDialog(
        context,
        b.gradientColors[slot] ?? fallback,
        suggestions: [primary, secondary, tertiary],
      );
      if (chosen != null) setBackground(b.withColor(slot, chosen));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSection(
          title: l10n.themeGroupBackground,
          onReset: () => onChanged(
            options.copyWith(effects: e.copyWith(bloom: 1, clearTint: true)),
          ),
          children: [
            EditorSlider(
              label: l10n.themeBloom,
              hint: l10n.themeBloomHint,
              value: e.bloom,
              min: 0,
              max: 2,
              divisions: 40,
              defaultValue: 1,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) =>
                  onChanged(options.copyWith(effects: e.copyWith(bloom: v))),
            ),
            EditorSlider(
              label: l10n.themeBackgroundTint,
              hint: l10n.themeBackgroundTintHint,
              value: e.backgroundTint ?? 16,
              min: 0,
              max: 40,
              divisions: 40,
              defaultValue: 16,
              format: (v) => v.round().toString(),
              onChanged: (v) => onChanged(
                options.copyWith(
                  effects: e.copyWith(backgroundTint: v.roundToDouble()),
                ),
              ),
            ),
          ],
        ),
        EditorSection(
          title: l10n.backgroundGradient,
          onReset: () => setBackground(const ThemeBackground()),
          children: [
            AppSwitchRow(
              icon: Icons.gradient,
              title: l10n.backgroundGradient,
              subtitle: l10n.backgroundGradientHint,
              value: b.gradient,
              onChanged: (on) => setBackground(b.copyWith(gradient: on)),
            ),
            if (b.gradient) ...[
              SizedBox(
                height: 76,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: side, vertical: 4),
                  itemCount: _presets.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    if (i == _presets.length) {
                      // A gradient made by chance, from these hues.
                      return InkWell(
                        onTap: () {
                          final g = ThemeRandomizer(Random()).gradient();
                          setBackground(
                            b.copyWith(
                              gradient: true,
                              gradientStyle: g.style,
                              gradientAngle: g.angle.toDouble(),
                              gradientColors: g.colors,
                              gradientStrength: g.strength / 100,
                            ),
                          );
                        },
                        borderRadius: context.shapes.chip.radius,
                        child: Container(
                          width: 84,
                          decoration: BoxDecoration(
                            borderRadius: context.shapes.chip.radius,
                            border: Border.all(color: cs.outlineVariant),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.casino_outlined, color: cs.primary),
                              const SizedBox(height: 4),
                              Text(
                                l10n.randomizeAction,
                                style: TextStyle(
                                  fontSize: 11.5,
                                  color: cs.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return _presetChip(context, l10n, _presets[i]);
                  },
                ),
              ),
              EditorChoice<GradientStyle>(
                label: l10n.backgroundGradientStyle,
                options: {
                  GradientStyle.linear: l10n.backgroundGradientLinear,
                  GradientStyle.radial: l10n.backgroundGradientRadial,
                },
                value: b.gradientStyle,
                onChanged: (s) => setBackground(b.copyWith(gradientStyle: s)),
              ),
              EditorSlider(
                label: l10n.backgroundGradientDirection,
                value: b.gradientAngle,
                min: 0,
                max: 360,
                divisions: 72,
                defaultValue: 135,
                format: (v) => '${v.round()}°',
                onChanged: (v) =>
                    setBackground(b.copyWith(gradientAngle: v.roundToDouble())),
              ),
              EditorSlider(
                label: l10n.backgroundGradientStrength,
                value: b.gradientStrength,
                min: 0.05,
                max: 1,
                divisions: 19,
                defaultValue: 0.4,
                format: (v) => '${(v * 100).round()}%',
                onChanged: (v) =>
                    setBackground(b.copyWith(gradientStrength: v)),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(side, 12, side, 4),
                child: Text(
                  l10n.backgroundGradientColors,
                  style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(side, 4, side, 8),
                child: Row(
                  children: [
                    _swatch(
                      context,
                      label: l10n.backgroundGradientStart,
                      shown: b.gradientColors[0] ?? primary,
                      custom: b.gradientColors[0] != null,
                      optional: false,
                      onPick: () => pick(0),
                      onClear: () => setBackground(b.withColor(0, null)),
                    ),
                    _swatch(
                      context,
                      label: l10n.backgroundGradientEnd,
                      shown: b.gradientColors[1] ?? tertiary,
                      custom: b.gradientColors[1] != null,
                      optional: false,
                      onPick: () => pick(1),
                      onClear: () => setBackground(b.withColor(1, null)),
                    ),
                    _swatch(
                      context,
                      label: l10n.backgroundGradientThird,
                      shown: b.gradientColors[2] ?? secondary,
                      custom: b.gradientColors[2] != null,
                      optional: true,
                      onPick: () => pick(2),
                      onClear: () => setBackground(b.withColor(2, null)),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}
