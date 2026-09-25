import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class StreakHeroCard extends StatelessWidget {
  const StreakHeroCard({super.key, required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final l10n = AppLocalizations.of(context)!;
    final detail = TextStyle(fontSize: 12, color: cs.onSurfaceVariant);

    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cs.primary.withValues(alpha: 0.14),
            ),
            alignment: Alignment.center,
            child: Icon(
              Icons.local_fire_department_rounded,
              size: 28,
              color: cs.primary,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.statsCurrentStreak,
                  style: TextStyle(fontSize: 12, color: cs.outline),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.statsDaysCount(stats.currentStreak),
                  style: TextStyle(
                    fontFamily: context.displayFont,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${l10n.statsBestStreak}: ${l10n.statsDaysCount(stats.longestStreak)} · ${l10n.statsActiveDays}: ${l10n.statsDaysCount(stats.totalActiveDays)}',
                  style: detail,
                ),
                if (stats.longestSingleDayCount > 0)
                  Text(
                    '${l10n.statsBestDay}: ${l10n.statsChaptersCount(stats.longestSingleDayCount)}',
                    style: detail,
                  ),
                if (stats.firstReadAt != null)
                  Text(
                    l10n.statsReadingSince(
                      DateFormat.yMMMd().format(stats.firstReadAt!),
                    ),
                    style: detail,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class VolumeMetricsCard extends StatelessWidget {
  const VolumeMetricsCard({super.key, required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      child: _MetricRow(
        metrics: [
          (l10n.statsToday, '${stats.chaptersToday}'),
          (l10n.statsThisWeek, '${stats.chaptersThisWeek}'),
          (l10n.statsThisMonth, '${stats.chaptersThisMonth}'),
        ],
      ),
    );
  }
}

class AveragesCard extends StatelessWidget {
  const AveragesCard({super.key, required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      title: l10n.statsAverages,
      titleGap: 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _MetricRow(
            metrics: [
              (
                l10n.statsPerSession,
                stats.averageChaptersPerSession.toStringAsFixed(1),
              ),
              (
                l10n.statsPerActiveDay,
                stats.averageChaptersPerActiveDay.toStringAsFixed(1),
              ),
              (
                l10n.statsPerWeek,
                stats.averageChaptersPerWeek.toStringAsFixed(1),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metrics});

  final List<(String label, String value)> metrics;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < metrics.length; i++) ...[
          if (i > 0) Container(width: 1, height: 34, color: cs.outlineVariant),
          Expanded(
            child: Column(
              children: [
                Text(
                  metrics[i].$2,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metrics[i].$1,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: cs.outline),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
