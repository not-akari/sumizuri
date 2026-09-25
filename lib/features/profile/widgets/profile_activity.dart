import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/library/flows/open_library_entry.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';
import 'package:sumizuri/features/statistics/providers/statistics_providers.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// How much has been read lately: today, this week and this month as numbers,
/// and the last two weeks as a row of bars.
class ProfileActivityCard extends ConsumerWidget {
  const ProfileActivityCard({super.key});

  static const _days = 14;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final stats =
        ref.watch(readingStatisticsProvider).value ?? ReadingStats.empty;

    final now = DateTime.now();
    final days = [
      for (var i = _days - 1; i >= 0; i--)
        DateTime(now.year, now.month, now.day - i),
    ];
    final counts = [for (final d in days) stats.dailyActivity[d] ?? 0];
    final peak = counts.fold<int>(0, (a, b) => a > b ? a : b);

    Widget metric(String value, String label) => Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontFamily: context.displayFont,
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11.5, color: cs.outline)),
        ],
      ),
    );

    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              metric('${stats.chaptersToday}', l10n.statsToday),
              metric('${stats.chaptersThisWeek}', l10n.statsThisWeek),
              metric('${stats.chaptersThisMonth}', l10n.statsThisMonth),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            l10n.profileLastDays(_days),
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: cs.outline,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 72,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (var i = 0; i < days.length; i++)
                  Expanded(
                    child: Tooltip(
                      message:
                          '${DateFormat.MMMd().format(days[i])}: ${l10n.statsChaptersCount(counts[i])}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.5),
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: counts[i] == 0
                                ? 4
                                : 8 + 64 * counts[i] / peak,
                            decoration: BoxDecoration(
                              color: counts[i] == 0
                                  ? cs.outlineVariant.withValues(alpha: 0.6)
                                  : i == days.length - 1
                                  ? cs.primary
                                  : cs.primary.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat.MMMd().format(days.first),
                style: TextStyle(fontSize: 10.5, color: cs.outline),
              ),
              Text(
                l10n.statsToday,
                style: TextStyle(fontSize: 10.5, color: cs.outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The titles read the most, as a shelf of covers to open.
class ProfileMostReadShelf extends ConsumerWidget {
  const ProfileMostReadShelf({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final stats =
        ref.watch(readingStatisticsProvider).value ?? ReadingStats.empty;
    final entries = stats.topReadEntries.take(6).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(label: l10n.statsTopSeries),
        SizedBox(
          height: 196,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: entries.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final entry = entries[index];
              return SizedBox(
                width: 108,
                child: InkWell(
                  borderRadius: context.shapes.cover.radius,
                  onTap: () => openLibraryEntry(
                    context,
                    ref,
                    libraryEntryId: entry.libraryEntryId,
                    title: entry.title,
                    coverUrl: entry.coverUrl,
                    sourceId: entry.sourceId,
                    externalId: entry.externalId,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: context.shapes.cover.radius,
                            child: SizedBox(
                              width: 108,
                              height: 152,
                              child: CoverImage(
                                url: entry.coverUrl,
                                filePath: entry.customCoverPath,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            left: 6,
                            top: 6,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: index == 0
                                    ? cs.primary
                                    : Colors.black.withValues(alpha: 0.65),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Text(
                                '#${index + 1} · ${entry.chaptersReadCount}',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w700,
                                  color: index == 0
                                      ? cs.onPrimary
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        entry.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
