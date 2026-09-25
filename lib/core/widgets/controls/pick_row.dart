import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';

/// One choice as a row that says what it is now and opens the options in a
/// sheet when tapped.
class PickRow<T> extends StatelessWidget {
  const PickRow({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.values,
    required this.labelOf,
    required this.iconOf,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final T value;
  final List<T> values;
  final String Function(T) labelOf;
  final IconData Function(T) iconOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppListRow(
      icon: icon,
      title: title,
      subtitle: labelOf(value),
      onTap: () async {
        final picked = await showAppSheet<T>(
          context,
          builder: (sheet) => AppSheet(
            title: title,
            children: [
              for (final option in values)
                AppOptionRow(
                  icon: iconOf(option),
                  title: labelOf(option),
                  selected: option == value,
                  onTap: () => Navigator.of(sheet).pop(option),
                ),
            ],
          ),
        );
        if (picked != null && picked != value) onChanged(picked);
      },
    );
  }
}
