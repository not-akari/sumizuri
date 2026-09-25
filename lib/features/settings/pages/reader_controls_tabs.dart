part of 'reader_controls_page.dart';

const _tabWidth = 720.0;

/// The keys of the reader: every action in its group, its keys shown on the
/// row. Tapping a row adds a key to it.
class _KeyboardTab extends StatefulWidget {
  const _KeyboardTab({
    required this.controls,
    required this.onAdd,
    required this.onRemove,
    required this.onReset,
    required this.onScroll,
  });

  final ValueChanged<ScrollSteps> onScroll;
  final ReaderControls controls;
  final ValueChanged<ReaderAction> onAdd;
  final void Function(ReaderAction, KeyChord) onRemove;
  final ValueChanged<ReaderAction> onReset;

  @override
  State<_KeyboardTab> createState() => _KeyboardTabState();
}

class _KeyboardTabState extends State<_KeyboardTab> {
  final _search = TextEditingController();
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  bool _differs(ReaderAction action) {
    final now = widget.controls.keys[action]!;
    final was = ReaderControls.defaults.keys[action]!;
    return now.length != was.length || !now.every(was.contains);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final controls = widget.controls;
    final cs = Theme.of(context).colorScheme;
    final matching = [
      for (final action in ReaderAction.values)
        if (_query.isEmpty ||
            readerActionLabel(l10n, action).toLowerCase().contains(_query))
          action,
    ];
    final gutter = context.layout.gutter;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _tabWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 96),
          children: [
            AnimatedSearchBar(
              controller: _search,
              hintText: l10n.controlsSearchHint,
              onChanged: (v) => setState(() => _query = v.trim().toLowerCase()),
              onClear: () => setState(() => _query = ''),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 10, 4, 0),
              child: Text(
                l10n.controlsKeyboardHint,
                style: Theme.of(context).textTheme.bodySmall
                    ?.copyWith(color: cs.onSurfaceVariant),
              ),
            ),
            if (matching.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(child: Text(l10n.controlsNoMatch)),
              ),
            for (final group in ReaderActionGroup.values) ...[
              if (matching.any((a) => readerActionGroup(a) == group))
                AppSectionLabel(label: readerActionGroupLabel(l10n, group)),
              for (final action in matching)
                if (readerActionGroup(action) == group)
                  AppListRow(
                    icon: readerActionIcon(action),
                    title: readerActionLabel(l10n, action),
                    subtitleWidget: Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: ChordChips(
                        chords: controls.keys[action]!,
                        onRemove: (chord) => widget.onRemove(action, chord),
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (_differs(action))
                          IconButton(
                            tooltip: l10n.readerControlsResetAction,
                            icon: const Icon(Icons.restart_alt_rounded),
                            onPressed: () => widget.onReset(action),
                          ),
                        IconButton(
                          tooltip: l10n.readerControlsAddKey,
                          icon: const Icon(Icons.add_rounded),
                          onPressed: () => widget.onAdd(action),
                        ),
                      ],
                    ),
                    onTap: () => widget.onAdd(action),
                  ),
            ],
            AppSectionLabel(label: l10n.readerControlsScrolling),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  ScrollStepSlider(
                    label: l10n.readerControlsArrowStep,
                    valueLabel: l10n.readerControlsPixels(
                      controls.scroll.arrowPixels.round(),
                    ),
                    value: controls.scroll.arrowPixels,
                    min: ScrollSteps.arrowRange.min,
                    max: ScrollSteps.arrowRange.max,
                    divisions: 29,
                    onChanged: (v) => widget.onScroll(
                      controls.scroll.copyWith(
                        arrowPixels: (v / 10).round() * 10.0,
                      ),
                    ),
                  ),
                  ScrollStepSlider(
                    label: l10n.readerControlsPageStep,
                    valueLabel: l10n.readerControlsPercentOfScreen(
                      (controls.scroll.pageFraction * 100).round(),
                    ),
                    value: controls.scroll.pageFraction,
                    min: ScrollSteps.fractionRange.min,
                    max: ScrollSteps.fractionRange.max,
                    divisions: 18,
                    onChanged: (v) => widget.onScroll(
                      controls.scroll.copyWith(
                        pageFraction: (v * 20).round() / 20,
                      ),
                    ),
                  ),
                  ScrollStepSlider(
                    label: l10n.readerControlsHoldSpeed,
                    valueLabel: l10n.readerControlsPxPerSecond(
                      controls.scroll.holdSpeed.round(),
                    ),
                    value: controls.scroll.holdSpeed,
                    min: ScrollSteps.holdRange.min,
                    max: ScrollSteps.holdRange.max,
                    divisions: 29,
                    onChanged: (v) => widget.onScroll(
                      controls.scroll.copyWith(
                        holdSpeed: (v / 100).round() * 100.0,
                      ),
                    ),
                  ),
                  _AutoSpeedSlider(
                    controls: controls,
                    onScroll: widget.onScroll,
                  ),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      l10n.readerControlsScrollNote,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tap zones: pick a ready-made layout, then adjust any zone or the size
