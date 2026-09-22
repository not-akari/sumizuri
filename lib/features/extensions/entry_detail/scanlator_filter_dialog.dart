import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<Set<String>?> showScanlatorFilterDialog(
  BuildContext context, {
  required List<String> names,
  required Set<String> hidden,
}) {
  return showDialog<Set<String>>(
    context: context,
    builder: (_) => _ScanlatorFilterDialog(names: names, hidden: hidden),
  );
}

class _ScanlatorFilterDialog extends StatefulWidget {
  const _ScanlatorFilterDialog({required this.names, required this.hidden});

  final List<String> names;
  final Set<String> hidden;

  @override
  State<_ScanlatorFilterDialog> createState() => _ScanlatorFilterDialogState();
}

class _ScanlatorFilterDialogState extends State<_ScanlatorFilterDialog> {
  late final Set<String> _hidden = {...widget.hidden};

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AlertDialog(
      title: Text(l10n.scanlatorFilterTitle),
      content: SizedBox(
        width: 360,
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                l10n.scanlatorFilterHint,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            for (final name in widget.names)
              AppToggleTile(
                checkbox: true,
                title: name,
                value: !_hidden.contains(name),
                onChanged: (show) => setState(() {
                  if (show) {
                    _hidden.remove(name);
                  } else {
                    _hidden.add(name);
                  }
                }),
              ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => setState(_hidden.clear),
          child: Text(l10n.scanlatorFilterShowAll),
        ),
        FilledButton(
          // Hiding every scanlator would empty the list, so at least one stays.
          onPressed: _hidden.length >= widget.names.length
              ? null
              : () => Navigator.of(context).pop(_hidden),
          child: Text(l10n.scanlatorFilterApply),
        ),
      ],
    );
  }
}
