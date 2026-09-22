import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/controls/no_scrollbar.dart';
import 'package:sumizuri/features/statistics/providers/statistics_providers.dart';
import 'package:sumizuri/features/statistics/widgets/library_breakdown_card.dart';
import 'package:sumizuri/features/statistics/widgets/reading_insights_card.dart';
import 'package:sumizuri/features/statistics/widgets/stats_metric_cards.dart';
import 'package:sumizuri/features/statistics/widgets/top_read_series_card.dart';

class StatisticsTab extends ConsumerWidget {
  const StatisticsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final stats = ref.watch(readingStatisticsProvider).value;
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (stats.totalSessions == 0 && stats.totalLibraryEntries == 0) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.bar_chart_rounded,
                size: 56,
                color: theme.colorScheme.outlineVariant,
              ),
              const SizedBox(height: 14),
              Text(
                AppLocalizations.of(context)!.statisticNoReadingActivityYet,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                AppLocalizations.of(context)!
                    .statisticStartReadingMangaNovelsOr,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: ScrollConfiguration(
          behavior: const NoScrollbarBehavior(),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              4,
              context.layout.gutter,
              24,
            ),
            children: [
              StreakHeroCard(stats: stats),
              const SizedBox(height: 14),
              VolumeMetricsCard(stats: stats),
              const SizedBox(height: 14),
              AveragesCard(stats: stats),
              const SizedBox(height: 14),
              ReadingInsightsCard(stats: stats),
              const SizedBox(height: 14),
              LibraryBreakdownCard(stats: stats),
              if (stats.topReadEntries.isNotEmpty) ...[
                const SizedBox(height: 14),
                TopReadSeriesCard(stats: stats),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
