import 'dart:isolate';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/features/library/models/upcoming_release.dart';
import 'package:sumizuri/features/library/models/upcoming_releases_calculator.dart';
import 'package:sumizuri/features/statistics/models/reading_statistics.dart';
import 'package:sumizuri/features/statistics/models/reading_stats_calculator.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

part 'statistics_providers.g.dart';

/// Worked out off the UI thread, since it walks every reading session.
final readingStatisticsProvider = FutureProvider.autoDispose<ReadingStats>((
  ref,
) async {
  final sessions = ref.watch(allReadingSessionsProvider).value ?? const [];
  final entries = ref.watch(libraryEntriesProvider()).value ?? const [];
  return Isolate.run(
    () =>
        ReadingStatsCalculator.calculate(sessions: sessions, entries: entries),
  );
});

@riverpod
class CalendarMonthNotifier extends _$CalendarMonthNotifier {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month);
  }

  void nextMonth() {
    state = DateTime(state.year, state.month + 1);
  }

  void previousMonth() {
    state = DateTime(state.year, state.month - 1);
  }

  void resetToCurrent() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month);
  }
}

@riverpod
class CalendarCategory extends _$CalendarCategory {
  @override
  int? build() => null;

  void choose(int? category) => state = category;
}

@riverpod
class CalendarSelectedDateNotifier extends _$CalendarSelectedDateNotifier {
  @override
  DateTime build() {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void selectDate(DateTime date) {
    state = DateTime(date.year, date.month, date.day);
  }

  void resetToToday() {
    final now = DateTime.now();
    state = DateTime(now.year, now.month, now.day);
  }
}

final upcomingReleasesByDayProvider =
    FutureProvider.autoDispose<Map<DateTime, List<UpcomingRelease>>>((
      ref,
    ) async {
      var chapters = ref.watch(allChapterDatesProvider()).value ?? const [];
      final chosen = ref.watch(calendarCategoryProvider);
      final category =
          ref.watch(visibleCategoriesProvider()).any((c) => c.id == chosen)
          ? chosen
          : null;
      if (category != null) {
        final membership =
            ref.watch(allEntryCategoryIdsProvider).value ?? const {};
        chapters = [
          for (final c in chapters)
            if (membership[c.libraryEntryId]?.contains(category) ?? false) c,
        ];
      }
      return Isolate.run(() {
        final byDay = <DateTime, List<UpcomingRelease>>{};
        for (final r in UpcomingReleasesCalculator.calculate(chapters)) {
          byDay.putIfAbsent(r.date, () => []).add(r);
        }
        return byDay;
      });
    });

@riverpod
List<UpcomingRelease> calendarSelectedDayReleases(Ref ref) {
  final byDay = ref.watch(upcomingReleasesByDayProvider).value ?? const {};
  final selectedDate = ref.watch(calendarSelectedDateProvider);
  final target = DateTime(
    selectedDate.year,
    selectedDate.month,
    selectedDate.day,
  );
  return [...?byDay[target]]
    ..sort((a, b) => a.entryTitle.compareTo(b.entryTitle));
}
