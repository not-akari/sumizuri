import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/controls/app_choice.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The building blocks of the theme editor's tabs. Everything is drawn as the
/// soft cards the rest of the app uses, so the editor looks like the app it
/// is editing.

/// A labelled group of controls, with an optional button that puts just this
/// group back to its defaults.
class EditorSection extends StatelessWidget {
  const EditorSection({
    super.key,
    required this.title,
    required this.children,
    this.onReset,
  });

  final String title;
  final List<Widget> children;
  final VoidCallback? onReset;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final side = AppRowStyle.marginOf(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(child: AppSectionLabel(label: title)),
            if (onReset != null)
              Padding(
                padding: EdgeInsets.only(right: side - 8, top: 12),
                child: TextButton.icon(
                  onPressed: onReset,
                  style: TextButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Icon(Icons.restart_alt, size: 16),
                  label: Text(
                    l10n.themeOptionsReset,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
              ),
          ],
        ),
        ...children,
      ],
    );
  }
}

/// A slider in its own card: the name, the value as a chip that also resets
/// it to [defaultValue] when tapped, and an optional line of explanation.
class EditorSlider extends StatelessWidget {
  const EditorSlider({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.format,
    this.defaultValue,
    this.divisions,
    this.hint,
  });

  final String label;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final String Function(double value) format;
  final double? defaultValue;
  final int? divisions;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final canReset =
        defaultValue != null && (value - defaultValue!).abs() > 1e-6;
    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      margin: EdgeInsets.symmetric(
        horizontal: AppRowStyle.marginOf(context),
        vertical: 4,
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              InkWell(
                onTap: canReset ? () => onChanged(defaultValue!) : null,
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: cs.outlineVariant),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        format(value),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: canReset ? cs.primary : cs.onSurfaceVariant,
                        ),
                      ),
                      if (canReset) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.restart_alt, size: 13, color: cs.primary),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (hint != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                hint!,
                style: TextStyle(fontSize: 12, height: 1.35, color: cs.outline),
              ),
            ),
          Slider(
            value: value.clamp(min, max).toDouble(),
            min: min,
            max: max,
            divisions: divisions,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}

/// A choice between a few options, in its own card under its name.
class EditorChoice<T> extends StatelessWidget {
  const EditorChoice({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final Map<T, String> options;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      margin: EdgeInsets.symmetric(
        horizontal: AppRowStyle.marginOf(context),
        vertical: 4,
      ),
      padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          AppChoice<T>.map(
            options: options,
            value: value,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
