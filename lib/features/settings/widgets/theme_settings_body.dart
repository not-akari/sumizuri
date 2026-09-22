import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/theme_editor/widgets/theme_gallery.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ThemeModeSelector extends ConsumerWidget {
  const ThemeModeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final preference =
        ref.watch(darkModePreferenceProvider).value ??
        AppDarkModePreference.system;
    final amoled = ref.watch(amoledDarkProvider).value ?? false;
    final repository = ref.read(settingsRepositoryProvider);

    // OLED is dark mode with pure black, so it is a dark preference plus the amoled flag.
    final selected = switch (preference) {
      AppDarkModePreference.system => 0,
      AppDarkModePreference.light => 1,
      AppDarkModePreference.dark => amoled ? 3 : 2,
    };

    void choose(int index) {
      switch (index) {
        case 0:
          repository.setDarkModePreference(AppDarkModePreference.system);
        case 1:
          repository.setDarkModePreference(AppDarkModePreference.light);
          repository.setAmoledDark(false);
        case 2:
          repository.setDarkModePreference(AppDarkModePreference.dark);
          repository.setAmoledDark(false);
        default:
          repository.setDarkModePreference(AppDarkModePreference.dark);
          repository.setAmoledDark(true);
      }
    }

    return AppChoice<int>(
      options: [
        AppChoiceOption(
          0,
          l10n.themeModeSystem,
          icon: Icons.brightness_auto_outlined,
        ),
        AppChoiceOption(
          1,
          l10n.themeModeLight,
          icon: Icons.light_mode_outlined,
        ),
        AppChoiceOption(2, l10n.themeModeDark, icon: Icons.dark_mode_outlined),
        AppChoiceOption(
          3,
          l10n.themeModeAmoled,
          icon: Icons.nightlight_outlined,
        ),
      ],
      value: selected,
      onChanged: choose,
    );
  }
}

class ThemeGalleryConnected extends ConsumerWidget {
  const ThemeGalleryConnected({super.key, this.manage = false});

  final bool manage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preference =
        ref.watch(darkModePreferenceProvider).value ??
        AppDarkModePreference.system;
    final amoled = ref.watch(amoledDarkProvider).value ?? false;
    final intensity =
        ref.watch(colorIntensityProvider).value ?? ColorIntensity.medium;
    final wantsDark =
        preference == AppDarkModePreference.dark ||
        (preference == AppDarkModePreference.system &&
            MediaQuery.platformBrightnessOf(context) == Brightness.dark);
    return ThemeGallery(
      wantsDark: wantsDark,
      amoled: amoled,
      intensity: intensity,
      manage: manage,
    );
  }
}
