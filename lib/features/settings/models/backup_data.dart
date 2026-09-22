import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';

class BackupData {
  const BackupData({
    required this.createdAt,
    required this.settings,
    required this.sources,
    required this.categories,
    required this.libraryEntries,
    this.customThemes = const [],
    this.extraSettings = const {},
  });

  final DateTime createdAt;
  final BackupSettings settings;
  final List<BackupSource> sources;
  final List<BackupCategory> categories;
  final List<BackupLibraryEntry> libraryEntries;

  final List<Map<String, Object?>> customThemes;

  final Map<String, Object?> extraSettings;
}

class BackupSettings {
  const BackupSettings({
    required this.themeScheme,
    required this.darkModePreference,
    required this.amoledDark,
    required this.colorIntensity,
    required this.libraryMode,
    required this.enabledMediaTypes,
    required this.navDestinationsOrder,
    required this.dashboardSectionOrder,
    required this.readerMode,
    required this.readerScaleType,
    required this.readerBackground,
    required this.readerPageGap,
    required this.readerInvertTaps,
    required this.readerDualPageMode,
    required this.libraryGridTileSize,
  });

  final String themeScheme;
  final AppDarkModePreference darkModePreference;
  final bool amoledDark;
  final ColorIntensity colorIntensity;
  final AppLibraryMode libraryMode;
  final Set<MediaType> enabledMediaTypes;
  final List<NavDestinationKind> navDestinationsOrder;
  final List<DashboardSectionKind> dashboardSectionOrder;
  final ReaderMode readerMode;
  final ReaderScaleType readerScaleType;
  final ReaderBackground readerBackground;
  final ReaderPageGap readerPageGap;
  final bool readerInvertTaps;
  final ReaderDualPageMode readerDualPageMode;
  final LibraryGridTileSize libraryGridTileSize;
}

class BackupSource {
  const BackupSource({
    required this.name,
    required this.lang,
    required this.mediaType,
    required this.jsSource,
    required this.iconUrl,
    required this.baseUrl,
    required this.engineKind,
    required this.enabled,
  });

  final String name;
  final String lang;
  final MediaType mediaType;
  final String jsSource;
  final String iconUrl;
  final String baseUrl;
  final EngineKind engineKind;
  final bool enabled;
}

class BackupCategory {
  const BackupCategory({
    required this.name,
    required this.sortOrder,
    required this.excludeFromUpdate,
    required this.mediaType,
    this.useSmartRule = false,
    this.sortField = CategorySortField.title,
    this.sortAscending = true,
    this.statusFilter = CategoryStatusFilter.any,
  });

  final String name;
  final int sortOrder;
  final bool excludeFromUpdate;
  final MediaType mediaType;
  final bool useSmartRule;
  final CategorySortField sortField;
  final bool sortAscending;
  final CategoryStatusFilter statusFilter;
}

class BackupLibraryEntry {
  const BackupLibraryEntry({
    required this.title,
    this.coverUrl,
    required this.mediaType,
    required this.favorite,
    required this.sourceName,
    required this.sourceBaseUrl,
    required this.externalId,
    required this.categoryNames,
    required this.chapters,
    this.sessions = const [],
  });

  final String title;
  final String? coverUrl;
  final MediaType mediaType;
  final bool favorite;
  final String sourceName;
  final String sourceBaseUrl;
  final String externalId;
  final List<String> categoryNames;
  final List<ChapterRecord> chapters;

  final List<({String chapterUrl, DateTime readAt})> sessions;
}
