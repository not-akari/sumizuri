import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/settings/data/db_file_backup.dart'
    as db_file_backup;
import 'package:sumizuri/features/settings/data/backup_codec.dart';
import 'package:sumizuri/core/theming/custom_theme.dart';
import 'package:sumizuri/core/utils/formatting/timestamps.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/data/backup_extra_settings.dart';
import 'package:sumizuri/features/settings/data/backup_preferences.dart';
import 'package:sumizuri/features/settings/models/backup_data.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/theme_editor/data/theme_editor_providers.dart';

part 'backup_service.g.dart';

// Kept alive to support multi-step sequential async backup and restore flows.
@Riverpod(keepAlive: true)
BackupService backupService(Ref ref) => BackupService(ref);

/// Builds a backup from the current data, restores one, and writes the automatic copies.
class BackupService {
  BackupService(this.ref);

  final Ref ref;

  Future<BackupData> build() async {
    final libraryRepository = ref.read(libraryRepositoryProvider);
    final settingsRepository = ref.read(settingsRepositoryProvider);
    final sourceRepository = ref.read(installedSourceRepositoryProvider);

    final sources = await sourceRepository.watchAll().first;
    final categories = await libraryRepository.watchCategories().first;
    final entries = await libraryRepository.watchLibrary().first;

    final sourceById = {for (final source in sources) source.id: source};

    final backupEntries = <BackupLibraryEntry>[];
    for (final entry in entries) {
      final source = sourceById[int.tryParse(entry.sourceId)];
      if (source == null) continue;
      final categoryIds = await libraryRepository
          .watchEntryCategoryIds(entry.id)
          .first;
      final categoryNames = [
        for (final category in categories)
          if (categoryIds.contains(category.id)) category.name,
      ];
      final chapters =
          (await libraryRepository.getAllChapters(entry.id)).valueOrNull ??
          const [];
      final sessions =
          (await libraryRepository.getReadingSessions(entry.id)).valueOrNull ??
          const [];
      backupEntries.add(
        BackupLibraryEntry(
          title: entry.title,
          coverUrl: entry.coverUrl,
          mediaType: entry.mediaType,
          favorite: entry.favorite,
          sourceName: source.name,
          sourceBaseUrl: source.baseUrl,
          externalId: entry.externalId,
          categoryNames: categoryNames,
          chapters: chapters,
          sessions: sessions,
        ),
      );
    }

    final themes = await ref.read(customThemesProvider.future);
    final extraSettings = await readExtraSettings(settingsRepository);

    return BackupData(
      createdAt: DateTime.now(),
      customThemes: [for (final t in themes) t.toJson()],
      extraSettings: extraSettings,
      settings: BackupSettings(
        themeScheme: await settingsRepository.watchThemeScheme().first,
        darkModePreference: await settingsRepository
            .watchDarkModePreference()
            .first,
        amoledDark: await settingsRepository.watchAmoledDark().first,
        colorIntensity: await settingsRepository.watchColorIntensity().first,
        libraryMode: await settingsRepository.watchLibraryMode().first,
        enabledMediaTypes: await settingsRepository
            .watchEnabledMediaTypes()
            .first,
        navDestinationsOrder: await settingsRepository
            .watchNavDestinations()
            .first,
        dashboardSectionOrder: await settingsRepository
            .watchDashboardSectionOrder()
            .first,
        readerMode: await settingsRepository.watchReaderMode().first,
        readerScaleType: await settingsRepository.watchReaderScaleType().first,
        readerBackground: await settingsRepository
            .watchReaderBackground()
            .first,
        readerPageGap: await settingsRepository.watchReaderPageGap().first,
        readerInvertTaps: await settingsRepository
            .watchReaderInvertTaps()
            .first,
        readerDualPageMode: await settingsRepository
            .watchReaderDualPageMode()
            .first,
        libraryGridTileSize: await settingsRepository
            .watchLibraryGridTileSize()
            .first,
      ),
      sources: [
        for (final source in sources)
          BackupSource(
            name: source.name,
            lang: source.lang,
            mediaType: source.mediaType,
            jsSource: source.jsSource,
            iconUrl: source.iconUrl,
            baseUrl: source.baseUrl,
            engineKind: source.engineKind,
            enabled: source.enabled,
          ),
      ],
      categories: [
        for (final category in categories)
          BackupCategory(
            name: category.name,
            sortOrder: category.sortOrder,
            excludeFromUpdate: category.excludeFromUpdate,
            mediaType: category.mediaType,
            useSmartRule: category.useSmartRule,
            sortField: category.sortField,
            sortAscending: category.sortAscending,
            statusFilter: category.statusFilter,
          ),
      ],
      libraryEntries: backupEntries,
    );
  }

