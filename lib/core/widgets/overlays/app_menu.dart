import 'package:flutter/material.dart';

/// One line of an [AppMenu].
class AppMenuEntry<T> {
  const AppMenuEntry(
    this.value,
    this.label, {
    this.icon,
    this.checked,
    this.destructive = false,
    this.dividerBefore = false,
  });

  final T value;
  final String label;
  final IconData? icon;

  /// When set, the line shows a check mark that is on or off.
  final bool? checked;

  /// Drawn in the error colour, for something that deletes.
  final bool destructive;
  final bool dividerBefore;
}

/// The three-dot menu used across the app, built from lines given as data.
class AppMenu<T> extends StatelessWidget {
  const AppMenu({
    super.key,
    required this.entries,
    required this.onSelected,
    this.tooltip,
    this.iconSize,
    this.tight = false,
  });

  /// A menu with one line per value, usually an enum, with optional look functions.
  factory AppMenu.of({
    Key? key,
    required List<T> values,
    required String Function(T value) label,
    required ValueChanged<T> onSelected,
    bool Function(T value)? visible,
    IconData? Function(T value)? icon,
    bool? Function(T value)? checked,
    bool Function(T value)? destructive,
    bool Function(T value)? dividerBefore,
    String? tooltip,
    double? iconSize,
    bool tight = false,
  }) => AppMenu(
    key: key,
    entries: [
      for (final value in values)
        if (visible?.call(value) ?? true)
          AppMenuEntry(
            value,
            label(value),
            icon: icon?.call(value),
            checked: checked?.call(value),
            destructive: destructive?.call(value) ?? false,
            dividerBefore: dividerBefore?.call(value) ?? false,
          ),
    ],
    onSelected: onSelected,
    tooltip: tooltip,
    iconSize: iconSize,
    tight: tight,
  );

  final List<AppMenuEntry<T>> entries;
  final ValueChanged<T> onSelected;
  final String? tooltip;
  final double? iconSize;

  /// Drops the padding around the button, for a menu inside a compact row.
  final bool tight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return PopupMenuButton<T>(
      icon: Icon(Icons.more_vert, size: iconSize),
      iconSize: iconSize,
      tooltip: tooltip,
      padding: tight ? EdgeInsets.zero : const EdgeInsets.all(8),
      onSelected: onSelected,
      itemBuilder: (context) => [
        for (final entry in entries) ...[
          if (entry.dividerBefore) const PopupMenuDivider(),
          if (entry.checked != null)
            CheckedPopupMenuItem<T>(
              value: entry.value,
              checked: entry.checked!,
              child: Text(entry.label),
            )
          else
            PopupMenuItem<T>(
              value: entry.value,
              child: _line(entry, entry.destructive ? cs.error : null),
            ),
        ],
      ],
    );
  }

  Widget _line(AppMenuEntry<T> entry, Color? color) {
    final text = Text(entry.label, style: TextStyle(color: color));
    if (entry.icon == null) return text;
    return Row(
      children: [
        Icon(entry.icon, size: 18, color: color),
        const SizedBox(width: 12),
        Flexible(child: text),
      ],
    );
  }
}
