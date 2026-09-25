part of 'theme_editor_page.dart';

mixin _ThemeEditorControls on ConsumerState<ThemeEditorPage> {
  CustomTheme get _draft;
  TextEditingController get _name;
  _Mode get _mode;
  abstract _EditorTab _tab;
  abstract double _previewFraction;
  set _dirty(bool value);
  ThemeColors get _colors;
  void _update(CustomTheme theme);
  void _setMode(_Mode mode);
  void _setColor(String role, Color? color);
  Future<void> _pick(String role, Color current, ColorScheme resolved);
  String _roleLabel(AppLocalizations l10n, String role);
  Color _resolved(ColorScheme cs, String role);
  IconData _tabIcon(_EditorTab tab);
  String _tabLabel(AppLocalizations l10n, _EditorTab tab);

  void _setOptions(ThemeOptions options) =>
      _update(_draft.copyWith(options: options));

  /// The colours tab: which palette is being edited, then each colour.
  List<Widget> _colorsTab(AppLocalizations l10n, ThemeData preview) {
    final cs = Theme.of(context).colorScheme;
    return [
      EditorSection(
        title: l10n.themeEditorTabColors,
        onReset: () => _update(
          _editingDarkPalette
              ? _draft.copyWith(dark: const ThemeColors())
              : _draft.copyWith(light: const ThemeColors()),
        ),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppRowStyle.marginOf(context),
              0,
              AppRowStyle.marginOf(context),
              6,
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 10,
              runSpacing: 8,
              children: [
                Text(
                  l10n.themeEditorEditing,
                  style: TextStyle(fontSize: 12.5, color: cs.onSurfaceVariant),
                ),
                AppChoice<_Mode>(
                  expanded: false,
                  compact: true,
                  options: [
                    AppChoiceOption(
                      _Mode.light,
                      l10n.themeEditorLight,
                      icon: Icons.light_mode_outlined,
                    ),
                    AppChoiceOption(
                      _Mode.dark,
                      l10n.themeEditorDark,
                      icon: Icons.dark_mode_outlined,
                    ),
                    AppChoiceOption(
                      _Mode.oled,
                      l10n.themeEditorOled,
                      icon: Icons.brightness_2_outlined,
                    ),
                  ],
                  value: _mode,
                  onChanged: _setMode,
                ),
              ],
            ),
          ),
          for (final role in ThemeColors.roles)
            _colorRow(l10n, role, preview.colorScheme),
          Padding(
            padding: EdgeInsets.fromLTRB(
              AppRowStyle.marginOf(context),
              8,
              AppRowStyle.marginOf(context),
              0,
            ),
            child: Text(
              l10n.themeEditorAutoHint,
              style: TextStyle(fontSize: 12, color: cs.outline),
            ),
          ),
        ],
      ),
    ];
  }

  bool get _editingDarkPalette => _mode != _Mode.light;

  Widget _controls(AppLocalizations l10n, ThemeData preview) {
    final margin = AppRowStyle.marginOf(context);
    final body = switch (_tab) {
      _EditorTab.colors => _colorsTab(l10n, preview),
      _EditorTab.background => [
        BackgroundEditor(
          options: _draft.options,
          onChanged: _setOptions,
          primary: preview.colorScheme.primary,
          secondary: preview.colorScheme.secondary,
          tertiary: preview.colorScheme.tertiary,
        ),
      ],
      _EditorTab.shape => [
        ShapeControls(
          shapes: _draft.shapes,
          options: _draft.options,
          onShapesChanged: (s) => _update(_draft.copyWith(shapes: s)),
          onOptionsChanged: _setOptions,
        ),
      ],
      _EditorTab.type => [
        TypeControls(options: _draft.options, onChanged: _setOptions),
      ],
      _EditorTab.effects => [
        EffectsControls(options: _draft.options, onChanged: _setOptions),
      ],
      _EditorTab.progress => [
        ProgressControls(options: _draft.options, onChanged: _setOptions),
      ],
    };
    return AppRowStyle(
      child: ListView(
        padding: const EdgeInsets.only(bottom: 32),
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(margin, 4, margin, 12),
            child: TextField(
              controller: _name,
              onChanged: (_) => setState(() => _dirty = true),
              decoration: InputDecoration(
                labelText: l10n.themeEditorName,
                isDense: true,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: margin),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final tab in _EditorTab.values)
                  TogglePill(
                    icon: _tabIcon(tab),
                    label: _tabLabel(l10n, tab),
                    selected: tab == _tab,
                    onTap: () => setState(() => _tab = tab),
                  ),
              ],
            ),
          ),
          ...body,
        ],
      ),
    );
  }

  Widget _colorRow(AppLocalizations l10n, String role, ColorScheme resolvedCs) {
    final cs = Theme.of(context).colorScheme;
    final resolved = _resolved(resolvedCs, role);
    final explicit = _colors[role];
    return AppCard(
      tone: AppCardTone.inset,
      margin: EdgeInsets.fromLTRB(
        context.layout.gutter,
        4,
        context.layout.gutter,
        4,
      ),
      padding: const EdgeInsets.all(10),
      onTap: () => _pick(role, resolved, resolvedCs),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: resolved,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: cs.outline),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _roleLabel(l10n, role),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: explicit == null
                            ? cs.outline.withValues(alpha: 0.18)
                            : cs.primary.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        (explicit == null
                                ? l10n.themeEditorAuto
                                : l10n.themeEditorCustom)
                            .toUpperCase(),
                        style: TextStyle(
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          color: explicit == null
                              ? cs.onSurfaceVariant
                              : cs.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      colorToHex(resolved),
                      style: TextStyle(fontSize: 12, color: cs.outline),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (explicit != null)
            IconButton(
              icon: const Icon(Icons.restart_alt, size: 20),
              tooltip: l10n.themeEditorResetColor,
              onPressed: () => _setColor(role, null),
            ),
          Icon(Icons.edit_outlined, size: 20, color: cs.primary),
        ],
      ),
    );
  }

  Widget _resizeHandle(AppLocalizations l10n, double screenHeight) {
    final cs = Theme.of(context).colorScheme;
    return Tooltip(
      message: l10n.themeEditorPreviewResize,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onVerticalDragUpdate: (d) => setState(() {
          _previewFraction = (_previewFraction + d.delta.dy / screenHeight)
              .clamp(0.2, 0.7);
        }),
        onDoubleTap: () => setState(
          () => _previewFraction = _previewFraction < 0.5 ? 0.7 : 0.4,
        ),
        child: SizedBox(
          height: 28,
          width: double.infinity,
          child: Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: cs.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
