import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';

part 'library_settings_providers.g.dart';

@riverpod
Stream<bool> chapterSortAscending(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchChapterSortAscending();
}

@riverpod
Stream<bool> hideAllCategoryChip(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchHideAllCategoryChip();
}

@riverpod
Stream<bool> hideUncategorizedCategoryChip(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchHideUncategorizedCategoryChip();
}

@riverpod
Stream<CategorySortField> librarySortField(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchLibrarySortField();
}

@riverpod
Stream<bool> librarySortAscending(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchLibrarySortAscending();
}

@riverpod
Stream<bool> downloadsWifiOnly(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchDownloadsWifiOnly();
}

@riverpod
Stream<int> autoDownloadChapterLimit(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAutoDownloadChapterLimit();
}

@riverpod
Stream<int> keepDownloadsBehind(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchKeepDownloadsBehind();
}

@riverpod
Stream<int> downloadDelaySeconds(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchDownloadDelaySeconds();
}

@riverpod
Stream<bool> categoriesEnabled(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchCategoriesEnabled();
}

@riverpod
Stream<bool> autoDownloadOnLibraryUpdate(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAutoDownloadOnLibraryUpdate();
}

@riverpod
Stream<bool> autoDownloadOnAddToLibrary(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAutoDownloadOnAddToLibrary();
}

@riverpod
Stream<ChapterListLayout> chapterListLayout(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchChapterListLayout();
}

@riverpod
Stream<int> autoLibraryUpdateIntervalHours(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchAutoLibraryUpdateIntervalHours();
}

@riverpod
Stream<List<DashboardSectionKind>> dashboardSectionOrder(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchDashboardSectionOrder();
}

@riverpod
Stream<LibraryGridTileSize> libraryGridTileSize(Ref ref) {
  final repository = ref.watch(settingsRepositoryProvider);
  return repository.watchLibraryGridTileSize();
}
