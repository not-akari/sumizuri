import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/font_catalog.dart';
import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/features/theme_editor/widgets/editor_kit.dart';
import 'package:sumizuri/features/theme_editor/widgets/font_picker_sheet.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The type and layout tab: the two typefaces, the text size, and how tightly
/// things are packed.
class TypeControls extends StatelessWidget {
  const TypeControls({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final ThemeOptions options;
  final ValueChanged<ThemeOptions> onChanged;

  Widget _fontRow(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String value,
    required String defaultLabel,
    required ValueChanged<String> onPicked,
  }) {
    final cs = Theme.of(context).colorScheme;
    return AppListRow(
      icon: icon,
      title: label,
      subtitleWidget: Text(
        fontLabel(value, defaultLabel),
        style: TextStyle(
          fontFamily: resolveFontFamily(value),
          fontSize: 13,
          color: cs.primary,
        ),
      ),
      onTap: () async {
        final picked = await showFontPicker(
          context,
          current: value,
          defaultLabel: defaultLabel,
        );
        if (picked != null) onPicked(picked);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = options.typography;
    final l = options.layout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSection(
          title: l10n.themeGroupTypography,
          onReset: () =>
              onChanged(options.copyWith(typography: const ThemeTypography())),
          children: [
            _fontRow(
              context,
              icon: Icons.title,
              label: l10n.themeHeadingFont,
              value: t.displayFont,
              defaultLabel: l10n.themeFontDefault,
              onPicked: (v) => onChanged(
                options.copyWith(typography: t.copyWith(displayFont: v)),
              ),
            ),
            _fontRow(
              context,
              icon: Icons.text_fields_rounded,
              label: l10n.themeBodyFont,
              value: t.bodyFont,
              defaultLabel: l10n.themeFontDefault,
              onPicked: (v) => onChanged(
                options.copyWith(typography: t.copyWith(bodyFont: v)),
              ),
            ),
            EditorSlider(
              label: l10n.themeTextScale,
              value: t.textScale,
              min: 0.8,
              max: 1.4,
              divisions: 30,
              defaultValue: 1,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) => onChanged(
                options.copyWith(typography: t.copyWith(textScale: v)),
              ),
            ),
          ],
        ),
        EditorSection(
          title: l10n.themeGroupLayout,
          onReset: () =>
              onChanged(options.copyWith(layout: const ThemeLayout())),
          children: [
            EditorChoice<LayoutDensity>(
              label: l10n.themeDensity,
              options: {
                LayoutDensity.compact: l10n.themeDensityCompact,
                LayoutDensity.comfortable: l10n.themeDensityComfortable,
                LayoutDensity.spacious: l10n.themeDensitySpacious,
              },
              value: l.density,
              onChanged: (v) =>
                  onChanged(options.copyWith(layout: l.copyWith(density: v))),
            ),
            EditorSlider(
              label: l10n.themeSpacing,
              hint: l10n.themeSpacingHint,
              value: l.spacing,
              min: 0.6,
              max: 1.6,
              divisions: 20,
              defaultValue: 1,
              format: (v) => '${(v * 100).round()}%',
              onChanged: (v) =>
                  onChanged(options.copyWith(layout: l.copyWith(spacing: v))),
            ),
          ],
        ),
      ],
    );
  }
}

/// The effects tab: the hand-drawn touches and how things move.
class EffectsControls extends StatelessWidget {
  const EffectsControls({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final ThemeOptions options;
  final ValueChanged<ThemeOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final e = options.effects;
    final m = options.motion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        EditorSection(
          title: l10n.themeGroupEffects,
          onReset: () => onChanged(
            options.copyWith(
              effects: e.copyWith(brushStrokes: true, coverShadow: false),
            ),
          ),
          children: [
            AppSwitchRow(
              icon: Icons.brush_outlined,
              title: l10n.themeBrushStrokes,
              subtitle: l10n.themeBrushStrokesHint,
              value: e.brushStrokes,
              onChanged: (v) => onChanged(
                options.copyWith(effects: e.copyWith(brushStrokes: v)),
              ),
            ),
            AppSwitchRow(
              icon: Icons.layers_outlined,
              title: l10n.themeCoverShadow,
              subtitle: l10n.themeCoverShadowHint,
              value: e.coverShadow,
              onChanged: (v) => onChanged(
                options.copyWith(effects: e.copyWith(coverShadow: v)),
              ),
            ),
          ],
        ),
        EditorSection(
          title: l10n.themeGroupMotion,
          onReset: () =>
              onChanged(options.copyWith(motion: const ThemeMotion())),
          children: [
            EditorSlider(
              label: l10n.themeHoverScale,
              hint: l10n.themeHoverScaleHint,
              value: m.hoverScale,
              min: 1,
              max: 1.12,
              divisions: 24,
              defaultValue: 1.02,
              format: (v) => '${((v - 1) * 100).toStringAsFixed(1)}%',
              onChanged: (v) => onChanged(
                options.copyWith(motion: m.copyWith(hoverScale: v)),
              ),
            ),
            EditorSlider(
              label: l10n.themePressScale,
              hint: l10n.themePressScaleHint,
              value: m.pressScale,
              min: 0.8,
              max: 1,
              divisions: 40,
              defaultValue: 0.96,
              format: (v) => '${((1 - v) * 100).toStringAsFixed(1)}%',
              onChanged: (v) => onChanged(
                options.copyWith(motion: m.copyWith(pressScale: v)),
              ),
            ),
            EditorSlider(
              label: l10n.themeTransitionSpeed,
              hint: l10n.themeTransitionSpeedHint,
              value: m.transitionSpeed,
              min: 0.5,
              max: 2,
              divisions: 30,
              defaultValue: 1,
              format: (v) => '${v.toStringAsFixed(2)}×',
              onChanged: (v) => onChanged(
                options.copyWith(motion: m.copyWith(transitionSpeed: v)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
