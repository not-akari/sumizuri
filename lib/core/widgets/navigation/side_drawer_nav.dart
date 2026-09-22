import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/navigation/island_nav_bar.dart';
import 'package:sumizuri/core/widgets/controls/tap_double_tap_area.dart';

class SideDrawerNav extends StatelessWidget {
  const SideDrawerNav({
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
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          const Positioned.fill(child: WindowAmbient()),
          SizedBox(
            width: 220,
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: [
                for (final (index, destination) in destinations.indexed)
                  _DrawerRow(
                    icon: destination.icon,
                    label: destination.tooltip,
                    selected: index == selectedIndex,
                    onTap: () => onSelected(index),
                    onDoubleTap: destination.onDoubleTap,
                    avatar: destination.avatar,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerRow extends StatelessWidget {
  const _DrawerRow({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.onDoubleTap,
    this.avatar,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final VoidCallback? onDoubleTap;
  final Widget? avatar;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
      child: Material(
        color: selected ? cs.primaryContainer : Colors.transparent,
        borderRadius: context.shapes.chip.radius,
        clipBehavior: Clip.antiAlias,
        child: TapDoubleTapArea(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                avatar ??
                    Icon(
                      icon,
                      size: 20,
                      color: selected
                          ? cs.onPrimaryContainer
                          : cs.onSurfaceVariant,
                    ),
                const SizedBox(width: 14),
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: selected
                        ? cs.onPrimaryContainer
                        : cs.onSurfaceVariant,
                    fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                    fontStyle: selected ? FontStyle.italic : FontStyle.normal,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
