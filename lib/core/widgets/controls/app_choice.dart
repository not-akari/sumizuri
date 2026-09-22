import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/controls/toggle_pill.dart';

/// How an [AppChoice] shows its options.
enum AppChoiceStyle {
  /// Segments when they fit on one line, a menu when they do not.
  auto,
  segments,

  /// Pills that wrap onto more lines, for a short list that should all be seen at once.
  pills,
  menu,
}

/// One option of an [AppChoice].
class AppChoiceOption<T> {
  const AppChoiceOption(this.value, this.label, {this.icon});

  final T value;
  final String label;
  final IconData? icon;
}

/// The one way to pick a single option, drawn as segments, pills or a menu.
class AppChoice<T> extends StatelessWidget {
  const AppChoice({
    super.key,
    required this.options,
    required this.value,
    required this.onChanged,
    this.style = AppChoiceStyle.auto,
    this.title,
    this.hint,
    this.labelText,
    this.placeholder,
    this.onCleared,
    this.clearLabel,
    this.expanded = true,
    this.padded = false,
    this.compact = false,
  });

  /// One option for each of [values], with its look decided per value by [label] and [icon].
  factory AppChoice.of({
    Key? key,
    required List<T> values,
    required String Function(T value) label,
    required T? value,
    required ValueChanged<T>? onChanged,
    IconData? Function(T value)? icon,
    AppChoiceStyle style = AppChoiceStyle.auto,
    String? title,
    String? hint,
    String? labelText,
    String? placeholder,
    VoidCallback? onCleared,
    String? clearLabel,
    bool expanded = true,
    bool padded = false,
    bool compact = false,
  }) => AppChoice(
    key: key,
    options: [
      for (final v in values) AppChoiceOption(v, label(v), icon: icon?.call(v)),
    ],
    value: value,
    onChanged: onChanged,
    style: style,
    title: title,
    hint: hint,
    labelText: labelText,
    placeholder: placeholder,
    onCleared: onCleared,
    clearLabel: clearLabel,
    expanded: expanded,
    padded: padded,
    compact: compact,
  );

  /// The same, from a map of value to label.
  factory AppChoice.map({
    Key? key,
    required Map<T, String> options,
    required T? value,
    required ValueChanged<T>? onChanged,
    AppChoiceStyle style = AppChoiceStyle.auto,
    bool expanded = true,
    bool compact = false,
  }) => AppChoice.of(
    key: key,
    values: options.keys.toList(),
    label: (v) => options[v]!,
    value: value,
    onChanged: onChanged,
    style: style,
    expanded: expanded,
    compact: compact,
  );

  final List<AppChoiceOption<T>> options;
  final T? value;

  /// Null turns the choice off.
  final ValueChanged<T>? onChanged;
  final AppChoiceStyle style;

  /// A heading above the options, with an optional line of help under it.
  final String? title;
  final String? hint;

  /// A floating label, which makes a menu look like a form field.
  final String? labelText;

  /// Shown in a menu while nothing is picked.
  final String? placeholder;

  /// When set, picking the chosen option again, or the [clearLabel] line, clears the choice.
  final VoidCallback? onCleared;

  /// The menu line that clears the choice.
  final String? clearLabel;

  /// Fills the width, which segments and a menu do by default.
  final bool expanded;

  /// Adds the screen side gutter, for a choice that sits straight in a list.
  final bool padded;

  /// Tighter segments, for a choice that shares a line with something else.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final body = _Body<T>(this);
    final heading = title == null
        ? null
        : _Heading(title: title!, hint: hint, padded: padded);
    final gutter = context.layout.gutter;
    final content = padded
        ? Padding(
            padding: EdgeInsets.fromLTRB(gutter, 0, gutter, 12),
            child: body,
          )
        : body;
    if (heading == null) return content;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [heading, content],
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading({
    required this.title,
    required this.hint,
    required this.padded,
  });

  final String title;
  final String? hint;
  final bool padded;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final gutter = padded ? context.layout.gutter : 0.0;
    return Padding(
      padding: EdgeInsets.fromLTRB(gutter, 8, gutter, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: cs.onSurface,
            ),
          ),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(hint!, style: TextStyle(fontSize: 12, color: cs.outline)),
          ],
        ],
      ),
    );
  }
}

