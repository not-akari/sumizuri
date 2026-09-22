import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';

class UpdateCoverCard extends StatelessWidget {
  const UpdateCoverCard({
    super.key,
    required this.title,
    this.coverUrl,
    this.customCoverPath,
    this.newChapterCount,
    this.width = 140,
    required this.onTap,
  });

  final String title;
  final String? coverUrl;
  final String? customCoverPath;

  final int? newChapterCount;

  final double width;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Its own Material, since a hero is drawn in the overlay away from the page's Material.
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        onTap: onTap,
        borderRadius: context.shapes.cover.radius,
        child: ClipRRect(
          borderRadius: context.shapes.cover.radius,
          child: SizedBox(
            width: width,
            child: AspectRatio(
              aspectRatio: 2 / 3,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CoverImage(url: coverUrl, filePath: customCoverPath),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.75),
                        ],
                        stops: const [0.5, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  if (newChapterCount != null && newChapterCount! > 1)
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '+$newChapterCount',
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.onPrimary,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
