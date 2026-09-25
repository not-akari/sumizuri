import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_randomizer.dart';
import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// What was ticked last time, so shuffling again does not mean choosing again.
var _lastChoice = {...RandomizeAspect.values};

/// Asks what to randomize, and returns the answer, or null if it was closed
/// without pressing Randomize.
Future<Set<RandomizeAspect>?> showRandomizeSheet(BuildContext context) {
  return showAppSheet<Set<RandomizeAspect>>(
    context,
    builder: (_) => const _RandomizeSheet(),
  );
}

class _RandomizeSheet extends StatefulWidget {
  const _RandomizeSheet();

  @override
  State<_RandomizeSheet> createState() => _RandomizeSheetState();
}

class _RandomizeSheetState extends State<_RandomizeSheet> {
  late final Set<RandomizeAspect> _chosen = {..._lastChoice};

  List<RandomizeAspect> get _offered => RandomizeAspect.values;

  ({IconData icon, String title, String hint}) _describe(
    AppLocalizations l10n,
    RandomizeAspect aspect,
  ) => switch (aspect) {
    RandomizeAspect.colors => (
      icon: Icons.palette_outlined,
      title: l10n.randomizeColors,
      hint: l10n.randomizeColorsHint,
    ),
    RandomizeAspect.shapes => (
      icon: Icons.rounded_corner,
      title: l10n.randomizeShapes,
      hint: l10n.randomizeShapesHint,
    ),
    RandomizeAspect.fonts => (
      icon: Icons.text_fields_rounded,
      title: l10n.randomizeFonts,
      hint: l10n.randomizeFontsHint,
    ),
    RandomizeAspect.spacing => (
      icon: Icons.space_bar,
      title: l10n.randomizeSpacing,
      hint: l10n.randomizeSpacingHint,
    ),
    RandomizeAspect.effects => (
      icon: Icons.auto_awesome_outlined,
      title: l10n.randomizeEffects,
      hint: l10n.randomizeEffectsHint,
    ),
    RandomizeAspect.components => (
      icon: Icons.widgets_outlined,
      title: l10n.randomizeComponents,
      hint: l10n.randomizeComponentsHint,
    ),
    RandomizeAspect.background => (
      icon: Icons.blur_on_outlined,
      title: l10n.randomizeBackground,
      hint: l10n.randomizeBackgroundHint,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final all = _chosen.length == _offered.length;
    return AppSheet(
      title: l10n.randomizeTitle,
      subtitle: l10n.randomizeHint,
      actions: [
        TextButton(
          onPressed: () => setState(() {
            if (all) {
              _chosen.clear();
            } else {
              _chosen.addAll(_offered);
            }
          }),
          child: Text(all ? l10n.randomizeNone : l10n.randomizeAll),
        ),
      ],
      children: [
        for (final aspect in _offered)
          Builder(
            builder: (context) {
              final info = _describe(l10n, aspect);
              return AppSwitchRow(
                icon: info.icon,
                title: info.title,
                subtitle: info.hint,
                value: _chosen.contains(aspect),
                onChanged: (on) => setState(() {
                  if (on) {
                    _chosen.add(aspect);
                  } else {
                    _chosen.remove(aspect);
                  }
                }),
              );
            },
          ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: FilledButton.icon(
            onPressed: _chosen.isEmpty
                ? null
                : () {
                    _lastChoice = {..._chosen};
                    Navigator.of(context).pop({..._chosen});
                  },
            icon: const Icon(Icons.casino_outlined, size: 18),
            label: Text(l10n.randomizeAction),
          ),
        ),
      ],
    );
  }
}
