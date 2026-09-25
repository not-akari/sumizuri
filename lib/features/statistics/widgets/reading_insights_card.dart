import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class ReadingInsightsCard extends StatelessWidget {
  const ReadingInsightsCard({super.key, required this.stats});

  final ReadingStats stats;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    final eta = stats.estimatedWeeksToClearBacklog;
    final activeDay = stats.mostActiveWeekday == null
        ? null
        : DateFormat.EEEE().format(DateTime(2024, 1, stats.mostActiveWeekday!));
    final activeTime = switch (stats.mostActiveTimeOfDay) {
      null => null,
      TimeOfDayBucket.morning => l10n.statsTimeMorning,
      TimeOfDayBucket.afternoon => l10n.statsTimeAfternoon,
      TimeOfDayBucket.evening => l10n.statsTimeEvening,
      TimeOfDayBucket.night => l10n.statsTimeNight,
    };

    return AppCard(
      flattenWhenCompact: true,
      tone: AppCardTone.inset,
      title: l10n.statsInsights,
      titleGap: 10,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _InsightRow(
            label: l10n.statsBacklog,
            value: l10n.statsChaptersCount(stats.totalUnreadChapters),
            caption: eta == null
                ? null
                : eta == 0
                ? l10n.statsBacklogCleared
                : l10n.statsBacklogEta(_formatDuration(eta, l10n)),
          ),
          if (stats.totalSessions > 0)
            _InsightRow(
              label: l10n.statsReReads,
              value: l10n.statsReReadsFraction(
                stats.totalReReadSessions,
                stats.totalSessions,
              ),
            ),
          if (activeDay != null)
            _InsightRow(label: l10n.statsMostActiveDay, value: activeDay),
          if (activeTime != null)
            _InsightRow(label: l10n.statsMostActiveTime, value: activeTime),
        ],
      ),
    );
  }

  static String _formatDuration(double weeks, AppLocalizations l10n) {
    if (weeks < 8) return l10n.statsWeeksCount(weeks.ceil());
    if (weeks < 104) return l10n.statsMonthsCount((weeks / 4.345).round());
    return l10n.statsYearsCount((weeks / 52).round());
  }
}

class _InsightRow extends StatelessWidget {
  const _InsightRow({required this.label, required this.value, this.caption});

  final String label;
  final String value;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
              Text(
                value,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cs.primary,
                ),
              ),
            ],
          ),
          if (caption != null)
            Text(caption!, style: TextStyle(fontSize: 11, color: cs.outline)),
        ],
      ),
    );
  }
}
