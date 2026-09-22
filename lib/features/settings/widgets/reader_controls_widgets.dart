import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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

class TapZoneGrid extends StatelessWidget {
  const TapZoneGrid({super.key, required this.zones, required this.onPick});

  final List<ReaderAction?> zones;
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
            box.maxWidth * 0.3,
            box.maxWidth * 0.4,
            box.maxWidth * 0.3,
          ];
          final heights = [
            box.maxHeight * 0.3,
            box.maxHeight * 0.4,
            box.maxHeight * 0.3,
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
    return SizedBox(
      width: width,
      height: height,
      child: Padding(
        padding: const EdgeInsets.all(3),
        child: Material(
          color: action == null
              ? cs.surfaceContainerLow
              : cs.primaryContainer.withValues(alpha: 0.55),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: BorderSide(color: cs.outlineVariant),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => onPick(index),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Text(
                  action == null
                      ? l10n.readerControlsNothing
                      : readerActionLabel(l10n, action),
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: action == null ? cs.onSurfaceVariant : cs.onSurface,
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

Future<({bool picked, ReaderAction? action})> pickTapAction(
  BuildContext context,
  ReaderAction? current,
) async {
  final l10n = AppLocalizations.of(context)!;
  final result = await showModalBottomSheet<Object>(
    context: context,
    showDragHandle: true,
    builder: (sheet) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
            child: Text(
              l10n.readerControlsPickAction,
              style: Theme.of(sheet).textTheme.titleMedium,
            ),
          ),
          for (final action in ReaderAction.values)
            ListTile(
              title: Text(readerActionLabel(l10n, action)),
              trailing: action == current ? const Icon(Icons.check) : null,
              onTap: () => Navigator.of(sheet).pop(action),
            ),
          ListTile(
            title: Text(l10n.readerControlsNothing),
            trailing: current == null ? const Icon(Icons.check) : null,
            onTap: () => Navigator.of(sheet).pop(false),
          ),
        ],
      ),
    ),
  );
  if (result is ReaderAction) return (picked: true, action: result);
  if (result == false) return (picked: true, action: null);
  return (picked: false, action: null);
}
