import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/navigation/nav_item.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';

import 'package:sumizuri/core/widgets/navigation/island_nav_bar.dart';

class BottomBarNav extends StatelessWidget {
  const BottomBarNav({
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
    final safeIndex = safeNavIndex(selectedIndex, destinations.length);
    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          const Positioned.fill(child: WindowAmbient()),
          SafeArea(
            top: false,
            child: SizedBox(
              height: 80,
              child: Row(
                children: [
                  for (final (index, destination) in destinations.indexed)
                    Expanded(
                      child: NavItem(
                        placement: NavItemPlacement.bar,
                        icon: destination.icon,
                        label: destination.tooltip,
                        selected: index == safeIndex,
                        onTap: () => onSelected(index),
                        onDoubleTap: destination.onDoubleTap,
                        avatar: destination.avatar,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
