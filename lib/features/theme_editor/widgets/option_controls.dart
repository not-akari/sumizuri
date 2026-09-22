import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/font_catalog.dart';
import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/features/theme_editor/widgets/font_picker_sheet.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

part 'option_control_widgets.dart';

class TypeLayoutControls extends StatelessWidget {
  const TypeLayoutControls({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final ThemeOptions options;
  final ValueChanged<ThemeOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final t = options.typography;
    final l = options.layout;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(
          title: l10n.themeGroupTypography,
          children: [
            _FontTile(
              label: l10n.themeHeadingFont,
              value: t.displayFont,
              defaultLabel: l10n.themeFontDefault,
              onChanged: (v) => onChanged(
                options.copyWith(typography: t.copyWith(displayFont: v)),
              ),
            ),
            _FontTile(
              label: l10n.themeBodyFont,
              value: t.bodyFont,
              defaultLabel: l10n.themeFontDefault,
              onChanged: (v) => onChanged(
                options.copyWith(typography: t.copyWith(bodyFont: v)),
              ),
            ),
            _Slider(
              label: l10n.themeTextScale,
              value: t.textScale,
              min: 0.8,
              max: 1.4,
              onChanged: (v) => onChanged(
                options.copyWith(typography: t.copyWith(textScale: v)),
              ),
            ),
          ],
        ),
        _Group(
          title: l10n.themeGroupLayout,
          children: [
            AppChoice<LayoutDensity>.map(
              options: {
                LayoutDensity.compact: l10n.themeDensityCompact,
                LayoutDensity.comfortable: l10n.themeDensityComfortable,
                LayoutDensity.spacious: l10n.themeDensitySpacious,
              },
              value: l.density,
              onChanged: (v) =>
                  onChanged(options.copyWith(layout: l.copyWith(density: v))),
            ),
            _Slider(
              label: l10n.themeSpacing,
              value: l.spacing,
              min: 0.6,
              max: 1.6,
              onChanged: (v) =>
                  onChanged(options.copyWith(layout: l.copyWith(spacing: v))),
            ),
          ],
        ),
        _ResetButton(
          onPressed: () => onChanged(
            options.copyWith(
              typography: const ThemeTypography(),
              layout: const ThemeLayout(),
            ),
          ),
        ),
      ],
    );
  }
}

class EffectsMotionControls extends StatelessWidget {
  const EffectsMotionControls({
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(
          title: l10n.themeGroupEffects,
          children: [
            _Slider(
              label: l10n.themeBloom,
              value: e.bloom,
              min: 0,
              max: 2,
              onChanged: (v) =>
                  onChanged(options.copyWith(effects: e.copyWith(bloom: v))),
            ),
            AppToggleTile(
              title: l10n.themeBrushStrokes,
              value: e.brushStrokes,
              onChanged: (v) => onChanged(
                options.copyWith(effects: e.copyWith(brushStrokes: v)),
              ),
            ),
            AppToggleTile(
              title: l10n.themeCoverShadow,
              value: e.coverShadow,
              onChanged: (v) => onChanged(
                options.copyWith(effects: e.copyWith(coverShadow: v)),
              ),
            ),
          ],
        ),
        _Group(
          title: l10n.themeGroupMotion,
          children: [
            _Slider(
              label: l10n.themeHoverScale,
              value: m.hoverScale,
              min: 1,
              max: 1.12,
              onChanged: (v) => onChanged(
                options.copyWith(motion: m.copyWith(hoverScale: v)),
              ),
            ),
            _Slider(
              label: l10n.themePressScale,
              value: m.pressScale,
              min: 0.8,
              max: 1,
              onChanged: (v) => onChanged(
                options.copyWith(motion: m.copyWith(pressScale: v)),
              ),
            ),
            _Slider(
              label: l10n.themeTransitionSpeed,
              value: m.transitionSpeed,
              min: 0.5,
              max: 2,
              onChanged: (v) => onChanged(
                options.copyWith(motion: m.copyWith(transitionSpeed: v)),
              ),
            ),
          ],
        ),
        _ResetButton(
          onPressed: () => onChanged(
            options.copyWith(
              effects: const ThemeEffects(),
              motion: const ThemeMotion(),
            ),
          ),
        ),
      ],
    );
  }
}

class ComponentToggles extends StatelessWidget {
  const ComponentToggles({
    super.key,
    required this.options,
    required this.onChanged,
  });

  final ThemeOptions options;
  final ValueChanged<ThemeOptions> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final c = options.components;
    return _Group(
      title: l10n.themeGroupComponents,
      children: [
        AppToggleTile(
          title: l10n.themeListIconTiles,
          value: c.listIconTiles,
          onChanged: (v) => onChanged(
            options.copyWith(components: c.copyWith(listIconTiles: v)),
          ),
        ),
        AppToggleTile(
          title: l10n.themeListChevron,
          value: c.listChevron,
          onChanged: (v) => onChanged(
            options.copyWith(components: c.copyWith(listChevron: v)),
          ),
        ),
      ],
    );
  }
}

class BackgroundControls extends StatelessWidget {
  const BackgroundControls({
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Group(
          title: l10n.themeGroupBackground,
          children: [
            _Slider(
              label: l10n.themeBackgroundTint,
              value: e.backgroundTint ?? 16,
              min: 0,
              max: 40,
              suffix: '',
              onChanged: (v) => onChanged(
                options.copyWith(
                  effects: e.copyWith(backgroundTint: v.roundToDouble()),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
