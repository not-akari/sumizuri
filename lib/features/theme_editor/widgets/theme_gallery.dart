import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/core/theming/app_theme.dart';
import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/theming/theme_options.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/overlays/confirm_dialog.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/theme_editor/data/theme_editor_providers.dart';
import 'package:sumizuri/features/theme_editor/data/theme_file_io.dart';
import 'package:sumizuri/features/theme_editor/pages/theme_editor_page.dart';
import 'package:sumizuri/features/theme_editor/widgets/theme_card.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

extension on _ThemeAction {
  String label(AppLocalizations l10n) => switch (this) {
    _ThemeAction.edit => l10n.themesEdit,
    _ThemeAction.duplicate => l10n.themesDuplicate,
    _ThemeAction.export => l10n.themesExport,
    _ThemeAction.delete => l10n.themesDelete,
    _ThemeAction.hide => l10n.themesHide,
  };
}

enum _ThemeAction { edit, duplicate, export, delete, hide }

class ThemeGallery extends ConsumerWidget {
  const ThemeGallery({
    super.key,
    required this.wantsDark,
    required this.amoled,
    required this.intensity,
    this.manage = false,
  });

  final bool wantsDark;
  final bool amoled;
  final ColorIntensity intensity;

  final bool manage;

  ColorScheme _builtInColors(AppColorScheme scheme) => wantsDark
      ? AppTheme.dark(
          scheme,
          amoled ? DarkVariant.amoled : DarkVariant.standard,
          intensity: intensity,
        ).colorScheme
      : AppTheme.light(scheme, intensity: intensity).colorScheme;

  ColorScheme _customColors(CustomTheme theme) => AppTheme.custom(
    theme,
    brightness: wantsDark ? Brightness.dark : Brightness.light,
    variant: amoled ? DarkVariant.amoled : DarkVariant.standard,
    intensity: intensity,
  ).colorScheme;

  CustomTheme _copyOfBuiltIn(AppColorScheme scheme) => CustomTheme(
    id: newThemeId(scheme.label),
    name: scheme.label,
    light: AppTheme.presetColors(scheme, Brightness.light),
    dark: AppTheme.presetColors(scheme, Brightness.dark),
    options: ThemeOptions(effects: ThemeEffects(oledDark: amoled)),
  );

  CustomTheme _startingTheme(
    String? active,
    List<CustomTheme> customs,
    String name,
  ) {
    for (final t in customs) {
      if (t.settingValue == active) {
        return t.copyWith(id: newThemeId(name), name: name);
      }
    }
    final scheme = AppColorScheme.values.firstWhere(
      (s) => s.name == active,
      orElse: () => AppColorScheme.sumizuriInk,
    );
    return _copyOfBuiltIn(scheme).copyWith(id: newThemeId(name), name: name);
  }

  void _edit(BuildContext context, CustomTheme theme) {
    Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => ThemeEditorPage(theme: theme)));
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final theme = await pickThemeFile();
      if (theme == null) return;
      final saved = await ref.read(customThemesProvider.notifier).add(theme);
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.themesImported(saved.name))),
      );
    } on ThemeFormatException catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.themesImportFailed(e.message))),
      );
    }
  }

  Future<void> _export(BuildContext context, CustomTheme theme) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final path = await exportThemeFile(theme);
    if (path != null) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.themesExported(path))),
      );
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CustomTheme theme,
    bool active,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    final confirmed = await showAppConfirmDialog(
      context: context,
      title: l10n.themesDeleteConfirmTitle,
      message: l10n.themesDeleteConfirmMessage(theme.name),
      confirmLabel: l10n.themesDelete,
      isDestructive: true,
    );
    if (!confirmed) return;
    // Fall back to the default preset first so the app never points at a missing theme.
    if (active) {
      await ref
          .read(settingsRepositoryProvider)
          .setThemeScheme(AppColorScheme.sumizuriInk.name);
    }
    await ref.read(customThemesProvider.notifier).delete(theme.id);
  }

  Future<void> _hidePreset(WidgetRef ref, AppColorScheme scheme) async {
    final hidden = ref.read(hiddenThemePresetsProvider).value ?? const {};
    await ref.read(settingsRepositoryProvider).setHiddenThemePresets({
      ...hidden,
      scheme,
    });
  }

  Widget _menu(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n, {
    CustomTheme? custom,
    AppColorScheme? builtIn,
    bool active = false,
  }) {
    return AppMenu<_ThemeAction>.of(
      iconSize: 18,
      tight: true,
      onSelected: (action) {
        switch (action) {
          case _ThemeAction.edit:
            _edit(context, custom ?? _copyOfBuiltIn(builtIn!));
          case _ThemeAction.duplicate:
            _edit(
              context,
              custom != null
                  ? custom.copyWith(
                      id: newThemeId(custom.name),
                      name: '${custom.name} copy',
                    )
                  : _copyOfBuiltIn(builtIn!),
            );
          case _ThemeAction.export:
            _export(context, custom ?? _copyOfBuiltIn(builtIn!));
          case _ThemeAction.delete:
            if (custom != null) _delete(context, ref, custom, active);
          case _ThemeAction.hide:
            if (builtIn != null) _hidePreset(ref, builtIn);
        }
      },
      values: _ThemeAction.values,
      label: (a) => a.label(l10n),
      // A preset copies on edit, so a duplicate would repeat it. The preset in use stays.
      visible: (a) => switch (a) {
        _ThemeAction.duplicate || _ThemeAction.delete => custom != null,
        _ThemeAction.hide => builtIn != null && !active,
        _ => true,
      },
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final active = ref.watch(themeSchemeProvider).value;
    final customs = ref.watch(customThemesProvider).value ?? const [];
    final hidden = ref.watch(hiddenThemePresetsProvider).value ?? const {};
    final repo = ref.read(settingsRepositoryProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 14,
          runSpacing: 16,
          children: [
            for (final scheme in AppColorScheme.values)
              if (!hidden.contains(scheme) || active == scheme.name)
                ThemeCard(
                  colors: _builtInColors(scheme),
                  shapes: const ThemeShapes(),
                  label: scheme.label,
                  selected: active == scheme.name,
                  onTap: () => repo.setThemeScheme(scheme.name),
                  menu: manage
                      ? _menu(
                          context,
                          ref,
                          l10n,
                          builtIn: scheme,
                          active: active == scheme.name,
                        )
                      : null,
                ),
            for (final theme in customs)
              ThemeCard(
                colors: _customColors(theme),
                shapes: theme.shapes,
                label: theme.name,
                selected: active == theme.settingValue,
                onTap: () => repo.setThemeScheme(theme.settingValue),
                menu: manage
                    ? _menu(
                        context,
                        ref,
                        l10n,
                        custom: theme,
                        active: active == theme.settingValue,
                      )
                    : null,
              ),
          ],
        ),
        if (manage) ...[
          const SizedBox(height: 14),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.tonalIcon(
                onPressed: () => _edit(
                  context,
                  _startingTheme(active, customs, l10n.themesNewName),
                ),
                icon: const Icon(Icons.add, size: 18),
                label: Text(l10n.themesNew),
              ),
              if (hidden.isNotEmpty)
                TextButton(
                  onPressed: () => repo.setHiddenThemePresets({}),
                  child: Text(l10n.themesShowHidden(hidden.length)),
                ),
              OutlinedButton.icon(
                onPressed: () => _import(context, ref),
                icon: const Icon(Icons.file_open_outlined, size: 18),
                label: Text(l10n.themesImport),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
