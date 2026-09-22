part of 'sync_local_store.dart';

extension _ConfigCollect on SyncLocalStore {
  Future<Map<int, String>> _sourceKeys() async {
    final rows = await _db.select(_db.installedSources).get();
    return {for (final s in rows) s.id: installedSourceKey(s)};
  }

  Future<Map<int, int>> _sourceClientIds() async {
    final rows = await _db.select(_db.installedSources).get();
    return {
      for (final s in rows)
        if (s.clientId != null) s.id: s.clientId!,
    };
  }

  String? _coverFile(String? path, String? coversDir) {
    if (path == null || coversDir == null) return null;
    return p.equals(p.dirname(path), coversDir) ? p.basename(path) : null;
  }

  Future<List<Map<String, dynamic>>> _sources(_Stamp s) async {
    final rows = await (_db.select(
      _db.installedSources,
    )..where((t) => _changed(t.updatedAt, s))).get();
    return [
      for (final r in rows)
        {
          'clientId': r.clientId,
          'updatedAt': s.of(r.updatedAt),
          'name': r.name,
          'lang': r.lang,
          'mediaType': r.mediaType.name,
          'jsSource': r.jsSource,
          'iconUrl': r.iconUrl,
          'baseUrl': r.baseUrl,
          'enabled': r.enabled,
          'engineKind': r.engineKind,
          'addedAt': r.addedAt.millisecondsSinceEpoch,
          'repoUrl': r.repoUrl,
          'repoSourceId': r.repoSourceId,
          'version': r.version,
        },
    ];
  }

  Future<List<Map<String, dynamic>>> _repos(_Stamp s) async {
    final rows = await (_db.select(
      _db.repos,
    )..where((t) => _changed(t.updatedAt, s))).get();
    return [
      for (final r in rows)
        {
          'clientId': r.clientId,
          'updatedAt': s.of(r.updatedAt),
          'url': r.url,
          'name': r.name,
          'addedAt': r.addedAt.millisecondsSinceEpoch,
        },
    ];
  }

  Future<List<Map<String, dynamic>>> _settingsRecord(
    int scopeProfileId,
    _Stamp s,
  ) async {
    final rows = await _db
        .customSelect(
          'SELECT setting_id, value, updated_at FROM setting_values '
          'WHERE profile_id = ? AND synced = 1',
          variables: [Variable.withInt(scopeProfileId)],
        )
        .get();
    if (rows.isEmpty) return [];
    final updatedAt = rows
        .map((r) => r.read<int>('updated_at'))
        .reduce((a, b) => a > b ? a : b);
    if (!s.includes(updatedAt)) return [];
    return [
      {
        'clientId': settingsClientId,
        'updatedAt': s.of(updatedAt),
        'data': {
          for (final r in rows)
            r.read<String>('setting_id'): jsonDecode(r.read<String>('value')),
        },
      },
    ];
  }

  Future<List<Map<String, dynamic>>> _settings(int profileId, _Stamp s) =>
      _settingsRecord(profileId, s);

  Future<List<Map<String, dynamic>>> _appSettings(_Stamp s) =>
      _settingsRecord(0, s);
}
