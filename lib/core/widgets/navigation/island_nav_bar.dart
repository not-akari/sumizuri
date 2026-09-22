import 'dart:ui';

import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/navigation/nav_item.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/theming/app_motion.dart';
import 'package:sumizuri/core/widgets/controls/pressable_scale.dart';
import 'package:sumizuri/core/widgets/controls/tap_double_tap_area.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';

class IslandNavDestination {
  const IslandNavDestination({
    required this.icon,
    required this.tooltip,
    this.onDoubleTap,
    this.avatar,
  });

  final IconData icon;
  final String tooltip;

  final VoidCallback? onDoubleTap;

  final Widget? avatar;
}

const double _slotWidth = 52.0;
const double _minSlotWidth = 36.0;
// Padding and border around the slots.
const double _barChrome = 14.0;
const double _slotHeight = 44.0;

class IslandNavBar extends StatelessWidget {
  const IslandNavBar({
    super.key,
    required this.destinations,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<IslandNavDestination> destinations;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final safeIndex = safeNavIndex(selectedIndex, destinations.length);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Each icon gets its usual width, or less when the bar would not fit the screen.
        final slotWidth =
            constraints.maxWidth.isFinite && destinations.isNotEmpty
            ? ((constraints.maxWidth - _barChrome) / destinations.length).clamp(
                _minSlotWidth,
                _slotWidth,
              )
            : _slotWidth;
        return _bar(context, colorScheme, safeIndex, slotWidth);
      },
    );
  }

  Widget _bar(
    BuildContext context,
    ColorScheme colorScheme,
    int safeIndex,
    double slotWidth,
  ) {
    return RepaintBoundary(
      child: Container(
        decoration: BoxDecoration(
          borderRadius: context.shapes.navBar.radius,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.28),
              blurRadius: 18,
              spreadRadius: -2,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: colorScheme.primary.withValues(alpha: 0.12),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: context.shapes.navBar.radius,
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHigh.withValues(alpha: 0.85),
                borderRadius: context.shapes.navBar.radius,
                border: Border.all(
                  color: colorScheme.outlineVariant.withValues(alpha: 0.35),
                  width: 0.8,
                ),
              ),
              child: SizedBox(
                height: _slotHeight,
                child: Stack(
                  children: [
                    if (destinations.isNotEmpty)
                      AnimatedPositioned(
                        duration: AppMotion.medium,
                        curve: AppMotion.curveLiquid,
                        left: safeIndex * slotWidth,
                        top: 0,
                        width: slotWidth,
                        height: _slotHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: colorScheme.primaryContainer,
                            borderRadius: context.shapes.navIndicator.radius,
                            boxShadow: [
                              BoxShadow(
                                color: colorScheme.primary.withValues(
                                  alpha: 0.25,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                        ),
                      ),

                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        for (var i = 0; i < destinations.length; i++)
                          _IslandNavIcon(
                            icon: destinations[i].icon,
                            tooltip: destinations[i].tooltip,
                            slotWidth: slotWidth,
                            selected: i == safeIndex,
                            onTap: () => onSelected(i),
                            onDoubleTap: destinations[i].onDoubleTap,
                            avatar: destinations[i].avatar,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IslandNavIcon extends StatefulWidget {
  const _IslandNavIcon({
    required this.icon,
    required this.tooltip,
    required this.slotWidth,
    required this.selected,
    required this.onTap,
    this.onDoubleTap,
    this.avatar,
  });

  final IconData icon;
  final String tooltip;
  final double slotWidth;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final Widget? avatar;

  @override
  State<_IslandNavIcon> createState() => _IslandNavIconState();
}

class _IslandNavIconState extends State<_IslandNavIcon> {
  @override
  Widget build(BuildContext context) => Semantics(
    button: true,
    selected: widget.selected,
    label: widget.tooltip,
    onTap: widget.onTap,
    // The tooltip and the icon would read the same thing a second time.
    excludeSemantics: true,
    child: _content(context),
  );

  Widget _content(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Tooltip(
      excludeFromSemantics: true,
      message: widget.tooltip,
      child: PressableScale(
        onTap: widget.onTap,
        pressedScale: 0.88,
        enableHover: false,
        child: TapDoubleTapArea(
          onTap: widget.onTap,
          onDoubleTap: widget.onDoubleTap,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: widget.slotWidth,
            height: _slotHeight,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AnimatedScale(
                  scale: widget.selected ? 1.14 : 1.0,
                  duration: AppMotion.medium,
                  curve: AppMotion.curveSpring,
                  child:
                      widget.avatar ??
                      Icon(
                        widget.icon,
                        size: 22,
                        color: widget.selected
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSurfaceVariant,
                      ),
                ),
                SizedBox(
                  width: 14,
                  height: 4,
                  child: widget.selected
                      ? CustomPaint(
                          painter: BrushLinePainter(
                            curvy: context.options.effects.brushStrokes,
                            color: colorScheme.onPrimaryContainer,
                          ),
                        )
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
