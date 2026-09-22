import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';
import 'package:sumizuri/core/widgets/controls/tap_double_tap_area.dart';

/// Keeps the selected index inside the list, which can shrink while the bar is on screen.
int safeNavIndex(int index, int count) =>
    index.clamp(0, count == 0 ? 0 : count - 1);

/// Where a [NavItem] sits, which decides how its highlight is shaped.
enum NavItemPlacement {
  /// One of several across the bottom, with a wide pill behind the icon.
  bar,

  /// One of several down the side, with a fixed width pill behind the icon.
  rail,
}

/// An icon over a label with a brush stroke under the chosen one, for bars and rails.
class NavItem extends StatelessWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.placement,
    this.onDoubleTap,
    this.avatar,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final Widget? avatar;
  final NavItemPlacement placement;

  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: selected,
    label: label,
    onTap: onTap,
    excludeSemantics: true,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final rail = placement == NavItemPlacement.rail;
    return TapDoubleTapArea(
      onTap: onTap,
      onDoubleTap: onDoubleTap,
      borderRadius: context.shapes.navIndicator.radius,
      child: Padding(
        padding: rail
            ? const EdgeInsets.symmetric(horizontal: 4)
            : const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: rail ? MainAxisSize.min : MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: rail ? 56 : null,
              alignment: rail ? Alignment.center : null,
              padding: rail
                  ? const EdgeInsets.symmetric(vertical: 8)
                  : const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: selected ? cs.primaryContainer : Colors.transparent,
                borderRadius: context.shapes.navIndicator.radius,
              ),
              child:
                  avatar ??
                  Icon(
                    icon,
                    size: 22,
                    color: selected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected ? cs.onSurface : cs.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                fontStyle: selected ? FontStyle.italic : FontStyle.normal,
              ),
            ),
            SizedBox(
              width: 16,
              height: 4,
              child: selected
                  ? CustomPaint(
                      painter: BrushLinePainter(
                        curvy: context.options.effects.brushStrokes,
                        color: cs.primary,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
