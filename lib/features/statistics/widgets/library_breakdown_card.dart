import 'package:flutter/material.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class LibraryBreakdownCard extends StatelessWidget {
  const LibraryBreakdownCard({super.key, required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    return AppCard(
      title: l10n.statsLibraryBreakdown,
      trailing: Text(
        AppLocalizations.of(context)!.statisticTotal(stats.totalLibraryEntries),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: cs.primary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _BreakdownPill(
                icon: Icons.menu_book_rounded,
                label: l10n.mediaTypeMangaTitle,
                count: stats.mangaCount,
              ),
              _BreakdownPill(
                icon: Icons.auto_stories_rounded,
                label: l10n.mediaTypeNovelTitle,
                count: stats.novelCount,
              ),
              _BreakdownPill(
                icon: Icons.movie_outlined,
                label: l10n.mediaTypeAnimeTitle,
                count: stats.animeCount,
              ),
              if (stats.favoriteCount > 0)
                _BreakdownPill(
                  icon: Icons.favorite_rounded,
                  label: AppLocalizations.of(context)!.statisticFavorites,
                  count: stats.favoriteCount,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BreakdownPill extends StatelessWidget {
  const _BreakdownPill({
    required this.icon,
    required this.label,
    required this.count,
  });

  final IconData icon;
  final String label;
  final int count;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: cs.surface,
        border: Border.all(color: cs.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(fontSize: 12, color: cs.onSurfaceVariant),
          ),
          const SizedBox(width: 6),
          Text(
            '$count',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}
