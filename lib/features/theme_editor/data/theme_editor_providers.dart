import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/theme_editor/data/custom_theme_store.dart';

class CustomThemesNotifier extends AsyncNotifier<List<CustomTheme>> {
  static const _store = CustomThemeStore();

  @override
  Future<List<CustomTheme>> build() => _store.loadAll();

  List<CustomTheme> _sorted(List<CustomTheme> themes) =>
      [...themes]
        ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

  Future<void> save(CustomTheme theme) async {
    await _store.save(theme);
    final current = state.value ?? const [];
    state = AsyncData(
      _sorted([...current.where((t) => t.id != theme.id), theme]),
    );
  }

  Future<void> delete(String id) async {
    await _store.delete(id);
    state = AsyncData(
      (state.value ?? const []).where((t) => t.id != id).toList(),
    );
  }

  /// Adds an imported theme with a fresh id if that id exists, so imports never overwrite.
  Future<CustomTheme> add(CustomTheme theme) async {
    final exists = (state.value ?? const []).any((t) => t.id == theme.id);
    final toSave = exists ? theme.copyWith(id: newThemeId(theme.name)) : theme;
    await save(toSave);
    return toSave;
  }
}

final customThemesProvider =
    AsyncNotifierProvider<CustomThemesNotifier, List<CustomTheme>>(
      CustomThemesNotifier.new,
    );

/// The active custom theme, or null when a preset is selected or the custom theme is gone.
final activeCustomThemeProvider = Provider<CustomTheme?>((ref) {
  final setting = ref.watch(themeSchemeProvider).value;
  if (setting == null || !setting.startsWith(customThemePrefix)) return null;
  final id = setting.substring(customThemePrefix.length);
  final themes = ref.watch(customThemesProvider).value ?? const [];
  for (final theme in themes) {
    if (theme.id == id) return theme;
  }
  return null;
});
