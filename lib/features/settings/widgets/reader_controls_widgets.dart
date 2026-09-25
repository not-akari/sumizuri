import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/reader/models/reader_controls.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

String readerActionLabel(AppLocalizations l10n, ReaderAction action) =>
    switch (action) {
      ReaderAction.nextPage => l10n.readerActionNextPage,
      ReaderAction.previousPage => l10n.readerActionPreviousPage,
      ReaderAction.pageRight => l10n.readerActionPageRight,
      ReaderAction.pageLeft => l10n.readerActionPageLeft,
      ReaderAction.scrollDown => l10n.readerActionScrollDown,
      ReaderAction.scrollUp => l10n.readerActionScrollUp,
      ReaderAction.toggleOverlays => l10n.readerActionToggleOverlays,
      ReaderAction.nextChapter => l10n.readerActionNextChapter,
      ReaderAction.previousChapter => l10n.readerActionPreviousChapter,
      ReaderAction.openSettings => l10n.readerActionOpenSettings,
      ReaderAction.toggleAutoScroll => l10n.readerActionToggleAutoScroll,
      ReaderAction.autoScrollFaster => l10n.readerActionAutoScrollFaster,
      ReaderAction.autoScrollSlower => l10n.readerActionAutoScrollSlower,
      ReaderAction.openInBrowser => l10n.readerActionOpenInBrowser,
      ReaderAction.toggleBookmark => l10n.readerActionToggleBookmark,
    };

