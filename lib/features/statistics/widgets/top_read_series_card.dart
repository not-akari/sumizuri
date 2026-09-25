import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';

class TopReadSeriesCard extends ConsumerWidget {
  const TopReadSeriesCard({super.key, required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;

    if (stats.topReadEntries.isEmpty) return const SizedBox.shrink();

    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      title: l10n.statsTopSeries,
      titleGap: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, entry) in stats.topReadEntries.indexed)
            InkWell(
              borderRadius: BorderRadius.circular(8),
              onTap: () => openLibraryEntry(
                context,
                ref,
                libraryEntryId: entry.libraryEntryId,
                title: entry.title,
                coverUrl: entry.coverUrl,
                sourceId: entry.sourceId,
                externalId: entry.externalId,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 22,
                      height: 22,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: index < 1 ? cs.primary : cs.outlineVariant,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: index < 1 ? cs.onPrimary : cs.onSurfaceVariant,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entry.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: cs.primary.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        l10n.statsChaptersCount(entry.chaptersReadCount),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: cs.primary,
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
