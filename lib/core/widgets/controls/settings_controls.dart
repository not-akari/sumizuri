import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';

class AppSwitchRow extends StatelessWidget {
  const AppSwitchRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;

  @override
  Widget build(BuildContext context) {
    // Merged, so a screen reader finds one switch with a name.
    return MergeSemantics(
      child: AppListRow(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onChanged == null ? null : () => onChanged!(!value),
        trailing: Switch(value: value, onChanged: onChanged),
      ),
    );
  }
}

class AppOptionRow extends StatelessWidget {
  const AppOptionRow({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Semantics(
      inMutuallyExclusiveGroup: true,
      selected: selected,
      child: AppListRow(
        icon: icon,
        iconColor: selected ? cs.primary : null,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.circle_outlined,
          size: 22,
          color: selected ? cs.primary : cs.outline,
        ),
      ),
    );
  }
}

/// A switch or check box with no icon or side margin, for dialogs and compact panels.
class AppToggleTile extends StatelessWidget {
  const AppToggleTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.checkbox = false,
    this.dense = true,
  });

  final String title;
  final String? subtitle;
  final bool value;

  /// Null turns the tile off.
  final ValueChanged<bool>? onChanged;

  /// A check box instead of a switch.
  final bool checkbox;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      title,
      style: dense ? const TextStyle(fontSize: 14) : null,
    );
    final hint = subtitle == null ? null : Text(subtitle!);
    final change = onChanged == null
        ? null
        : (bool? next) => onChanged!(next ?? false);
    if (checkbox) {
      return CheckboxListTile(
        dense: dense,
        contentPadding: EdgeInsets.zero,
        title: label,
        subtitle: hint,
        value: value,
        onChanged: change,
      );
    }
    return SwitchListTile(
      dense: dense,
      contentPadding: EdgeInsets.zero,
      title: label,
      subtitle: hint,
      value: value,
      onChanged: change,
    );
  }
}

/// A title inside a settings page that already has its own side margin.
class AppInlineHeading extends StatelessWidget {
  const AppInlineHeading(this.text, {super.key, this.large = false});

  final String text;

  /// The bigger title with more space above, for the main parts of a page.
  final bool large;

  @override
  Widget build(BuildContext context) {
    final style = large
        ? Theme.of(context).textTheme.titleMedium
        : Theme.of(context).textTheme.titleSmall;
    return Padding(
      padding: EdgeInsets.only(top: large ? 28 : 16, bottom: large ? 12 : 4),
      child: Text(text, style: style),
    );
  }
}

/// A title, a help line and a control under them, for a setting that is not a row.
class AppLabelled extends StatelessWidget {
  const AppLabelled({
    super.key,
    required this.title,
    this.hint,
    required this.child,
  });

  final String title;
  final String? hint;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: theme.textTheme.titleSmall),
          if (hint != null) ...[
            const SizedBox(height: 2),
            Text(
              hint!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}