IconData readerActionIcon(ReaderAction action) => switch (action) {
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

/// The kinds the actions are sorted into on the page, so a long list can be scanned.
enum ReaderActionGroup { turning, scrolling, chapters, reader, autoScroll }

ReaderActionGroup readerActionGroup(ReaderAction action) => switch (action) {
  ReaderAction.nextPage ||
  ReaderAction.previousPage ||
  ReaderAction.pageRight ||
  ReaderAction.pageLeft => ReaderActionGroup.turning,
  ReaderAction.scrollDown ||
  ReaderAction.scrollUp => ReaderActionGroup.scrolling,
  ReaderAction.nextChapter ||
  ReaderAction.previousChapter => ReaderActionGroup.chapters,
  ReaderAction.toggleOverlays ||
  ReaderAction.openSettings ||
  ReaderAction.toggleBookmark ||
  ReaderAction.openInBrowser => ReaderActionGroup.reader,
  ReaderAction.toggleAutoScroll ||
  ReaderAction.autoScrollFaster ||
  ReaderAction.autoScrollSlower => ReaderActionGroup.autoScroll,
};

String readerActionGroupLabel(AppLocalizations l10n, ReaderActionGroup group) =>
    switch (group) {
      ReaderActionGroup.turning => l10n.controlsGroupTurning,
      ReaderActionGroup.scrolling => l10n.controlsGroupScrolling,
      ReaderActionGroup.chapters => l10n.controlsGroupChapters,
      ReaderActionGroup.reader => l10n.controlsGroupReader,
      ReaderActionGroup.autoScroll => l10n.controlsGroupAutoScroll,
    };

/// Whether a tap in [layout] can do [action] at all: turning left or right
/// means nothing in a scrolling chapter, and scrolling nothing in a paged one.
bool readerActionFitsLayout(ReaderAction action, TapLayout layout) =>
    switch (action) {
      ReaderAction.pageLeft ||
      ReaderAction.pageRight => layout == TapLayout.paged,
      ReaderAction.scrollUp ||
      ReaderAction.scrollDown ||
      ReaderAction.toggleAutoScroll ||
      ReaderAction.autoScrollFaster ||
      ReaderAction.autoScrollSlower => layout == TapLayout.continuous,
      _ => true,
    };

String tapPresetLabel(AppLocalizations l10n, TapPreset preset) =>
    switch (preset) {
      TapPreset.standard => l10n.tapPresetStandard,
      TapPreset.edges => l10n.tapPresetEdges,
      TapPreset.lShaped => l10n.tapPresetLShaped,
      TapPreset.wideCenter => l10n.tapPresetWideCenter,
      TapPreset.menuOnly => l10n.tapPresetMenuOnly,
    };

String chordLabel(KeyChord chord) {
  final key = LogicalKeyboardKey(chord.keyId);
  var name = key.keyLabel.trim();
  if (key == LogicalKeyboardKey.space) name = 'Space';
  if (name.isEmpty) name = key.debugName ?? 'Key ${chord.keyId}';
  if (name.length == 1) name = name.toUpperCase();
  return [
    if (chord.ctrl) 'Ctrl',
    if (chord.shift) 'Shift',
    if (chord.alt) 'Alt',
    if (chord.meta) 'Meta',
    name,
  ].join(' + ');
}

bool _isModifier(LogicalKeyboardKey key) =>
    key == LogicalKeyboardKey.controlLeft ||
    key == LogicalKeyboardKey.controlRight ||
    key == LogicalKeyboardKey.shiftLeft ||
    key == LogicalKeyboardKey.shiftRight ||
    key == LogicalKeyboardKey.altLeft ||
    key == LogicalKeyboardKey.altRight ||
    key == LogicalKeyboardKey.metaLeft ||
    key == LogicalKeyboardKey.metaRight ||
    key == LogicalKeyboardKey.capsLock ||
    key == LogicalKeyboardKey.numLock ||
    key == LogicalKeyboardKey.scrollLock ||
    key == LogicalKeyboardKey.fn;

Future<KeyChord?> recordKeyChord(
  BuildContext context, {
  required String title,
  required String? Function(KeyChord) usedBy,
}) {
  return showDialog<KeyChord>(
    context: context,
    builder: (_) => _KeyRecorderDialog(title: title, usedBy: usedBy),
  );
}

class _KeyRecorderDialog extends StatefulWidget {
  const _KeyRecorderDialog({required this.title, required this.usedBy});

  final String title;

  final String? Function(KeyChord) usedBy;

  @override
  State<_KeyRecorderDialog> createState() => _KeyRecorderDialogState();
}

class _KeyRecorderDialogState extends State<_KeyRecorderDialog> {
  final _focus = FocusNode();
  KeyChord? _pending;
  String? _conflict;

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent ||
        _pending != null ||
        _isModifier(event.logicalKey)) {
      return KeyEventResult.handled;
    }
    final keyboard = HardwareKeyboard.instance;
    final chord = KeyChord(
      event.logicalKey.keyId,
      ctrl: keyboard.isControlPressed,
      shift: keyboard.isShiftPressed,
      alt: keyboard.isAltPressed,
      meta: keyboard.isMetaPressed,
    );
    final owner = widget.usedBy(chord);
    if (owner == null) {
      Navigator.of(context).pop(chord);
    } else {
      setState(() {
        _pending = chord;
        _conflict = owner;
      });
    }
    return KeyEventResult.handled;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pending = _pending;
    final conflict = _conflict;
    return Focus(
      focusNode: _focus,
      autofocus: true,
      onKeyEvent: _onKey,
      child: AlertDialog(
        title: Text(widget.title),
        content: pending == null || conflict == null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l10n.readerControlsPressKey),
                  const SizedBox(height: 8),
                  Text(
                    l10n.readerControlsPressKeyHint,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              )
            : Text(
                l10n.readerControlsAlreadyUsed(chordLabel(pending), conflict),
              ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          if (pending != null)
            FilledButton(
              onPressed: () => Navigator.of(context).pop(pending),
              child: Text(l10n.readerControlsMove),
            ),
        ],
      ),
    );
  }
}

/// The keys of an action as chips, each with a way to take it away, or a note
/// that none is set.
class ChordChips extends StatelessWidget {
  const ChordChips({super.key, required this.chords, required this.onRemove});

