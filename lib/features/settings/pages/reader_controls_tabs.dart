part of 'reader_controls_page.dart';

class _KeyboardTab extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        8,
        context.layout.gutter,
        96,
      ),
      children: [
        for (final action in ReaderAction.values) ...[
          AppListRow(
            icon: _iconFor(action),
            title: readerActionLabel(l10n, action),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_differs(action))
                  TextButton(
                    onPressed: () => onReset(action),
                    child: Text(l10n.readerControlsResetAction),
                  ),
                IconButton(
                  tooltip: l10n.readerControlsAddKey,
                  icon: const Icon(Icons.add),
                  onPressed: () => onAdd(action),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(56, 0, 0, 12),
            child: controls.keys[action]!.isEmpty
                ? Text(
                    l10n.readerControlsNotSet,
                    style: Theme.of(context).textTheme.bodySmall,
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    children: [
                      for (final chord in controls.keys[action]!)
                        InputChip(
                          label: Text(chordLabel(chord)),
                          onDeleted: () => onRemove(action, chord),
                        ),
                    ],
                  ),
          ),
        ],
        const SizedBox(height: 8),
        Text(
          l10n.readerControlsScrolling,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        ScrollStepSlider(
          label: l10n.readerControlsArrowStep,
          valueLabel: l10n.readerControlsPixels(
            controls.scroll.arrowPixels.round(),
          ),
          value: controls.scroll.arrowPixels,
          min: ScrollSteps.arrowRange.min,
          max: ScrollSteps.arrowRange.max,
          divisions: 29,
          onChanged: (v) => onScroll(
            controls.scroll.copyWith(arrowPixels: (v / 10).round() * 10.0),
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
          onChanged: (v) => onScroll(
            controls.scroll.copyWith(pageFraction: (v * 20).round() / 20),
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
          onChanged: (v) => onScroll(
            controls.scroll.copyWith(holdSpeed: (v / 100).round() * 100.0),
          ),
        ),
        _AutoSpeedSlider(controls: controls, onScroll: onScroll),
        Text(
          l10n.readerControlsScrollNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }

  bool _differs(ReaderAction action) {
    final now = controls.keys[action]!;
    final was = ReaderControls.defaults.keys[action]!;
    return now.length != was.length || !now.every(was.contains);
  }

  IconData _iconFor(ReaderAction action) => switch (action) {
    ReaderAction.nextPage => Icons.skip_next_outlined,
    ReaderAction.previousPage => Icons.skip_previous_outlined,
    ReaderAction.pageRight => Icons.arrow_forward,
    ReaderAction.pageLeft => Icons.arrow_back,
    ReaderAction.scrollDown => Icons.keyboard_arrow_down,
    ReaderAction.scrollUp => Icons.keyboard_arrow_up,
    ReaderAction.toggleOverlays => Icons.visibility_outlined,
    ReaderAction.nextChapter => Icons.last_page,
    ReaderAction.previousChapter => Icons.first_page,
    ReaderAction.openSettings => Icons.tune,
    ReaderAction.toggleAutoScroll => Icons.play_circle_outline,
    ReaderAction.autoScrollFaster => Icons.fast_forward_outlined,
    ReaderAction.autoScrollSlower => Icons.fast_rewind_outlined,
    ReaderAction.openInBrowser => Icons.open_in_new,
    ReaderAction.toggleBookmark => Icons.bookmark_border,
  };
}

class _TapZonesTab extends StatelessWidget {
  const _TapZonesTab({
    required this.controls,
    required this.layout,
    required this.onLayout,
    required this.onPick,
    required this.onReset,
    required this.onScroll,
  });

  final ValueChanged<ScrollSteps> onScroll;
  final ReaderControls controls;
  final TapLayout layout;
  final ValueChanged<TapLayout> onLayout;
  final ValueChanged<int> onPick;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListView(
      padding: EdgeInsets.fromLTRB(
        context.layout.gutter,
        8,
        context.layout.gutter,
        96,
      ),
      children: [
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              label: Text(l10n.readerControlsPaged),
              selected: layout == TapLayout.paged,
              onSelected: (_) => onLayout(TapLayout.paged),
            ),
            ChoiceChip(
              label: Text(l10n.readerControlsContinuous),
              selected: layout == TapLayout.continuous,
              onSelected: (_) => onLayout(TapLayout.continuous),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 360),
            child: TapZoneGrid(
              zones: controls.tapZones[layout]!,
              onPick: onPick,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.readerControlsTapNote,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 8),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton(
            onPressed: onReset,
            child: Text(l10n.readerControlsResetZones),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          l10n.readerControlsScrolling,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
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
            controls.scroll.copyWith(tapFraction: (v * 20).round() / 20),
          ),
        ),
        _AutoSpeedSlider(controls: controls, onScroll: onScroll),
      ],
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