/// of the bands.
class _TapZonesTab extends StatelessWidget {
  const _TapZonesTab({
    required this.controls,
    required this.layout,
    required this.onLayout,
    required this.onPick,
    required this.onPreset,
    required this.onGeometry,
    required this.onMirror,
    required this.onReset,
    required this.onScroll,
  });

  final ValueChanged<ScrollSteps> onScroll;
  final ReaderControls controls;
  final TapLayout layout;
  final ValueChanged<TapLayout> onLayout;
  final ValueChanged<int> onPick;
  final ValueChanged<TapPreset> onPreset;
  final ValueChanged<TapGeometry> onGeometry;
  final VoidCallback onMirror;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final geometry = controls.geometryOf(layout);
    final cs = Theme.of(context).colorScheme;
    final gutter = context.layout.gutter;

    double snap(double v) => (v * 20).round() / 20;
    String percent(double v) =>
        l10n.readerControlsPercentOfScreen((v * 100).round());

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: _tabWidth),
        child: ListView(
          padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 96),
          children: [
            AppChoice<TapLayout>.of(
              style: AppChoiceStyle.pills,
              values: TapLayout.values,
              label: (v) => v == TapLayout.paged
                  ? l10n.readerControlsPaged
                  : l10n.readerControlsContinuous,
              icon: (v) => v == TapLayout.paged
                  ? Icons.auto_stories_outlined
                  : Icons.swap_vert_rounded,
              value: layout,
              onChanged: onLayout,
            ),
            const SizedBox(height: 4),
            AppSectionLabel(label: l10n.controlsPresetsTitle),
            TapPresetPicker(
              controls: controls,
              layout: layout,
              onPick: onPreset,
            ),
            const SizedBox(height: 8),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 340),
                child: Column(
                  children: [
                    TapZoneGrid(
                      zones: controls.tapZones[layout]!,
                      geometry: geometry,
                      onPick: onPick,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.controlsTapHint,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onMirror,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: Text(l10n.controlsMirror),
                  ),
                  TextButton(
                    onPressed: onReset,
                    child: Text(l10n.readerControlsResetZones),
                  ),
                ],
              ),
            ),
            AppSectionLabel(label: l10n.controlsZoneSizeTitle),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  ScrollStepSlider(
                    label: l10n.controlsSideWidth,
                    valueLabel: percent(geometry.edgeX),
                    value: geometry.edgeX,
                    min: TapGeometry.range.min,
                    max: TapGeometry.range.max,
                    divisions: 6,
                    onChanged: (v) =>
                        onGeometry(geometry.copyWith(edgeX: snap(v))),
                  ),
                  ScrollStepSlider(
                    label: l10n.controlsEdgeHeight,
                    valueLabel: percent(geometry.edgeY),
                    value: geometry.edgeY,
                    min: TapGeometry.range.min,
                    max: TapGeometry.range.max,
                    divisions: 6,
                    onChanged: (v) =>
                        onGeometry(geometry.copyWith(edgeY: snap(v))),
                  ),
                ],
              ),
            ),
            AppSectionLabel(label: l10n.readerControlsScrolling),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Column(
                children: [
                  ScrollStepSlider(
                    label: l10n.readerControlsTapStep,
                    valueLabel: l10n.readerControlsPercentOfScreen(
                      (controls.scroll.tapFraction * 100).round(),
                    ),
                    value: controls.scroll.tapFraction,
                    min: ScrollSteps.fractionRange.min,
                    max: ScrollSteps.fractionRange.max,
                    divisions: 18,
                    onChanged: (v) => onScroll(
                      controls.scroll.copyWith(
                        tapFraction: (v * 20).round() / 20,
                      ),
                    ),
                  ),
                  _AutoSpeedSlider(controls: controls, onScroll: onScroll),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AutoSpeedSlider extends StatelessWidget {
  const _AutoSpeedSlider({required this.controls, required this.onScroll});

  final ReaderControls controls;
  final ValueChanged<ScrollSteps> onScroll;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ScrollStepSlider(
      label: l10n.readerControlsAutoSpeed,
      valueLabel: l10n.readerControlsPxPerSecond(
        controls.scroll.autoSpeed.round(),
      ),
      value: controls.scroll.autoSpeed,
      min: ScrollSteps.autoRange.min,
      max: ScrollSteps.autoRange.max,
      divisions: 59,
      onChanged: (v) => onScroll(
        controls.scroll.copyWith(autoSpeed: (v / 10).round() * 10.0),
      ),
    );
  }
}