  final List<KeyChord> chords;
  final ValueChanged<KeyChord> onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (chords.isEmpty) {
      return Text(
        l10n.readerControlsNotSet,
        style: Theme.of(context).textTheme.bodySmall,
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: [
        for (final chord in chords)
          InputChip(
            visualDensity: VisualDensity.compact,
            label: Text(chordLabel(chord)),
            onDeleted: () => onRemove(chord),
          ),
      ],
    );
  }
}

class ScrollStepSlider extends StatelessWidget {
  const ScrollStepSlider({
    super.key,
    required this.label,
    required this.valueLabel,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  final String label;
  final String valueLabel;
  final double value;
  final double min;
  final double max;
  final int divisions;
  final ValueChanged<double> onChanged;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: text.bodyMedium),
            Text(valueLabel, style: text.bodySmall),
          ],
        ),
        Slider(
          value: value.clamp(min, max),
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }
}

/// How a zone is drawn. What a zone does is told by colour that stands out
/// from the page in any theme: the accent for turning and scrolling, the
/// second accent for showing the controls, and an empty outline for nothing.
({Color fill, Color border}) _zoneStyle(ColorScheme cs, ReaderAction? action) {
  if (action == null) {
    return (fill: Colors.transparent, border: cs.outlineVariant);
  }
  final color = readerActionGroup(action) == ReaderActionGroup.reader
      ? cs.tertiary
      : cs.primary;
  return (
    fill: color.withValues(alpha: 0.32),
    border: color.withValues(alpha: 0.75),
  );
}

/// The nine tap zones of a layout, drawn at the size they really are on the
/// screen. Tapping one asks what it should do.
class TapZoneGrid extends StatelessWidget {
  const TapZoneGrid({
    super.key,
    required this.zones,
    required this.geometry,
    required this.onPick,
  });

