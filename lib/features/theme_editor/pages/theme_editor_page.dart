import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/theming/app_theme.dart';
import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_scaffold.dart';
import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';
import 'package:sumizuri/features/theme_editor/data/theme_editor_providers.dart';
import 'package:sumizuri/features/theme_editor/widgets/color_picker_dialog.dart';
import 'package:sumizuri/features/theme_editor/widgets/option_controls.dart';
import 'package:sumizuri/features/theme_editor/widgets/preview_screens.dart';
import 'package:sumizuri/features/theme_editor/widgets/shape_controls.dart';
import 'package:sumizuri/features/theme_editor/widgets/theme_preview.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

part 'theme_editor_controls.dart';

enum _Mode { light, dark, oled }

enum _EditorTab { colors, components, type, effects }

class ThemeEditorPage extends ConsumerStatefulWidget {
  const ThemeEditorPage({super.key, required this.theme});

  final CustomTheme theme;

  @override
  ConsumerState<ThemeEditorPage> createState() => _ThemeEditorPageState();
}

class _ThemeEditorPageState extends ConsumerState<ThemeEditorPage>
    with _ThemeEditorControls {
  static const _wideBreakpoint = 900.0;
  static const _controlsWidth = 420.0;

  @override
  late CustomTheme _draft = widget.theme;
  @override
  late final _name = TextEditingController(text: widget.theme.name);
  // Starts in dark so the editor does not open blindingly bright.
  @override
  late _Mode _mode = widget.theme.options.effects.oledDark
      ? _Mode.oled
      : _Mode.dark;
  @override
  _EditorTab _tab = _EditorTab.colors;
  @override
  double _previewFraction = 0.4;
  bool _dirty = false;
  PreviewScreen _screen = PreviewScreen.library;

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  bool get _editingDark => _mode != _Mode.light;

  @override
  void _setMode(_Mode mode) {
    setState(() => _mode = mode);
    if (mode == _Mode.light) return;
    final oled = mode == _Mode.oled;
    if (_draft.options.effects.oledDark == oled) return;
    _update(
      _draft.copyWith(
        options: _draft.options.copyWith(
          effects: _draft.options.effects.copyWith(oledDark: oled),
        ),
      ),
    );
  }

  @override
  ThemeColors get _colors => _editingDark ? _draft.dark : _draft.light;

  @override
  void _update(CustomTheme theme) => setState(() {
    _draft = theme;
    _dirty = true;
  });

  @override
  void _setColor(String role, Color? color) {
    final updated = _colors.withRole(role, color);
    _update(
      _editingDark
          ? _draft.copyWith(dark: updated)
          : _draft.copyWith(light: updated),
    );
  }

  @override
  Future<void> _pick(String role, Color current, ColorScheme resolved) async {
    final picked = await showColorPickerDialog(
      context,
      current,
      suggestions: [
        for (final r in ThemeColors.roles)
          if (r != role) _resolved(resolved, r),
      ],
    );
    if (picked != null) _setColor(role, picked);
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final theme = _draft.copyWith(name: name.isEmpty ? _draft.name : name);
    await ref.read(customThemesProvider.notifier).save(theme);
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmDiscard() async {
    final l10n = AppLocalizations.of(context)!;
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(l10n.themeEditorDiscardTitle),
        content: Text(l10n.themeEditorDiscardMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text(l10n.browseAddWarningCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text(l10n.themeEditorDiscard),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  @override
  String _roleLabel(AppLocalizations l10n, String role) => switch (role) {
    'primary' => l10n.themeRolePrimary,
    'primaryContainer' => l10n.themeRolePrimaryContainer,
    'secondary' => l10n.themeRoleSecondary,
    'tertiary' => l10n.themeRoleTertiary,
    'error' => l10n.themeRoleError,
    _ => l10n.themeRoleSurface,
  };

  @override
  Color _resolved(ColorScheme cs, String role) => switch (role) {
    'primary' => cs.primary,
    'primaryContainer' => cs.primaryContainer,
    'secondary' => cs.secondary,
    'tertiary' => cs.tertiary,
    'error' => cs.error,
    _ => cs.surface,
  };

  @override
  IconData _tabIcon(_EditorTab tab) => switch (tab) {
    _EditorTab.colors => Icons.palette_outlined,
    _EditorTab.components => Icons.widgets_outlined,
    _EditorTab.type => Icons.text_fields_rounded,
    _EditorTab.effects => Icons.auto_awesome_outlined,
  };

  @override
  String _tabLabel(AppLocalizations l10n, _EditorTab tab) => switch (tab) {
    _EditorTab.colors => l10n.themeEditorTabColors,
    _EditorTab.components => l10n.themeEditorTabShape,
    _EditorTab.type => l10n.themeEditorTabType,
    _EditorTab.effects => l10n.themeEditorTabEffects,
  };

  void _expandPreview(ThemeData preview) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ThemePreviewPage(theme: preview, initial: _screen),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final brightness = _editingDark ? Brightness.dark : Brightness.light;
    final preview = AppTheme.custom(_draft, brightness: brightness);
    final size = MediaQuery.sizeOf(context);
    final isWide = size.width >= _wideBreakpoint;

    final picker = Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      child: PreviewScreenPicker(
        screen: _screen,
        onChanged: (s) => setState(() => _screen = s),
        onExpand: () => _expandPreview(preview),
      ),
    );
    final frame = ThemePreviewFrame(
      theme: preview,
      screen: _screen,
      onScreenChanged: (s) => setState(() => _screen = s),
    );

    return PopScope(
      canPop: !_dirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final navigator = Navigator.of(context);
        if (await _confirmDiscard()) navigator.pop();
      },
      child: AmbientScaffold(
        title: Text(l10n.themeEditorTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check, size: 18),
              label: Text(l10n.themeEditorSave),
            ),
          ),
        ],
        body: isWide
            ? Row(
                children: [
                  SizedBox(
                    width: _controlsWidth,
                    child: _controls(l10n, preview),
                  ),
                  VerticalDivider(
                    width: 1,
                    color: Theme.of(context).colorScheme.outlineVariant,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        picker,
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            child: Center(
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  maxWidth: 480,
                                ),
                                child: frame,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                children: [
                  picker,
                  SizedBox(
                    height: size.height * _previewFraction,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                      child: frame,
                    ),
                  ),
                  _resizeHandle(l10n, size.height),
                  Expanded(child: _controls(l10n, preview)),
                ],
              ),
      ),
    );
  }
}
