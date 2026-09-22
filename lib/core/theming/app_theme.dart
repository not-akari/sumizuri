import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/theming/font_catalog.dart';
import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/core/theming/sumizuri_page_transitions_builder.dart';

part 'app_theme_presets.dart';

class SumizuriInkPalette {
  const SumizuriInkPalette._();

  static const inkBg = Color(0xFF17130F);
  static const paperBg = Color(0xFFF3ECDC);
}

const _fontFamilyFallback = <String>[
  'Noto Sans',
  'Noto Sans CJK SC',
  'Noto Sans CJK JP',
  'Noto Sans CJK KR',
  'Noto Sans Arabic',
  'Noto Sans Devanagari',
  'Noto Sans Thai',
  'PingFang SC',
  'Microsoft YaHei',
  'Hiragino Sans',
  'Meiryo',
  'sans-serif',
];

const _appSubThemes = FlexSubThemesData(
  defaultRadius: 6,
  thinBorderWidth: 1,
  thickBorderWidth: 2,
  elevatedButtonElevation: 0,
  cardElevation: 0,
  popupMenuElevation: 2,
  appBarScrolledUnderElevation: 0,
);

double _contrastRatio(Color a, Color b) {
  final l1 = a.computeLuminance();
  final l2 = b.computeLuminance();
  final lighter = l1 > l2 ? l1 : l2;
  final darker = l1 > l2 ? l2 : l1;
  return (lighter + 0.05) / (darker + 0.05);
}

Color _withContrast(Color fg, Color bg, double minimum, {Color? toward}) {
  if (_contrastRatio(fg, bg) >= minimum) return fg;
  const black = Color(0xFF000000);
  const white = Color(0xFFFFFFFF);
  final target =
      toward ??
      (_contrastRatio(black, bg) > _contrastRatio(white, bg) ? black : white);
  for (var step = 1; step <= 10; step++) {
    final candidate = Color.lerp(fg, target, step / 10)!;
    if (_contrastRatio(candidate, bg) >= minimum) return candidate;
  }
  return target;
}

ColorScheme _readable(ColorScheme cs) => cs.copyWith(
  outline: _withContrast(cs.outline, cs.surface, 4.5, toward: cs.onSurface),
  onPrimary: _withContrast(cs.onPrimary, cs.primary, 4.5),
  onPrimaryContainer: _withContrast(
    cs.onPrimaryContainer,
    cs.primaryContainer,
    4.5,
  ),
);

ThemeData _applyShapes(
  ThemeData theme,
  ThemeShapes shapes, [
  ThemeOptions options = const ThemeOptions(),
]) {
  final buttonShape = shapes.button.border();
  return theme.copyWith(
    colorScheme: _readable(theme.colorScheme),
    appBarTheme: theme.appBarTheme.copyWith(
      backgroundColor: theme.colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
    ),
    cardTheme: theme.cardTheme.copyWith(shape: shapes.card.border()),
    chipTheme: theme.chipTheme.copyWith(shape: shapes.chip.border()),
    filledButtonTheme: FilledButtonThemeData(
      style: theme.filledButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(buttonShape),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: theme.outlinedButtonTheme.style?.copyWith(
        shape: WidgetStatePropertyAll(buttonShape),
      ),
    ),
    bottomSheetTheme: theme.bottomSheetTheme.copyWith(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(shapes.sheetRadius),
        ),
      ),
    ),
    dialogTheme: theme.dialogTheme.copyWith(shape: shapes.dialog.border()),
    visualDensity: switch (options.layout.density) {
      LayoutDensity.compact => const VisualDensity(
        horizontal: -1,
        vertical: -1,
      ),
      LayoutDensity.comfortable => theme.visualDensity,
      LayoutDensity.spacious => const VisualDensity(horizontal: 1, vertical: 1),
    },
    extensions: [AppTokens(shapes: shapes, options: options)],
  );
}

enum AppColorScheme {
  sumizuriInk('Sumizuri Ink'),
  sakura('Sakura'),
  indigoNight('Indigo Night'),
  bamboo('Bamboo');

  const AppColorScheme(this.label);

  final String label;
}

enum DarkVariant { standard, amoled }

extension on ColorIntensity {
  int get blendLevel => switch (this) {
    ColorIntensity.subtle => 6,
    ColorIntensity.medium => 16,
    ColorIntensity.vivid => 30,
  };
}

const _pageTransitionsTheme = PageTransitionsTheme(
  builders: {
    TargetPlatform.android: SumizuriPageTransitionsBuilder(),
    TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
    TargetPlatform.windows: SumizuriPageTransitionsBuilder(),
    TargetPlatform.macOS: SumizuriPageTransitionsBuilder(),
    TargetPlatform.linux: SumizuriPageTransitionsBuilder(),
  },
);

class AppTheme {
  const AppTheme._();

  static final _builtInCache = <String, ThemeData>{};

