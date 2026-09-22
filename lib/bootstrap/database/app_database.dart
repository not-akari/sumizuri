// Defines the Drift database, its tables and schema migrations for the whole app.
import 'dart:math';

import 'package:sumizuri/bootstrap/startup/startup_timer.dart';
import 'package:sumizuri/bootstrap/database/slow_query_interceptor.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
// ignore: depend_on_referenced_packages
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter/foundation.dart';

import 'package:sumizuri/bootstrap/database/tables/category_table.dart';
import 'package:sumizuri/bootstrap/database/tables/chapter_progress_table.dart';
import 'package:sumizuri/bootstrap/database/tables/content_unit_table.dart';
import 'package:sumizuri/bootstrap/database/tables/entry_branch_table.dart';
import 'package:sumizuri/bootstrap/database/tables/installed_source_table.dart';
import 'package:sumizuri/bootstrap/database/tables/library_entry_table.dart';
import 'package:sumizuri/bootstrap/database/tables/log_entry_table.dart';
import 'package:sumizuri/bootstrap/database/tables/profile_table.dart';
import 'package:sumizuri/bootstrap/database/tables/reading_session_table.dart';
import 'package:sumizuri/bootstrap/database/tables/setting_values_table.dart';
import 'package:sumizuri/bootstrap/startup/client_id.dart';
import 'package:sumizuri/bootstrap/database/sync_schema.dart';
import 'package:sumizuri/bootstrap/database/tracker_schema.dart';
import 'package:sumizuri/bootstrap/database/tables/tracker_tables.dart';
import 'package:sumizuri/bootstrap/database/tables/sync_tables.dart';
import 'package:sumizuri/bootstrap/database/tables/repo_table.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/settings/models/log_entry.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/settings/registry/setting_def.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';

part 'app_database.g.dart';

const appDatabaseSchemaVersion = 63;

// Databases older than this cannot be upgraded.
const oldestUpgradableSchemaVersion = 46;

