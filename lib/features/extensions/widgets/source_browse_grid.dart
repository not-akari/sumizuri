import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';

class SourceBrowseGrid extends StatelessWidget {
  const SourceBrowseGrid({
    super.key,
    required this.controller,
    required this.entries,
    required this.hasMore,
    required this.loadingMore,
    required this.onLoadMore,
    required this.onOpenEntry,
    required this.onAddToLibrary,
    required this.libraryIds,
    required this.emptyText,
    required this.loadMoreText,
  });

  final ScrollController controller;
  final List<MEntry> entries;
  final bool hasMore;
  final bool loadingMore;
  final VoidCallback onLoadMore;
  final ValueChanged<MEntry> onOpenEntry;
  final ValueChanged<MEntry> onAddToLibrary;
  final Set<String> libraryIds;
  final String emptyText;
  final String loadMoreText;

  @override
  Widget build(BuildContext context) {
    if (entries.isEmpty) {
      return Center(
        child: Text(emptyText, style: Theme.of(context).textTheme.bodyMedium),
      );
    }

    return GridView.builder(
      controller: controller,
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 130,
        crossAxisSpacing: 12,
        mainAxisSpacing: 16,
        childAspectRatio: 0.62,
      ),
      itemCount: entries.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == entries.length) {
          return _buildLoadMoreCard(context);
        }
        final entry = entries[index];
        return _buildEntryCard(context, entry);
      },
    );
  }

  Widget _buildLoadMoreCard(BuildContext context) {
    return InkWell(
      onTap: loadingMore ? null : onLoadMore,
      borderRadius: context.shapes.cover.radius,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: context.shapes.cover.radius,
          border: Border.all(color: Theme.of(context).colorScheme.outline),
        ),
        alignment: Alignment.center,
        child: loadingMore
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add_circle_outline),
                  const SizedBox(height: 4),
                  Text(loadMoreText, textAlign: TextAlign.center),
                ],
              ),
      ),
    );
  }

  Widget _buildEntryCard(BuildContext context, MEntry entry) {
    final inLibrary = libraryIds.contains(entry.url);

    return InkWell(
      onTap: () => onOpenEntry(entry),
      onLongPress: () => onAddToLibrary(entry),
      borderRadius: context.shapes.cover.radius,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: context.shapes.cover.radius,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CoverImage(
                    url: entry.coverUrl,
                    placeholderIcon: Icons.image_outlined,
                  ),
                  if (inLibrary)
                    Positioned.fill(
                      child: ColoredBox(color: Colors.black.withAlpha(115)),
                    ),
                  if (entry.rating != null)
                    Positioned(
                      left: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              size: 12,
                              color: Colors.amber,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              entry.rating!.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (inLibrary)
                    Positioned(
                      right: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.black.withAlpha(180),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.greenAccent,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            entry.title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}
