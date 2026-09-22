import 'dart:convert';

import 'package:sumizuri/features/settings/models/backup_data.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/library/models/dashboard_section_kind.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/core/navigation/nav_destination_kind.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/data/enum_list_codec.dart';

const backupFormatVersion = 2;

String encodeBackup(BackupData data) => jsonEncode({
  'backupVersion': backupFormatVersion,
  'createdAt': data.createdAt.toIso8601String(),
  'settings': _settingsToJson(data.settings),
  'sources': data.sources.map(_sourceToJson).toList(),
  'categories': data.categories.map(_categoryToJson).toList(),
  'libraryEntries': data.libraryEntries.map(_entryToJson).toList(),
  'customThemes': data.customThemes,
  'extraSettings': data.extraSettings,
});

Result<BackupData, AppFailure> decodeBackup(String text) {
  try {
    final json = jsonDecode(text) as Map<String, dynamic>;
    final version = json['backupVersion'] as int?;
    if (version == null || version > backupFormatVersion) {
      return Err(
        ExtensionFailure('Unsupported backup file (version $version).'),
      );
    }
    return Ok(
      BackupData(
        createdAt: DateTime.parse(json['createdAt'] as String),
        settings: _settingsFromJson(
          (json['settings'] as Map).cast<String, dynamic>(),
        ),
        sources: (json['sources'] as List)
            .map((e) => _sourceFromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        categories: (json['categories'] as List)
            .map((e) => _categoryFromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        libraryEntries: (json['libraryEntries'] as List)
            .map((e) => _entryFromJson((e as Map).cast<String, dynamic>()))
            .toList(),
        customThemes: [
          for (final t in (json['customThemes'] as List? ?? const []))
            (t as Map).cast<String, Object?>(),
        ],
        extraSettings:
            (json['extraSettings'] as Map?)?.cast<String, Object?>() ??
            const {},
      ),
    );
  } catch (error) {
    return Err(ExtensionFailure('Not a valid backup file: $error'));
  }
}

Map<String, Object?> _settingsToJson(BackupSettings s) => {
  'themeScheme': s.themeScheme,
  'darkModePreference': s.darkModePreference.name,
  'amoledDark': s.amoledDark,
  'colorIntensity': s.colorIntensity.name,
  'libraryMode': s.libraryMode.name,
  'enabledMediaTypes': encodeEnumList(s.enabledMediaTypes),
  'navDestinationsOrder': encodeEnumList(s.navDestinationsOrder),
  'dashboardSectionOrder': encodeEnumList(s.dashboardSectionOrder),
  'readerMode': s.readerMode.name,
  'readerScaleType': s.readerScaleType.name,
  'readerBackground': s.readerBackground.name,
  'readerPageGap': s.readerPageGap.name,
  'readerInvertTaps': s.readerInvertTaps,
  'readerDualPageMode': s.readerDualPageMode.name,
  'libraryGridTileSize': s.libraryGridTileSize.name,
};

T _byName<T extends Enum>(List<T> values, String? name, T fallback) =>
    values.firstWhere((v) => v.name == name, orElse: () => fallback);

BackupSettings _settingsFromJson(Map<String, dynamic> json) => BackupSettings(
  themeScheme: json['themeScheme'] as String? ?? 'sumizuriInk',
  darkModePreference: _byName(
    AppDarkModePreference.values,
    json['darkModePreference'] as String?,
    AppDarkModePreference.system,
  ),
  amoledDark: json['amoledDark'] as bool? ?? false,
  colorIntensity: _byName(
    ColorIntensity.values,
    json['colorIntensity'] as String?,
    ColorIntensity.medium,
  ),
  libraryMode: _byName(
    AppLibraryMode.values,
    json['libraryMode'] as String?,
    AppLibraryMode.unified,
  ),
  enabledMediaTypes: decodeEnumList(
    json['enabledMediaTypes'] as String? ?? 'manga',
    MediaType.values,
  ).toSet(),
  navDestinationsOrder: decodeEnumList(
    json['navDestinationsOrder'] as String? ?? '',
    NavDestinationKind.values,
  ).toList(),
  dashboardSectionOrder: decodeEnumList(
    json['dashboardSectionOrder'] as String? ?? '',
    DashboardSectionKind.values,
  ).toList(),
  readerMode: _byName(
    ReaderMode.values,
    json['readerMode'] as String?,
    ReaderMode.rightToLeft,
  ),
  readerScaleType: _byName(
    ReaderScaleType.values,
    json['readerScaleType'] as String?,
    ReaderScaleType.fitWidth,
  ),
  readerBackground: _byName(
    ReaderBackground.values,
    json['readerBackground'] as String?,
    ReaderBackground.black,
  ),
  readerPageGap: _byName(
    ReaderPageGap.values,
    json['readerPageGap'] as String?,
    ReaderPageGap.none,
  ),
  readerInvertTaps: json['readerInvertTaps'] as bool? ?? false,
  readerDualPageMode: _byName(
    ReaderDualPageMode.values,
    json['readerDualPageMode'] as String?,
    ReaderDualPageMode.off,
  ),
  libraryGridTileSize: _byName(
    LibraryGridTileSize.values,
    json['libraryGridTileSize'] as String?,
    LibraryGridTileSize.medium,
  ),
);

Map<String, Object?> _sourceToJson(BackupSource s) => {
  'name': s.name,
  'lang': s.lang,
  'mediaType': s.mediaType.name,
  'jsSource': s.jsSource,
  'iconUrl': s.iconUrl,
  'baseUrl': s.baseUrl,
  'engineKind': s.engineKind.name,
  'enabled': s.enabled,
};

BackupSource _sourceFromJson(Map<String, dynamic> json) => BackupSource(
  name: json['name'] as String,
  lang: json['lang'] as String,
  mediaType: _byName(
    MediaType.values,
    json['mediaType'] as String?,
    MediaType.manga,
  ),
  jsSource: json['jsSource'] as String,
  iconUrl: json['iconUrl'] as String? ?? '',
  baseUrl: json['baseUrl'] as String? ?? '',
  engineKind: _byName(
    EngineKind.values,
    json['engineKind'] as String?,
    EngineKind.js,
  ),
  enabled: json['enabled'] as bool? ?? true,
);

Map<String, Object?> _categoryToJson(BackupCategory c) => {
  'name': c.name,
  'sortOrder': c.sortOrder,
  'excludeFromUpdate': c.excludeFromUpdate,
  'mediaType': c.mediaType.name,
  'useSmartRule': c.useSmartRule,
  'sortField': c.sortField.name,
  'sortAscending': c.sortAscending,
  'statusFilter': c.statusFilter.name,
};

BackupCategory _categoryFromJson(Map<String, dynamic> json) => BackupCategory(
  name: json['name'] as String,
  sortOrder: json['sortOrder'] as int? ?? 0,
  excludeFromUpdate: json['excludeFromUpdate'] as bool? ?? false,
  mediaType: _byName(
    MediaType.values,
    json['mediaType'] as String?,
    MediaType.manga,
  ),
  useSmartRule: json['useSmartRule'] as bool? ?? false,
  sortField: _byName(
    CategorySortField.values,
    json['sortField'] as String?,
    CategorySortField.title,
  ),
  sortAscending: json['sortAscending'] as bool? ?? true,
  statusFilter: _byName(
    CategoryStatusFilter.values,
    json['statusFilter'] as String?,
    CategoryStatusFilter.any,
  ),
);

Map<String, Object?> _chapterToJson(ChapterRecord c) => {
  'url': c.url,
  'number': c.number,
  'title': c.title,
  'dateUploaded': c.dateUploaded?.toIso8601String(),
  'consumed': c.consumed,
  'consumedAt': c.consumedAt?.toIso8601String(),
  'progressPosition': c.progressPosition,
  if (c.bookmarked) 'bookmarked': true,
};

ChapterRecord _chapterFromJson(Map<String, dynamic> json) => ChapterRecord(
  url: json['url'] as String,
  number: (json['number'] as num?)?.toDouble() ?? 0,
  title: json['title'] as String?,
  dateUploaded: (json['dateUploaded'] as String?) == null
      ? null
      : DateTime.parse(json['dateUploaded'] as String),
  consumed: json['consumed'] as bool? ?? false,
  consumedAt: (json['consumedAt'] as String?) == null
      ? null
      : DateTime.parse(json['consumedAt'] as String),
  progressPosition: (json['progressPosition'] as num?)?.toDouble(),
  bookmarked: json['bookmarked'] as bool? ?? false,
);

Map<String, Object?> _entryToJson(BackupLibraryEntry e) => {
  'title': e.title,
  'coverUrl': e.coverUrl,
  'mediaType': e.mediaType.name,
  'favorite': e.favorite,
  'sourceName': e.sourceName,
  'sourceBaseUrl': e.sourceBaseUrl,
  'externalId': e.externalId,
  'categoryNames': e.categoryNames,
  'chapters': e.chapters.map(_chapterToJson).toList(),
  'sessions': [
    for (final s in e.sessions)
      {'url': s.chapterUrl, 'readAt': s.readAt.toIso8601String()},
  ],
};

BackupLibraryEntry _entryFromJson(Map<String, dynamic> json) =>
    BackupLibraryEntry(
      title: json['title'] as String,
      coverUrl: json['coverUrl'] as String?,
      mediaType: _byName(
        MediaType.values,
        json['mediaType'] as String?,
        MediaType.manga,
      ),
      favorite: json['favorite'] as bool? ?? false,
      sourceName: json['sourceName'] as String,
      sourceBaseUrl: json['sourceBaseUrl'] as String,
      externalId: json['externalId'] as String,
      categoryNames:
          (json['categoryNames'] as List?)?.cast<String>() ?? const [],
      chapters: (json['chapters'] as List? ?? const [])
          .map((e) => _chapterFromJson((e as Map).cast<String, dynamic>()))
          .toList(),
      sessions: [
        for (final s in (json['sessions'] as List? ?? const []))
          (
            chapterUrl: (s as Map)['url'] as String,
            readAt: DateTime.parse(s['readAt'] as String),
          ),
      ],
    );
