import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';

/// A scrolling row of tabs that filters a list. With [brush] a stroke marks the chosen one.
class FilterTabRow<T> extends StatelessWidget {
  const FilterTabRow({
    super.key,
    required this.allLabel,
    required this.selected,
    required this.items,
    required this.onSelect,
    this.showAllChip = true,
    this.brush = false,
  });

  final String allLabel;
  final T? selected;
  final List<(T value, String label)> items;
  final ValueChanged<T?> onSelect;
  final bool showAllChip;
  final bool brush;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Widget tab(String label, bool isSelected, VoidCallback onTap) {
      final text = AnimatedDefaultTextStyle(
        duration: AppMotion.fast,
        curve: AppMotion.curveInteractive,
        style: TextStyle(
          fontSize: 13.5,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          fontStyle: brush && isSelected ? FontStyle.italic : FontStyle.normal,
          color: isSelected ? cs.primary : cs.onSurfaceVariant,
        ),
        child: Text(label),
      );
      return InkWell(
        onTap: onTap,
        hoverColor: Colors.transparent,
        splashFactory: NoSplash.splashFactory,
        highlightColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: brush
              ? Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    text,
                    const SizedBox(height: 4),
                    SizedBox(
                      width: 26,
                      height: 5,
                      child: isSelected
                          ? CustomPaint(
                              painter: BrushLinePainter(
                                curvy: context.options.effects.brushStrokes,
                                color: cs.primary,
                              ),
                            )
                          : null,
                    ),
                  ],
                )
              : text,
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          if (showAllChip)
            tab(allLabel, selected == null, () => onSelect(null)),
          for (final (value, label) in items)
            tab(label, selected == value, () => onSelect(value)),
        ],
      ),
    );
  }
}