  final List<ReaderAction?> zones;
  final TapGeometry geometry;
  final ValueChanged<int> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 0.72,
      child: LayoutBuilder(
        builder: (context, box) {
          final widths = [
            box.maxWidth * geometry.edgeX,
            box.maxWidth * (1 - 2 * geometry.edgeX),
            box.maxWidth * geometry.edgeX,
          ];
          final heights = [
            box.maxHeight * geometry.edgeY,
            box.maxHeight * (1 - 2 * geometry.edgeY),
            box.maxHeight * geometry.edgeY,
          ];
          return Column(
            children: [
              for (var row = 0; row < 3; row++)
                Row(
                  children: [
                    for (var col = 0; col < 3; col++)
                      _cell(
                        context,
                        cs,
                        l10n,
                        index: row * 3 + col,
                        width: widths[col],
                        height: heights[row],
                      ),
                  ],
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _cell(
    BuildContext context,
    ColorScheme cs,
    AppLocalizations l10n, {
    required int index,
    required double width,
    required double height,
  }) {
    final action = zones[index];
    final radius = context.shapes.item.radius;
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: _zoneStyle(cs, action).fill,
          shape: RoundedRectangleBorder(
            borderRadius: radius,
            side: BorderSide(color: _zoneStyle(cs, action).border),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onPick(index),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        action == null
                            ? Icons.block_outlined
                            : readerActionIcon(action),
                        size: 20,
                        color: action == null ? cs.outline : cs.onSurface,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        action == null
                            ? l10n.readerControlsNothing
                            : readerActionLabel(l10n, action),
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: action == null
                              ? cs.onSurfaceVariant
                              : cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// A small picture of a tap layout, for choosing between them.
class _MiniZones extends StatelessWidget {
  const _MiniZones({required this.zones, required this.geometry});

  final List<ReaderAction?> zones;
  final TapGeometry geometry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final middleX = 1 - 2 * geometry.edgeX;
    final middleY = 1 - 2 * geometry.edgeY;
    Widget cell(int i) => Padding(
      padding: const EdgeInsets.all(1),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _zoneStyle(cs, zones[i]).fill,
          border: Border.all(color: _zoneStyle(cs, zones[i]).border),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
    );
    Widget row(int r, double height) => Expanded(
      flex: (height * 1000).round(),
      child: Row(
        // Tall as the row, so each cell has a size to be painted at.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(flex: (geometry.edgeX * 1000).round(), child: cell(r * 3)),
          Expanded(flex: (middleX * 1000).round(), child: cell(r * 3 + 1)),
          Expanded(
            flex: (geometry.edgeX * 1000).round(),
            child: cell(r * 3 + 2),
          ),
        ],
      ),
    );
    return Column(
      children: [
        row(0, geometry.edgeY),
        row(1, middleY),
        row(2, geometry.edgeY),
      ],
    );
  }
}

/// Whether [layout] is laid out as [preset] says right now.
bool tapPresetActive(
  ReaderControls controls,
  TapLayout layout,
  TapPreset preset,
) {
  final made = controls.withPreset(layout, preset);
  return listEquals(made.tapZones[layout], controls.tapZones[layout]) &&
      made.geometryOf(layout) == controls.geometryOf(layout);
}

/// A row of tap layouts, each drawn small, to pick from.
class TapPresetPicker extends StatelessWidget {
  const TapPresetPicker({
    super.key,
    required this.controls,
    required this.layout,
    required this.onPick,
  });

  final ReaderControls controls;
  final TapLayout layout;
  final ValueChanged<TapPreset> onPick;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    return SizedBox(
      height: 132,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: TapPreset.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final preset = TapPreset.values[index];
          final made = controls.withPreset(layout, preset);
          final active = tapPresetActive(controls, layout, preset);
          return SizedBox(
            width: 84,
            child: Material(
              color: active
                  ? cs.primaryContainer.withValues(alpha: 0.35)
                  : Colors.transparent,
              shape: RoundedRectangleBorder(
                borderRadius: context.shapes.item.radius,
                side: BorderSide(
                  color: active ? cs.primary : cs.outlineVariant,
                  width: active ? 2 : 1,
                ),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onPick(preset),
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: Column(
                    children: [
                      Expanded(
                        child: AspectRatio(
                          aspectRatio: 0.72,
                          child: _MiniZones(
                            zones: made.tapZones[layout]!,
                            geometry: made.geometryOf(layout),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tapPresetLabel(l10n, preset),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Asks what a tap zone should do, in groups. Only what a tap can do in
/// [layout] is offered, apart from what the zone already does.
Future<({bool picked, ReaderAction? action})> pickTapAction(
  BuildContext context,
  ReaderAction? current,
  TapLayout layout,
) async {
  final l10n = AppLocalizations.of(context)!;
  final cs = Theme.of(context).colorScheme;
  final result = await showAppSheet<Object>(
    context,
    builder: (sheet) => AppSheet(
      title: l10n.readerControlsPickAction,
      children: [
        for (final group in ReaderActionGroup.values) ...[
          if (ReaderAction.values.any(
            (a) =>
                readerActionGroup(a) == group &&
                (readerActionFitsLayout(a, layout) || a == current),
          ))
            AppSectionLabel(label: readerActionGroupLabel(l10n, group)),
          for (final action in ReaderAction.values)
            if (readerActionGroup(action) == group &&
                (readerActionFitsLayout(action, layout) || action == current))
              AppListRow(
                icon: readerActionIcon(action),
                iconColor: action == current ? cs.primary : null,
                title: readerActionLabel(l10n, action),
                trailing: action == current
                    ? Icon(Icons.check_rounded, color: cs.primary)
                    : null,
                onTap: () => Navigator.of(sheet).pop(action),
              ),
        ],
        const SizedBox(height: 4),
        AppListRow(
          icon: Icons.block_outlined,
          title: l10n.readerControlsNothing,
          trailing: current == null
              ? Icon(Icons.check_rounded, color: cs.primary)
              : null,
          onTap: () => Navigator.of(sheet).pop(false),
        ),
      ],
    ),
  );
  if (result is ReaderAction) return (picked: true, action: result);
  if (result == false) return (picked: true, action: null);
  return (picked: false, action: null);
}