@DriftDatabase(
  tables: [
    LibraryEntries,
    EntryBranches,
    ContentUnits,
    ChapterProgress,
    Categories,
    EntryCategories,
    LogEntries,
    InstalledSources,
    Repos,
    Profiles,
    ActiveProfileTable,
    SettingValues,
    ReadingSessions,
    SyncDeletions,
    SyncState,
    SyncProfileState,
    SyncFiles,
    TrackerLinks,
    TrackerOutbox,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection());

  @override
  int get schemaVersion => appDatabaseSchemaVersion;

  @visibleForTesting
  Future<void> moveLegacySettingsToRows() async {
    Future<bool> exists(String table) async => (await customSelect(
      "SELECT name FROM sqlite_master WHERE type = 'table' AND name = ?",
      variables: [Variable.withString(table)],
    ).get()).isNotEmpty;

    Future<void> copy(
      String table,
      Map<String, SettingDef<Object?>> columns, {
      required bool app,
    }) async {
      if (!await exists(table)) return;
      final rows = await customSelect(
        app ? 'SELECT * FROM $table WHERE id = 0' : 'SELECT * FROM $table',
      ).get();
      for (final row in rows) {
        final scope = app ? 0 : row.read<int>('profile_id');
        final stamp = row.data['updated_at'] as int? ?? 0;
        for (final entry in columns.entries) {
          if (!row.data.containsKey(entry.key)) continue;
          final def = entry.value;
          await customStatement(
            'INSERT OR IGNORE INTO setting_values '
            '(profile_id, setting_id, value, synced, updated_at) VALUES (?, ?, ?, ?, ?)',
            [
              scope,
              def.id,
              def.encode(def.fromLegacyColumn(row.data[entry.key])),
              def.sync ? 1 : 0,
              stamp,
            ],
          );
        }
      }
      await customStatement('DROP TABLE $table');
    }

    await copy('app_settings', Settings.legacyAppColumns, app: true);
    await copy('profile_settings', Settings.legacyProfileColumns, app: false);
  }

  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    ...super.allSchemaEntities,
    ...syncTriggers,
    ...settingValueTriggers,
    ...trackerTriggers,
  ];

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await into(
        profiles,
      ).insert(const ProfilesCompanion(id: Value(1), name: Value('Profile 1')));
      await into(activeProfileTable).insert(
        const ActiveProfileTableCompanion(id: Value(0), profileId: Value(1)),
      );
      await into(syncState).insert(
        SyncStateCompanion(
          id: const Value(0),
          installId: Value(_newInstallId()),
        ),
      );
      StartupTimer.instance.mark('database created');
    },
    onUpgrade: (m, from, to) async {
      if (from < oldestUpgradableSchemaVersion) {
        throw UnsupportedError(
          'This database is too old to upgrade (version $from). Reset the app data.',
        );
      }
      if (from < 47) {
        await m.addColumn(libraryEntries, libraryEntries.sourceKey);
      }
      if (from < 53) {
        await m.addColumn(contentUnits, contentUnits.bookmarked);
      }
      if (from < 54) {
        await m.createTable(settingValues);
        await m.createIndex(idxSettingValuesSetting);
      } else if (from < 55) {
        await m.addColumn(settingValues, settingValues.updatedAt);
        for (final name in const ['insert', 'update', 'delete']) {
          await customStatement(
            'DROP TRIGGER IF EXISTS trg_setting_values_sync_$name',
          );
        }
      }
      if (from < 55) {
        for (final trigger in settingValueTriggers) {
          await m.create(trigger);
        }
        await moveLegacySettingsToRows();
      }
      if (from < 56) {
        await m.addColumn(contentUnits, contentUnits.scanlator);
        await m.addColumn(libraryEntries, libraryEntries.excludedScanlators);
      }
      if (from < 57) {
        await m.addColumn(syncProfileState, syncProfileState.backgroundSync);
      }
      if (from < 59) {
        await customStatement('DROP TABLE IF EXISTS fake_migration_tests');
      }
      if (from < 58) {
        await m.createTable(trackerLinks);
        await m.createTable(trackerOutbox);
        for (final trigger in trackerTriggers) {
          await m.create(trigger);
        }
      }
      if (from < 60) {
        await _addColumnIfMissing(
          'library_entries',
          'reader_dual_page_mode',
          'INTEGER NULL',
        );
      }
      if (from < 61) {
        await _addColumnIfMissing(
          'library_entries',
          'settings_overrides',
          'TEXT NULL',
        );
      }
      if (from < 62) {
        // Drift DDL adds the required CHECK(0,1) constraint on bool column.
        await m.addColumn(libraryEntries, libraryEntries.readerModeChecked);
      }
      if (from < 63) {
        // Re-creates column with CHECK constraint if needed.
        final columns = await customSelect(
          'PRAGMA table_info(library_entries)',
        ).get();
        if (columns.any(
          (row) => row.read<String>('name') == 'reader_mode_checked',
        )) {
          await customStatement(
            'ALTER TABLE library_entries DROP COLUMN reader_mode_checked',
          );
        }
        await m.addColumn(libraryEntries, libraryEntries.readerModeChecked);
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');

      // A database that was just made from this code has nothing to check.
      if (kDebugMode && !details.wasCreated) {
        await validateDatabaseSchema();
        StartupTimer.instance.mark('schema check');
      }
      // Connection is open and ready for database queries.
      StartupTimer.instance.mark('database ready');
    },
  );

  // A step that adds a column must also work when the column is already there.
  Future<void> _addColumnIfMissing(
    String table,
    String column,
    String definition,
  ) async {
    final columns = await customSelect('PRAGMA table_info($table)').get();
    if (columns.any((row) => row.read<String>('name') == column)) return;
    await customStatement('ALTER TABLE $table ADD COLUMN $column $definition');
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      return NativeDatabase.createInBackground(await databaseFile())
          .interceptWith(SlowQueryInterceptor());
    });
  }
}

String _newInstallId() {
  final random = Random.secure();
  return List.generate(
    16,
    (_) => random.nextInt(256).toRadixString(16).padLeft(2, '0'),
  ).join();
}
