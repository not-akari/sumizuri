import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/features/library/models/upcoming_release.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/statistics/providers/statistics_providers.dart';
import 'package:sumizuri/features/statistics/widgets/calendar_day_cell.dart';

class CalendarMonthView extends ConsumerWidget {
  const CalendarMonthView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final l10n = AppLocalizations.of(context)!;

    final currentMonth = ref.watch(calendarMonthProvider);
    final selectedDate = ref.watch(calendarSelectedDateProvider);
    final releasesAsync = ref.watch(upcomingReleasesByDayProvider);
    final releasesByDay = releasesAsync.value ?? const {};

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final isCurrentMonth =
        currentMonth.year == now.year && currentMonth.month == now.month;

    final firstDayOfMonth = DateTime(currentMonth.year, currentMonth.month, 1);
    final leadingPadding = firstDayOfMonth.weekday - 1;
    final daysInMonth = DateTime(
      currentMonth.year,
      currentMonth.month + 1,
      0,
    ).day;
    final totalCells = ((leadingPadding + daysInMonth + 6) ~/ 7) * 7;

    var monthActualCount = 0;
    var monthUpcomingCount = 0;
    for (int d = 1; d <= daysInMonth; d++) {
      final date = DateTime(currentMonth.year, currentMonth.month, d);
      for (final r in releasesByDay[date] ?? const <UpcomingRelease>[]) {
        if (r.kind == ReleaseKind.actual) {
          monthActualCount++;
        } else {
          monthUpcomingCount++;
        }
      }
    }

    final monthTitle = DateFormat.yMMMM().format(currentMonth);

    // Capped so day cells stay a comfortable size on wide screens instead of stretching.
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: AppCard(
          flattenWhenCompact: true,
          tone: AppCardTone.inset,
          child: Column(
            children: [
              if (releasesAsync.value == null)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      monthTitle,
                      style: TextStyle(
                        fontFamily: context.displayFont,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (!isCurrentMonth)
                    TextButton.icon(
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: const Icon(Icons.today_rounded, size: 16),
                      label: Text(l10n.calendarToday),
                      onPressed: () {
                        ref
                            .read(calendarMonthProvider.notifier)
                            .resetToCurrent();
                        ref
                            .read(calendarSelectedDateProvider.notifier)
                            .resetToToday();
                      },
                    ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_left_rounded),
                    tooltip: AppLocalizations.of(context)!
                        .statisticPreviousMonth,
                    onPressed: () => ref
                        .read(calendarMonthProvider.notifier)
                        .previousMonth(),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.chevron_right_rounded),
                    tooltip: AppLocalizations.of(context)!.statisticNextMonth,
                    onPressed: () =>
                        ref.read(calendarMonthProvider.notifier).nextMonth(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  for (final dayName in const [
                    'M',
                    'T',
                    'W',
                    'T',
                    'F',
                    'S',
                    'S',
                  ])
                    Expanded(
                      child: Center(
                        child: Text(
                          dayName,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: cs.outline,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: totalCells,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                ),
                itemBuilder: (context, index) {
                  if (index < leadingPadding ||
                      index >= leadingPadding + daysInMonth) {
                    return const SizedBox.shrink();
                  }

                  final dayNumber = index - leadingPadding + 1;
                  final date = DateTime(
                    currentMonth.year,
                    currentMonth.month,
                    dayNumber,
                  );
                  final isSelected =
                      selectedDate.year == date.year &&
                      selectedDate.month == date.month &&
                      selectedDate.day == date.day;
                  final isTodayDate =
                      today.year == date.year &&
                      today.month == date.month &&
                      today.day == date.day;
                  final dayReleases =
                      releasesByDay[date] ?? const <UpcomingRelease>[];
                  final actualCount = dayReleases
                      .where((r) => r.kind == ReleaseKind.actual)
                      .length;
                  final hasPredicted = dayReleases.any(
                    (r) => r.kind == ReleaseKind.predicted,
                  );

                  return CalendarDayCell(
                    dayNumber: dayNumber,
                    isSelected: isSelected,
                    isToday: isTodayDate,
                    isFuture: date.isAfter(today),
                    actualCount: actualCount,
                    hasPredicted: hasPredicted,
                    onTap: () => ref
                        .read(calendarSelectedDateProvider.notifier)
                        .selectDate(date),
                  );
                },
              ),
              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Text(
                    l10n.calendarReleasesCount(monthActualCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  Text('•', style: TextStyle(color: cs.outlineVariant)),
                  Text(
                    l10n.calendarUpcomingCount(monthUpcomingCount),
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
