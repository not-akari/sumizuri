import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/extensions/data/source_relink.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/features/library/models/scanlator_filter.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/features/sync/data/sync_file_store.dart';
import 'package:sumizuri/features/sync/data/sync_local_store.dart';

part 'sync_page_applier_rows.dart';
part 'sync_page_applier_progress.dart';
part 'sync_page_applier_config.dart';

typedef WireRow = Map<String, dynamic>;

/// Things a page could not finish because they point at a row on a later page.
class SyncPending {
  bool finalizing = false;

  final List<({String entity, WireRow row})> orphans = [];

  final Map<int, SyncEntryLinks> entryLinks = {};

  final Map<String, Set<int>> delivered = {};

  final Map<String, Set<int>> uploaded = {};

  final Map<String, Map<int, int>> aliases = {};
}

class SyncEntryLinks {
  SyncEntryLinks(this.categoryClientIds, this.activeBranchClientId);

  final List<int> categoryClientIds;
  final int? activeBranchClientId;
}

class SyncPageApplier {
  SyncPageApplier(this._db, {this._files, this._coversPath});

  final AppDatabase _db;
  final SyncFileStore? _files;
  final Future<String> Function()? _coversPath;

  // The sync run being applied. Syncs never overlap, so one field is enough.
  SyncPending? _run;

  // Children before parents, so nothing is deleted from under a row about to go too.
  static const _deleteOrder = [
    ('sessions', 'reading_sessions'),
    ('progress', 'chapter_progress'),
    ('chapters', 'content_units'),
    ('branches', 'entry_branches'),
    ('entries', 'library_entries'),
    ('categories', 'categories'),
    ('sources', 'installed_sources'),
    ('repos', 'repos'),
  ];

  Future<void> apply(
    WireRow response,
    SyncPending pending,
    int profileId,
  ) async {
    _run = pending;
    await _applyDatabaseRows(response, pending, profileId);
    final deleted = (response['deleted'] as Map?)?.cast<String, dynamic>();
    await _files?.apply(
      profileId,
      _rows(response['files']),
      (deleted?['files'] as List? ?? const []).cast<int>(),
    );
  }

  /// Last step of a sync: places whatever is still waiting on a parent that never arrived.
  Future<void> finish(SyncPending pending, int profileId) =>
      _db.transaction(() async {
        _run = pending;
        await _setApplying(1);
        pending.finalizing = true;
        await _retryOrphans(pending, profileId);
        await _resolveEntryLinks(pending);
        await _setApplying(0);
      });

  Future<void> _applyDatabaseRows(
    WireRow response,
    SyncPending pending,
    int profileId,
  ) => _db.transaction(() async {
    await _setApplying(1);
    for (final entity in syncEntities) {
      for (final row in _rows(response[entity])) {
        await _applyRow(entity, row, pending, profileId);
      }
    }
    await _retryOrphans(pending, profileId);
    await _resolveEntryLinks(pending);
    await _applyDeletions(response['deleted']);
    await _setApplying(0);
  });

  Future<void> _setApplying(int value) => _db.customStatement(
    'UPDATE sync_state SET applying = $value WHERE id = 0',
  );

  List<WireRow> _rows(Object? raw) =>
      (raw as List? ?? const []).cast<WireRow>();

  static const _tableOf = {
    'sources': 'installed_sources',
    'repos': 'repos',
    'categories': 'categories',
    'entries': 'library_entries',
    'branches': 'entry_branches',
    'chapters': 'content_units',
    'progress': 'chapter_progress',
    'sessions': 'reading_sessions',
  };

  Future<void> _applyRow(
    String entity,
    WireRow row,
    SyncPending pending,
    int profileId,
  ) async {
    final echoed = row['clientId'];
    final table = _tableOf[entity];
    if (table != null &&
        echoed is int &&
        (pending.uploaded[entity]?.contains(echoed) ?? false) &&
        await _idOf(table, echoed) == null) {
      return;
    }
    final delivered = row['clientId'];
    if (delivered is int &&
        !(pending.uploaded[entity]?.contains(delivered) ?? false)) {
      pending.delivered.putIfAbsent(entity, () => {}).add(delivered);
    }
    final applied = switch (entity) {
      'sources' => await _source(row, profileId),
      'repos' => await _repo(row, profileId),
      'appsettings' => await _appSettings(row),
      'categories' => await _category(row, profileId),
      'entries' => await _entry(row, pending, profileId),
      'branches' => await _branch(row, profileId),
      'chapters' => await _chapter(row, profileId),
      'progress' => await _progress(row, profileId),
      'sessions' => await _session(row),
      'settings' => await _settings(row, profileId),
      _ => true,
    };
    if (!applied) pending.orphans.add((entity: entity, row: row));
  }

  Future<void> _retryOrphans(SyncPending pending, int profileId) async {
    var placed = true;
    while (placed && pending.orphans.isNotEmpty) {
      placed = false;
      final batch = [...pending.orphans]
        ..sort(
          (a, b) => syncEntities
              .indexOf(a.entity)
              .compareTo(syncEntities.indexOf(b.entity)),
        );
      pending.orphans.clear();
      for (final orphan in batch) {
        final before = pending.orphans.length;
        await _applyRow(orphan.entity, orphan.row, pending, profileId);
        if (pending.orphans.length == before) placed = true;
      }
    }
  }

  Future<int?> _idOf(String table, Object? clientId) async {
    if (clientId == null) return null;
    final serverId = clientId as int;
    final wanted = _run?.aliases[table]?[serverId] ?? serverId;
    final row = await _db
        .customSelect(
          'SELECT id FROM $table WHERE client_id = ?',
          variables: [Variable.withInt(wanted)],
        )
        .getSingleOrNull();
    return row?.read<int>('id');
  }

  Future<void> _tombstone(int profileId, String entity, int? clientId) async {
    if (clientId == null) return;
    await _db.customStatement(
      'INSERT OR IGNORE INTO sync_deletions (profile_id, entity, client_id) VALUES (?, ?, ?)',
      [profileId, entity, clientId],
    );
  }

  bool _deliveredThisRun(String entity, int? existingClientId) =>
      existingClientId != null &&
      (_run?.delivered[entity]?.contains(existingClientId) ?? false);

  void _alias(String table, int serverClientId, int localClientId) {
    (_run?.aliases.putIfAbsent(table, () => {}) ?? {})[serverClientId] =
        localClientId;
  }

  // Marks rows as changed now so they are sent again.
  Future<void> _touch(
    String table,
    String where,
    List<Object> args,
  ) => _db.customStatement(
    'UPDATE $table SET updated_at = '
    "CAST((julianday('now') - 2440587.5) * 86400000 AS INTEGER) WHERE $where",
    args,
  );

  DateTime _date(int millis) => DateTime.fromMillisecondsSinceEpoch(millis);

  T? _byName<T extends Enum>(List<T> values, Object? name) {
    if (name is! String) return null;
    for (final value in values) {
      if (value.name == name) return value;
    }
    return null;
  }
}