// What a segment takes besides its text, and an icon.
const _segmentPadding = 32.0;
const _segmentIcon = 26.0;

class _Body<T> extends StatelessWidget {
  const _Body(this.choice);

  final AppChoice<T> choice;

  @override
  Widget build(BuildContext context) {
    switch (choice.style) {
      case AppChoiceStyle.pills:
        return _pills();
      case AppChoiceStyle.menu:
        return _menu(context);
      case AppChoiceStyle.segments:
        return _segments(context, icons: true);
      case AppChoiceStyle.auto:
        return LayoutBuilder(
          builder: (context, box) {
            final room = box.maxWidth;
            // A line with no width limit, such as inside a row, has room for anything.
            if (!room.isFinite ||
                _segmentsWidth(context, icons: true) <= room) {
              return _segments(context, icons: true);
            }
            if (_segmentsWidth(context, icons: false) <= room) {
              return _segments(context, icons: false);
            }
            return _menu(context);
          },
        );
    }
  }

  double _segmentsWidth(BuildContext context, {required bool icons}) {
    final base = Theme.of(context).textTheme.labelLarge ?? const TextStyle();
    final scaler = MediaQuery.textScalerOf(context);
    var total = 0.0;
    for (final option in choice.options) {
      final painter = TextPainter(
        text: TextSpan(text: option.label, style: base),
        textDirection: TextDirection.ltr,
        textScaler: scaler,
        maxLines: 1,
      )..layout();
      total += painter.width + _segmentPadding;
      if (icons && option.icon != null) total += _segmentIcon;
    }
    return total;
  }

  Widget _pills() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final option in choice.options)
          TogglePill(
            icon: option.icon ?? Icons.label_outline,
            label: option.label,
            selected: option.value == choice.value,
            onTap: () {
              if (option.value == choice.value && choice.onCleared != null) {
                choice.onCleared!();
              } else {
                choice.onChanged?.call(option.value);
              }
            },
          ),
      ],
    );
  }

  Widget _segments(BuildContext context, {required bool icons}) {
    final onChanged = choice.onChanged;
    final hasPick =
        choice.value != null &&
        choice.options.any((o) => o.value == choice.value);
    final segmented = SegmentedButton<T>(
      showSelectedIcon: false,
      emptySelectionAllowed: choice.onCleared != null || !hasPick,
      style: choice.compact
          ? SegmentedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              visualDensity: VisualDensity.compact,
            )
          : null,
      segments: [
        for (final option in choice.options)
          ButtonSegment(
            value: option.value,
            icon: icons && option.icon != null
                ? Icon(option.icon, size: 18)
                : null,
            label: Text(option.label, maxLines: 1, softWrap: false),
          ),
      ],
      selected: {if (hasPick) choice.value as T},
      onSelectionChanged: onChanged == null
          ? null
          : (picked) {
              if (picked.isNotEmpty) {
                onChanged(picked.first);
              } else {
                choice.onCleared?.call();
              }
            },
    );
    if (!choice.expanded) return segmented;
    return SizedBox(width: double.infinity, child: segmented);
  }

  Widget _menu(BuildContext context) {
    final picked = choice.options.any((o) => o.value == choice.value)
        ? choice.value
        : null;
    final onChanged = choice.onChanged;
    final menu = DropdownButton<T?>(
      value: picked,
      isExpanded: choice.expanded,
      isDense: choice.labelText != null,
      underline: const SizedBox.shrink(),
      hint: choice.placeholder == null ? null : Text(choice.placeholder!),
      items: [
        if (choice.onCleared != null)
          DropdownMenuItem<T?>(child: Text(choice.clearLabel ?? '')),
        for (final option in choice.options)
          DropdownMenuItem<T?>(
            value: option.value,
            child: Text(option.label, overflow: TextOverflow.ellipsis),
          ),
      ],
      onChanged: onChanged == null
          ? null
          : (next) {
              if (next == null) {
                choice.onCleared?.call();
              } else {
                onChanged(next);
              }
            },
    );
    if (choice.labelText == null) return menu;
    return InputDecorator(
      decoration: InputDecoration(labelText: choice.labelText),
      isEmpty: picked == null && choice.onCleared == null,
      child: DropdownButtonHideUnderline(child: menu),
    );
  }
}
