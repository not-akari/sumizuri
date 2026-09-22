import 'package:sumizuri/core/utils/formatting/series_status_bucket.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/library_entry_summary.dart';

enum CategorySortField { title, unreadCount, addedAt, lastUpdatedAt }

enum CategoryStatusFilter { any, ongoing, completed, hiatus }

List<LibraryEntrySummary> applyCategorySmartRule(
  List<LibraryEntrySummary> entries,
  Category category,
) {
  if (!category.useSmartRule) return entries;

  final filtered = category.statusFilter == CategoryStatusFilter.any
      ? entries
      : entries
            .where((e) => _matchesStatusFilter(e.status, category.statusFilter))
            .toList();

  return sortLibraryEntries(
    filtered,
    category.sortField,
    category.sortAscending,
  );
}

List<LibraryEntrySummary> sortLibraryEntries(
  List<LibraryEntrySummary> entries,
  CategorySortField sortField,
  bool sortAscending,
) {
  final sorted = [...entries];
  sorted.sort((a, b) {
    final cmp = switch (sortField) {
      CategorySortField.title => a.title.toLowerCase().compareTo(
        b.title.toLowerCase(),
      ),
      CategorySortField.unreadCount => a.unreadCount.compareTo(b.unreadCount),
      CategorySortField.addedAt => a.addedAt.compareTo(b.addedAt),
      CategorySortField.lastUpdatedAt => a.lastUpdatedAt.compareTo(
        b.lastUpdatedAt,
      ),
    };
    return sortAscending ? cmp : -cmp;
  });
  return sorted;
}

bool _matchesStatusFilter(String? status, CategoryStatusFilter filter) {
  final bucket = classifySeriesStatus(status);
  return switch (filter) {
    CategoryStatusFilter.any => true,
    CategoryStatusFilter.ongoing => bucket == SeriesStatusBucket.ongoing,
    CategoryStatusFilter.completed => bucket == SeriesStatusBucket.completed,
    CategoryStatusFilter.hiatus => bucket == SeriesStatusBucket.hiatus,
  };
}
