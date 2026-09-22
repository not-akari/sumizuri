import 'dart:convert';

import 'package:drift/drift.dart';

import 'package:path/path.dart' as p;
import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/features/library/models/scanlator_filter.dart';
import 'package:sumizuri/features/extensions/data/source_relink.dart';
import 'package:sumizuri/features/sync/data/sync_file_store.dart';

part 'sync_local_store_library.dart';
part 'sync_local_store_config.dart';

const syncEntities = [
  'settings',
  'appsettings',
  'sources',
  'repos',
  'categories',
  'entries',
  'branches',
  'chapters',
  'progress',
  'sessions',
  'files',
];

const settingsClientId = 1;

class SyncUpload {
  SyncUpload({required this.rows, required this.deleted, this.files});

  final Map<String, List<Map<String, dynamic>>> rows;
  final Map<String, List<int>> deleted;

  // Kept so a finished sync can record which files were sent.
  final SyncFileUpload? files;
}

class SyncLocalStore {
  SyncLocalStore(this._db, {this._files, this._coversPath});

  final AppDatabase _db;
  final SyncFileStore? _files;

  final Future<String> Function()? _coversPath;

  Future<int> activeProfileId() async {
    final active = await _db.select(_db.activeProfileTable).getSingle();
    return active.profileId;
  }

  /// This profile's sync bookkeeping. A profile that never synced reads as all defaults.
  Future<SyncProfileStateData> readState(int profileId) async {
    final row = await (_db.select(
      _db.syncProfileState,
    )..where((t) => t.profileId.equals(profileId))).getSingleOrNull();
    return row ??
        SyncProfileStateData(
          profileId: profileId,
          since: 0,
          localSince: 0,
          lastSyncAt: 0,
          autoSyncIntervalMinutes: 0,
          syncOnLaunch: true,
          backgroundSync: false,
        );
  }

  Future<List<SyncProfileStateData>> allStates() =>
      _db.select(_db.syncProfileState).get();

  Future<void> writeState(int profileId, SyncProfileStateCompanion values) =>
      _db
          .into(_db.syncProfileState)
          .insertOnConflictUpdate(values.copyWith(profileId: Value(profileId)));

  Future<void> clearAll() async {
    await _db.delete(_db.syncProfileState).go();
    await _db.delete(_db.syncDeletions).go();
  }

  Future<void> clearProfile(int profileId) async {
    await (_db.delete(
      _db.syncProfileState,
    )..where((t) => t.profileId.equals(profileId))).go();
    await (_db.delete(
      _db.syncDeletions,
    )..where((t) => t.profileId.equals(profileId))).go();
  }

  Future<SyncUpload> collect({
    required int profileId,
    required int since,
    int? forceUpdatedAt,
  }) async {
    await _ensureClientIds();
    final stamp = _Stamp(since, forceUpdatedAt);

    final categoryIds = await _clientIdsOf(
      'SELECT id, client_id FROM categories WHERE profile_id = ?',
      profileId,
    );
    final branchIds = await _clientIdsOf(
      'SELECT b.id, b.client_id FROM entry_branches b '
      'JOIN library_entries e ON e.id = b.library_entry_id WHERE e.profile_id = ?',
      profileId,
    );
    final entryIds = await _clientIdsOf(
      'SELECT id, client_id FROM library_entries WHERE profile_id = ?',
      profileId,
    );
    final chapterIds = await _clientIdsOf(
      'SELECT c.id, c.client_id FROM content_units c '
      'JOIN library_entries e ON e.id = c.library_entry_id WHERE e.profile_id = ?',
      profileId,
    );

    final sourceIds = await _sourceClientIds();
    final coversDir = await _coversPath?.call();

    final files = await _files?.collect(
      profileId: profileId,
      everything: forceUpdatedAt != null,
      forceUpdatedAt: forceUpdatedAt,
    );

    final rows = {
      'sources': await _sources(stamp),
      'repos': await _repos(stamp),
      'categories': await _categories(profileId, stamp),
      'entries': await _entries(
        profileId,
        stamp,
        categoryIds,
        branchIds,
        sourceIds,
        coversDir,
      ),
      'branches': await _branches(profileId, stamp, entryIds),
      'chapters': await _chapters(profileId, stamp, entryIds),
      'progress': await _progress(profileId, stamp, chapterIds, branchIds),
      'sessions': await _sessions(
        profileId,
        stamp,
        entryIds,
        chapterIds,
        branchIds,
      ),
      'settings': await _settings(profileId, stamp),
      'appsettings': await _appSettings(stamp),
      'files': files?.rows ?? <Map<String, dynamic>>[],
    };
    final deleted = forceUpdatedAt == null
        ? await _pendingDeletions(profileId)
        : <String, List<int>>{};
    final goneFiles = files?.deletedIds ?? const <int>[];
    if (goneFiles.isNotEmpty) {
      deleted['files'] = [...?deleted['files'], ...goneFiles];
    }
    return SyncUpload(rows: rows, deleted: deleted, files: files);
  }

  Future<String> installId() async {
    final row = await _db.select(_db.syncState).getSingle();
    final existing = row.installId;
    if (existing != null) return existing;
    await _db.customStatement(
      "UPDATE sync_state SET install_id = lower(hex(randomblob(16))) WHERE id = 0",
    );
    return (await _db.select(_db.syncState).getSingle()).installId!;
  }

  Future<void> commitUpload(int profileId, SyncUpload upload) async {
    await clearDeletions(profileId, upload.deleted);
    final files = upload.files;
    if (files != null) await _files?.commit(profileId, files);
  }

  Future<void> clearDeletions(
    int profileId,
    Map<String, List<int>> uploaded,
  ) async {
    await _db.batch((batch) {
      for (final entry in uploaded.entries) {
        batch.deleteWhere(
          _db.syncDeletions,
          (t) =>
              t.profileId.equals(profileId) &
              t.entity.equals(entry.key) &
              t.clientId.isIn(entry.value),
        );
      }
    });
  }

  Future<Map<String, List<int>>> _pendingDeletions(int profileId) async {
    final result = <String, List<int>>{};
    final rows = await (_db.select(
      _db.syncDeletions,
    )..where((t) => t.profileId.equals(profileId))).get();
    for (final row in rows) {
      (result[row.entity] ??= []).add(row.clientId);
    }
    return result;
  }

  Future<void> _ensureClientIds() async {
    for (final table in const [
      'categories',
      'library_entries',
      'entry_branches',
      'content_units',
      'chapter_progress',
      'reading_sessions',
      'installed_sources',
      'repos',
    ]) {
      await _db.customStatement(
        'UPDATE $table SET client_id = (abs(random()) % 4503599627370496) + 1 '
        'WHERE client_id IS NULL',
      );
    }
  }

  Future<Map<int, int>> _clientIdsOf(String sql, int profileId) async {
    final rows = await _db
        .customSelect(sql, variables: [Variable.withInt(profileId)])
        .get();
    return {
      for (final r in rows)
        if (r.read<int?>('client_id') != null)
          r.read<int>('id'): r.read<int>('client_id'),
    };
  }

  Expression<bool> _changed(GeneratedColumn<int> column, _Stamp s) =>
      s.forced ? const Constant(true) : column.isBiggerOrEqualValue(s.since);
}

class _Stamp {
  _Stamp(this.since, this.forceUpdatedAt);

  final int since;
  final int? forceUpdatedAt;

  bool get forced => forceUpdatedAt != null;

  bool includes(int updatedAt) => forced || updatedAt >= since;

  int of(int updatedAt) => forceUpdatedAt ?? updatedAt;
}
