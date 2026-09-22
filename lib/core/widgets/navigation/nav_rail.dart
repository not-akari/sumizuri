import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/navigation/nav_item.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/navigation/island_nav_bar.dart';

class SumizuriNavRail extends StatelessWidget {
  const SumizuriNavRail({
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
            right: false,
            child: SizedBox(
              width: 96,

              child: Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          for (final (index, destination)
                              in destinations.indexed)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: NavItem(
                                placement: NavItemPlacement.rail,
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
            ),
          ),
        ],
      ),
    );
  }
}