  Future<(int, int)> restore(BackupData data) async {
    final logger = ref.read(appLoggerProvider);
    final settingsRepository = ref.read(settingsRepositoryProvider);
    final sourceRepository = ref.read(installedSourceRepositoryProvider);
    final libraryRepository = ref.read(libraryRepositoryProvider);

    // Themes first, so a restored "custom:" choice points at something that exists.
    for (final json in data.customThemes) {
      try {
        await ref
            .read(customThemesProvider.notifier)
            .save(CustomTheme.fromJson(json));
      } catch (_) {
        continue;
      }
    }
    await applyExtraSettings(settingsRepository, data.extraSettings);
    await settingsRepository.setThemeScheme(data.settings.themeScheme);
    await settingsRepository.setDarkModePreference(
      data.settings.darkModePreference,
    );
    await settingsRepository.setAmoledDark(data.settings.amoledDark);
    await settingsRepository.setColorIntensity(data.settings.colorIntensity);
    await settingsRepository.setLibraryMode(data.settings.libraryMode);
    await settingsRepository.setEnabledMediaTypes(
      data.settings.enabledMediaTypes,
    );
    await settingsRepository.setNavDestinations(
      data.settings.navDestinationsOrder,
    );
    await settingsRepository.setDashboardSectionOrder(
      data.settings.dashboardSectionOrder,
    );
    await settingsRepository.setReaderMode(data.settings.readerMode);
    await settingsRepository.setReaderScaleType(data.settings.readerScaleType);
    await settingsRepository.setReaderBackground(
      data.settings.readerBackground,
    );
    await settingsRepository.setReaderPageGap(data.settings.readerPageGap);
    await settingsRepository.setReaderInvertTaps(
      data.settings.readerInvertTaps,
    );
    await settingsRepository.setReaderDualPageMode(
      data.settings.readerDualPageMode,
    );
    await settingsRepository.setLibraryGridTileSize(
      data.settings.libraryGridTileSize,
    );

    final sourceIds = <(String, String), int>{};
    final existingSources = await sourceRepository.watchAll().first;
    for (final source in data.sources) {
      final matches = existingSources.where(
        (s) => s.name == source.name && s.baseUrl == source.baseUrl,
      );
      if (matches.isNotEmpty) {
        sourceIds[(source.name, source.baseUrl)] = matches.first.id;
        continue;
      }
      final result = await sourceRepository.add(
        name: source.name,
        lang: source.lang,
        mediaType: source.mediaType,
        jsSource: source.jsSource,
        iconUrl: source.iconUrl,
        baseUrl: source.baseUrl,
        engineKind: source.engineKind,
      );
      final newId = result.valueOrNull;
      if (newId != null) sourceIds[(source.name, source.baseUrl)] = newId;
    }

    final categoryIds = <(String, MediaType), int>{};
    final existingCategories = await libraryRepository.watchCategories().first;
    for (final category in data.categories) {
      final matches = existingCategories.where(
        (c) => c.name == category.name && c.mediaType == category.mediaType,
      );
      if (matches.isNotEmpty) {
        categoryIds[(category.name, category.mediaType)] = matches.first.id;
        continue;
      }
      final result = await libraryRepository.createCategory(
        category.name,
        mediaType: category.mediaType,
      );
      final newId = result.valueOrNull;
      if (newId != null) {
        categoryIds[(category.name, category.mediaType)] = newId;
        await libraryRepository.setCategoryExcludeFromUpdate(
          id: newId,
          exclude: category.excludeFromUpdate,
        );
        await libraryRepository.setCategorySmartRule(
          id: newId,
          useSmartRule: category.useSmartRule,
          sortField: category.sortField,
          sortAscending: category.sortAscending,
          statusFilter: category.statusFilter,
        );
      }
    }

    var restored = 0;
    var skipped = 0;
    for (final entry in data.libraryEntries) {
      final sourceId = sourceIds[(entry.sourceName, entry.sourceBaseUrl)];
      if (sourceId == null) {
        skipped++;
        logger.warning(
          'Skipped restoring "${entry.title}": source "${entry.sourceName}" not in this backup',
          tag: 'backup',
        );
        continue;
      }

      final existing = await libraryRepository.checkLibraryMatch(
        title: entry.title,
        sourceId: sourceId.toString(),
        externalId: entry.externalId,
      );
      final existingMatch = existing.valueOrNull;
      if (existingMatch?.hasPossibleDuplicates ?? false) {
        // Skip duplicate entries already in library under a different source.
        skipped++;
        logger.warning(
          'Skipped restoring "${entry.title}": already in the library from another source',
          tag: 'backup',
        );
        continue;
      }

      var entryId = existingMatch?.exactMatchId;
      if (entryId == null) {
        await libraryRepository.addToLibrary(
          title: entry.title,
          coverUrl: entry.coverUrl,
          mediaType: entry.mediaType,
          sourceId: sourceId.toString(),
          externalId: entry.externalId,
        );
        final match = await libraryRepository.checkLibraryMatch(
          title: entry.title,
          sourceId: sourceId.toString(),
          externalId: entry.externalId,
        );
        entryId = match.valueOrNull?.exactMatchId;
      }
      if (entryId == null) {
        skipped++;
        continue;
      }

      await libraryRepository.restoreChapters(
        libraryEntryId: entryId,
        chapters: entry.chapters,
      );
      await libraryRepository.restoreReadingSessions(
        libraryEntryId: entryId,
        sessions: entry.sessions,
      );
      final entryCategoryIds = {
        for (final name in entry.categoryNames)
          if (categoryIds[(name, entry.mediaType)] != null)
            categoryIds[(name, entry.mediaType)]!,
      };
      await libraryRepository.setEntryCategories(
        entryId: entryId,
        categoryIds: entryCategoryIds,
      );
      restored++;
    }

    return (restored, skipped);
  }

  /// Replaces the current database with a saved copy. The app has to restart afterwards.
  Future<void> restoreDatabaseFile(File backup) async {
    await ref.read(appDatabaseProvider).close();
    await db_file_backup.restoreBackup(backup);
  }

  Future<File> writeAuto({required int keep}) async {
    final data = await build();
    final dir = await autoBackupsDirectory();
    final stamp = fileStamp();
    final file = File(
      p.join(dir.path, 'sumizuri_auto_$stamp.$backupFileExtension'),
    );
    await file.writeAsString(encodeBackup(data));
    await pruneAutoBackups(keep);
    return file;
  }
}
