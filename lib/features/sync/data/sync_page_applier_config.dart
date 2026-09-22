part of 'sync_page_applier.dart';

extension _ConfigApply on SyncPageApplier {
  Future<bool> _applySettings(WireRow w, int scopeProfileId) async {
    final incoming = w['updatedAt'] as int;
    final local = await _db
        .customSelect(
          'SELECT MAX(updated_at) AS newest FROM setting_values '
          'WHERE profile_id = ? AND synced = 1',
          variables: [Variable.withInt(scopeProfileId)],
        )
        .getSingle();
    if ((local.read<int?>('newest') ?? 0) >= incoming) return true;
    final data = w['data'];
    if (data is! Map) return true;
    final deviceOnly = {
      for (final def in Settings.all)
        if (!def.sync) def.id,
    };
    for (final entry in data.entries) {
      final id = entry.key;
      if (id is! String || deviceOnly.contains(id)) continue;
      await _db.customStatement(
        'INSERT INTO setting_values (profile_id, setting_id, value, synced, updated_at) '
        'VALUES (?, ?, ?, 1, ?) '
        'ON CONFLICT(profile_id, setting_id) DO UPDATE SET '
        'value = excluded.value, synced = 1, updated_at = excluded.updated_at',
        [scopeProfileId, id, jsonEncode(entry.value), incoming],
      );
    }
    return true;
  }

  Future<bool> _settings(WireRow w, int profileId) =>
      _applySettings(w, profileId);

  Future<void> _applyDeletions(Object? raw) async {
    final deleted = (raw as Map?)?.cast<String, dynamic>() ?? const {};
    for (final (entity, table) in SyncPageApplier._deleteOrder) {
      final ids = (deleted[entity] as List? ?? const []).cast<int>();
      if (ids.isEmpty) continue;
      await _db.customStatement(
        'DELETE FROM $table WHERE client_id IN (${List.filled(ids.length, '?').join(', ')})',
        ids,
      );
    }
  }

  Future<bool> _source(WireRow w, int profileId) async {
    final clientId = w['clientId'] as int;
    final incoming = w['updatedAt'] as int;
    final mediaType = _byName(MediaType.values, w['mediaType']);
    if (mediaType == null) return true;

    var existing = await (_db.select(
      _db.installedSources,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    var adopted = false;
    var keepId = clientId;
    if (existing == null) {
      final repoUrl = w['repoUrl'] as String?;
      final repoSourceId = w['repoSourceId'] as String?;
      final query = _db.select(_db.installedSources)
        ..where(
          (t) => repoUrl != null && repoSourceId != null
              ? t.repoUrl.equals(repoUrl) & t.repoSourceId.equals(repoSourceId)
              : t.name.equals(w['name'] as String) &
                    t.baseUrl.equals(w['baseUrl'] as String),
        );
      existing = (await query.get()).firstOrNull;
      if (existing != null && _deliveredThisRun('sources', existing.clientId)) {
        existing = null;
      } else if (existing != null) {
        // Both devices keep the smaller id, so they always agree on the survivor.
        keepId = existing.clientId! < clientId ? existing.clientId! : clientId;
        await _tombstone(
          profileId,
          'sources',
          keepId == clientId ? existing.clientId : clientId,
        );
        if (keepId != clientId) _alias('installed_sources', clientId, keepId);
        // Entries name their source by this id, so they go out again with the new one.
        await _touch('library_entries', 'source_id = ?', ['${existing.id}']);
        adopted = true;
      }
    }
    if (existing != null && !adopted && existing.updatedAt >= incoming) {
      return true;
    }

    final values = InstalledSourcesCompanion(
      clientId: Value(keepId),
      updatedAt: Value(incoming),
      name: Value(w['name'] as String),
      lang: Value(w['lang'] as String),
      mediaType: Value(mediaType),
      jsSource: Value(w['jsSource'] as String),
      iconUrl: Value(w['iconUrl'] as String),
      baseUrl: Value(w['baseUrl'] as String),
      enabled: Value(w['enabled'] as bool),
      engineKind: Value(w['engineKind'] as String),
      addedAt: Value(_date(w['addedAt'] as int)),
      repoUrl: Value(w['repoUrl'] as String?),
      repoSourceId: Value(w['repoSourceId'] as String?),
      version: Value(w['version'] as int),
    );
    if (existing == null) {
      await _db.into(_db.installedSources).insert(values);
    } else if (adopted && existing.updatedAt > incoming) {
      await (_db.update(_db.installedSources)
            ..where((t) => t.id.equals(existing!.id)))
          .write(InstalledSourcesCompanion(clientId: Value(keepId)));
      await _touch('installed_sources', 'id = ?', [existing.id]);
    } else {
      await (_db.update(
        _db.installedSources,
      )..where((t) => t.id.equals(existing!.id))).write(values);
    }
    if (adopted && keepId != clientId && existing != null) {
      await _touch('installed_sources', 'id = ?', [existing.id]);
    }
    final row = await (_db.select(
      _db.installedSources,
    )..where((t) => t.clientId.equals(keepId))).getSingleOrNull();
    if (row != null) {
      final relinked = await relinkEntriesToSource(
        _db,
        sourceRowId: row.id,
        key: installedSourceKey(row),
      );
      if (relinked > 0) {
        await _touch('library_entries', 'source_id = ?', ['${row.id}']);
      }
    }
    return true;
  }

  Future<int?> _installedSourceByKey(String key) async {
    for (final row in await _db.select(_db.installedSources).get()) {
      if (installedSourceKey(row) == key) return row.id;
    }
    return null;
  }

  Future<bool> _repo(WireRow w, int profileId) async {
    final clientId = w['clientId'] as int;
    final incoming = w['updatedAt'] as int;

    var existing = await (_db.select(
      _db.repos,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    var adopted = false;
    var keepId = clientId;
    if (existing == null) {
      existing = await (_db.select(
        _db.repos,
      )..where((t) => t.url.equals(w['url'] as String))).getSingleOrNull();
      if (existing != null && _deliveredThisRun('repos', existing.clientId)) {
        _alias('repos', clientId, existing.clientId!);
        return true;
      } else if (existing != null) {
        // Both devices keep the smaller id, so they always agree on the survivor.
        keepId = existing.clientId! < clientId ? existing.clientId! : clientId;
        await _tombstone(
          profileId,
          'repos',
          keepId == clientId ? existing.clientId : clientId,
        );
        if (keepId != clientId) _alias('repos', clientId, keepId);
        adopted = true;
      }
    }
    if (existing != null && !adopted && existing.updatedAt >= incoming) {
      return true;
    }
    final values = ReposCompanion(
      clientId: Value(keepId),
      updatedAt: Value(incoming),
      url: Value(w['url'] as String),
      name: Value(w['name'] as String),
      addedAt: Value(_date(w['addedAt'] as int)),
    );
    if (existing == null) {
      await _db.into(_db.repos).insert(values);
    } else if (adopted && existing.updatedAt > incoming) {
      await (_db.update(_db.repos)..where((t) => t.id.equals(existing!.id)))
          .write(ReposCompanion(clientId: Value(keepId)));
      await _touch('repos', 'id = ?', [existing.id]);
    } else {
      await (_db.update(
        _db.repos,
      )..where((t) => t.id.equals(existing!.id))).write(values);
    }
    if (adopted && keepId != clientId && existing != null) {
      await _touch('repos', 'id = ?', [existing.id]);
    }
    return true;
  }

  Future<bool> _appSettings(WireRow w) => _applySettings(w, 0);
}
