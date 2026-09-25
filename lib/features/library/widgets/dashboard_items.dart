import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/content/manga_cover_list_row.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

/// One title on a section of the home page.
class DashboardItem {
  const DashboardItem({
    required this.title,
    required this.onTap,
    this.coverUrl,
    this.customCoverPath,
    this.caption,
    this.progress,
    this.badge,
    this.heroTag,
  });

  final String title;
  final String? coverUrl;
  final String? customCoverPath;

  /// A line under the title, such as the chapter last read.
  final String? caption;

  /// How much of the title is read, from 0 to 1.
  final double? progress;

  /// A count shown on the cover, such as new chapters.
  final int? badge;
  final Object? heroTag;
  final VoidCallback onTap;
}

/// The titles of a home page section, in the way the person chose for it: a
/// row of covers that scrolls sideways, a grid, or a short list.
class DashboardItems extends ConsumerWidget {
  const DashboardItems({super.key, required this.style, required this.items});

  final DashboardShelfStyle style;
  final List<DashboardItem> items;

  Widget _tile(DashboardItem item) => MangaCoverTile(
    title: item.title,
    coverUrl: item.coverUrl,
    customCoverPath: item.customCoverPath,
    caption: item.caption,
    progress: item.progress,
    unreadCount: item.badge,
    heroTag: item.heroTag,
    onTap: item.onTap,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tileSize =
        ref.watch(libraryGridTileSizeProvider).value ??
        LibraryGridTileSize.medium;
    return switch (style) {
      DashboardShelfStyle.shelf => SizedBox(
        // The cover, then room for its title and a line under it.
        height: tileSize.maxExtent * 1.5 + 60,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: items.length,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) =>
              SizedBox(width: tileSize.maxExtent, child: _tile(items[index])),
        ),
      ),
      DashboardShelfStyle.grid => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: tileSize.maxExtent,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.5,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) => _tile(items[index]),
        ),
      ),
      DashboardShelfStyle.list => Column(
        children: [
          for (final item in items)
            MangaCoverListRow(
              dense: true,
              title: item.title,
              coverUrl: item.coverUrl,
              customCoverPath: item.customCoverPath,
              caption: item.caption,
              progress: item.progress,
              unreadCount: item.badge,
              heroTag: item.heroTag,
              onTap: item.onTap,
            ),
        ],
      ),
    };
  }
}