  static ThemeData light(
    AppColorScheme scheme, {
    ColorIntensity intensity = ColorIntensity.medium,
  }) => _builtInCache.putIfAbsent(
    'light-${scheme.name}-${intensity.name}',
    () =>
        _buildPreset(scheme, Brightness.light, DarkVariant.standard, intensity),
  );

  static ThemeData dark(
    AppColorScheme scheme,
    DarkVariant variant, {
    ColorIntensity intensity = ColorIntensity.medium,
  }) => _builtInCache.putIfAbsent(
    'dark-${scheme.name}-${variant.name}-${intensity.name}',
    () => _buildPreset(scheme, Brightness.dark, variant, intensity),
  );

  /// The editable colours of a preset, so a copy starts from what the preset looks like.
  static ThemeColors presetColors(
    AppColorScheme scheme,
    Brightness brightness,
  ) {
    final preset = _presets[scheme]!;
    return brightness == Brightness.dark ? preset.dark : preset.light;
  }

  static ThemeData _buildPreset(
    AppColorScheme scheme,
    Brightness brightness,
    DarkVariant variant,
    ColorIntensity intensity,
  ) {
    final preset = _presets[scheme]!;
    final amoled =
        brightness == Brightness.dark && variant == DarkVariant.amoled;
    final theme = CustomTheme(
      id: scheme.name,
      name: scheme.label,
      light: preset.light,
      // AMOLED means a black background, so the preset's own is left out.
      dark: amoled ? preset.dark.withRole('surface', null) : preset.dark,
      options: ThemeOptions(
        effects: ThemeEffects(
          backgroundTint: switch (intensity) {
            ColorIntensity.subtle => 3,
            ColorIntensity.medium => 8,
            ColorIntensity.vivid => 16,
          },
        ),
      ),
    );
    return _buildCustom(theme, brightness, variant, intensity, preset: true);
  }

  static ThemeData custom(
    CustomTheme theme, {
    required Brightness brightness,
    DarkVariant variant = DarkVariant.standard,
    ColorIntensity intensity = ColorIntensity.medium,
  }) {
    for (final hit in _customCache) {
      if (identical(hit.theme, theme) &&
          hit.brightness == brightness &&
          hit.variant == variant &&
          hit.intensity == intensity) {
        return hit.result;
      }
    }
    final result = _buildCustom(theme, brightness, variant, intensity);
    _customCache.add((
      theme: theme,
      brightness: brightness,
      variant: variant,
      intensity: intensity,
      result: result,
    ));
    if (_customCache.length > 4) _customCache.removeAt(0);
    return result;
  }

  static final _customCache =
      <
        ({
          CustomTheme theme,
          Brightness brightness,
          DarkVariant variant,
          ColorIntensity intensity,
          ThemeData result,
        })
      >[];

  static ThemeData _buildCustom(
    CustomTheme theme,
    Brightness brightness,
    DarkVariant variant,
    ColorIntensity intensity, {
    bool preset = false,
  }) {
    final isDark = brightness == Brightness.dark;
    final c = isDark ? theme.dark : theme.light;
    final colors = FlexSchemeColor.from(
      primary:
          c.primary ??
          (isDark
              ? _presets[AppColorScheme.sumizuriInk]!.dark.primary!
              : _presets[AppColorScheme.sumizuriInk]!.light.primary!),
      primaryContainer: c.primaryContainer,
      secondary: c.secondary,
      tertiary: c.tertiary,
      error: c.error,
      brightness: brightness,
    );
    // A chosen surface must stay exact, so no primary tint is blended over it.
    final effects = theme.options.effects;
    final blend = c.surface != null
        ? 0
        : (effects.backgroundTint?.round() ?? intensity.blendLevel);
    final forceBlack =
        isDark &&
        c.surface == null &&
        (effects.oledDark || variant == DarkVariant.amoled);
    final tint = effects.backgroundTint;
    final surface = c.surface == null || tint == null
        ? c.surface
        : Color.alphaBlend(
            colors.primary.withValues(alpha: tint / 100 * 0.35),
            c.surface!,
          );
    final base = isDark
        ? FlexThemeData.dark(
            colors: colors,
            useMaterial3: true,
            darkIsTrueBlack: forceBlack,
            surfaceMode: FlexSurfaceMode.level,
            blendLevel: blend,
            surface: forceBlack ? null : surface,
            scaffoldBackground: forceBlack ? null : surface,
            subThemesData: _appSubThemes,
          )
        : FlexThemeData.light(
            colors: colors,
            useMaterial3: true,
            surfaceMode: FlexSurfaceMode.level,
            blendLevel: blend,
            surface: surface,
            scaffoldBackground: surface,
            subThemesData: _appSubThemes,
          );
    final bodyFont = resolveFontFamily(theme.options.typography.bodyFont);
    return _applyShapes(
      base.copyWith(
        pageTransitionsTheme: _pageTransitionsTheme,
        textTheme: base.textTheme.apply(
          fontFamily: bodyFont,
          fontFamilyFallback: _fontFamilyFallback,
        ),
      ),
      theme.shapes,
      theme.options,
    );
  }
}
