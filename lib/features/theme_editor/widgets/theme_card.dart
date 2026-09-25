import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';

class ThemeCard extends StatelessWidget {
  const ThemeCard({
    super.key,
    required this.colors,
    required this.shapes,
    required this.label,
    required this.selected,
    required this.onTap,
    this.menu,
    this.marked,
  });

  final ColorScheme colors;
  final ThemeShapes shapes;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  final Widget? menu;

  /// While themes are being chosen: whether this one is. Null the rest of the time.
  final bool? marked;

  @override
  Widget build(BuildContext context) {
    final cs = colors;
    final outline = Theme.of(context).colorScheme.outlineVariant;
    final cardRadius = shapes.card.radius;

    return SizedBox(
      width: 88,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              PressableScale(
                onTap: onTap,
                pressedScale: 0.94,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 88,
                    height: 108,
                    clipBehavior: Clip.antiAlias,
                    decoration: BoxDecoration(
                      color: cs.surface,
                      borderRadius: cardRadius,
                      border: Border.all(
                        color: marked == true
                            ? Theme.of(context).colorScheme.error
                            : selected
                            ? cs.primary
                            : outline,
                        width: selected || marked == true ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(height: 22, color: cs.primary),
                        Padding(
                          padding: const EdgeInsets.all(8),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                height: 6,
                                width: 44,
                                margin: const EdgeInsets.only(bottom: 5),
                                decoration: BoxDecoration(
                                  color: cs.onSurface.withValues(alpha: 0.4),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Container(
                                height: 6,
                                width: 28,
                                margin: const EdgeInsets.only(bottom: 10),
                                decoration: BoxDecoration(
                                  color: cs.onSurface.withValues(alpha: 0.22),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                              Container(
                                height: 18,
                                width: 40,
                                decoration: BoxDecoration(
                                  color: cs.secondary,
                                  borderRadius: shapes.button.radius,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (selected)
                Positioned(
                  top: -6,
                  left: -6,
                  child: CircleAvatar(
                    radius: 10,
                    backgroundColor: cs.primary,
                    child: Icon(Icons.check, size: 13, color: cs.onPrimary),
                  ),
                ),
              if (marked != null)
                Positioned(
                  top: -6,
                  right: -6,
                  child: CircleAvatar(
                    radius: 11,
                    backgroundColor: marked!
                        ? Theme.of(context).colorScheme.error
                        : Theme.of(context).colorScheme.surfaceContainerHighest,
                    child: Icon(
                      marked! ? Icons.check : Icons.circle_outlined,
                      size: 14,
                      color: marked!
                          ? Theme.of(context).colorScheme.onError
                          : Theme.of(context).colorScheme.outline,
                    ),
                  ),
                ),
              if (menu != null) Positioned(top: 22, right: 0, child: menu!),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
