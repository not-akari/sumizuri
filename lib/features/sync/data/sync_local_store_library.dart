part of 'sync_local_store.dart';

extension _LibraryCollect on SyncLocalStore {
  Future<List<Map<String, dynamic>>> _categories(
    int profileId,
    _Stamp s,
  ) async {
    final query = _db.select(_db.categories)
      ..where((t) => t.profileId.equals(profileId) & _changed(t.updatedAt, s));
    return [
      for (final c in await query.get())
        {
          'clientId': c.clientId,
          'updatedAt': s.of(c.updatedAt),
          'name': c.name,
          'sortOrder': c.sortOrder,
          'excludeFromUpdate': c.excludeFromUpdate,
          'mediaType': c.mediaType.name,
          'useSmartRule': c.useSmartRule,
          'sortField': c.sortField.name,
          'sortAscending': c.sortAscending,
          'statusFilter': c.statusFilter.name,
        },
    ];
  }

  Future<List<Map<String, dynamic>>> _entries(
    int profileId,
    _Stamp s,
    Map<int, int> categoryIds,
    Map<int, int> branchIds,
    Map<int, int> sourceIds,
    String? coversDir,
  ) async {
    final query = _db.select(_db.libraryEntries)
      ..where((t) => t.profileId.equals(profileId) & _changed(t.updatedAt, s));
    final entries = await query.get();
    if (entries.isEmpty) return [];
    final sourceKeys = await _sourceKeys();

    final links = await _db.select(_db.entryCategories).get();
    final categoriesOf = <int, List<int>>{};
    for (final link in links) {
      final clientId = categoryIds[link.categoryId];
      if (clientId != null) {
        (categoriesOf[link.libraryEntryId] ??= []).add(clientId);
      }
    }
    return [
      for (final e in entries)
        {
          'clientId': e.clientId,
          'updatedAt': s.of(e.updatedAt),
          'sourceId': e.sourceId,
          'sourceClientId': sourceIds[int.tryParse(e.sourceId)],
          'sourceKey': sourceKeys[int.tryParse(e.sourceId)] ?? e.sourceKey,
          'excludedScanlators': decodeScanlatorList(e.excludedScanlators),
          'customCoverFile': _coverFile(e.customCoverPath, coversDir),
          'externalId': e.externalId,
          'mediaType': e.mediaType.name,
          'title': e.title,
          'coverUrl': e.coverUrl,
          'favorite': e.favorite,
          'addedAt': e.addedAt.millisecondsSinceEpoch,
          'lastUpdatedAt': e.lastUpdatedAt.millisecondsSinceEpoch,
          'readerMode': e.readerMode?.name,
          'readerDualPageMode': e.readerDualPageMode?.name,
          'settingsOverrides': e.settingsOverrides,
          'status': e.status,
          'activeBranchClientId': branchIds[e.activeBranchId],
          'categoryClientIds': categoriesOf[e.id] ?? <int>[],
        },
    ];
  }

  Future<List<Map<String, dynamic>>> _branches(
    int profileId,
    _Stamp s,
    Map<int, int> entryIds,
  ) async {
    final rows = await (_db.select(
      _db.entryBranches,
    )..where((t) => _changed(t.updatedAt, s))).get();
    return [
      for (final b in rows)
        if (entryIds[b.libraryEntryId] != null)
          {
            'clientId': b.clientId,
            'updatedAt': s.of(b.updatedAt),
            'entryClientId': entryIds[b.libraryEntryId],
            'name': b.name,
            'createdAt': b.createdAt.millisecondsSinceEpoch,
          },
    ];
  }

  Future<List<Map<String, dynamic>>> _chapters(
    int profileId,
    _Stamp s,
    Map<int, int> entryIds,
  ) async {
    final rows = await (_db.select(
      _db.contentUnits,
    )..where((t) => _changed(t.updatedAt, s))).get();
    return [
      for (final c in rows)
        if (entryIds[c.libraryEntryId] != null)
          {
            'clientId': c.clientId,
            'updatedAt': s.of(c.updatedAt),
            'entryClientId': entryIds[c.libraryEntryId],
            'number': c.number,
            'bookmarked': c.bookmarked,
            'scanlator': c.scanlator,
            'displayTitle': c.displayTitle,
            'url': c.url,
            'dateUploaded': c.dateUploaded.millisecondsSinceEpoch,
          },
    ];
  }

  Future<List<Map<String, dynamic>>> _progress(
    int profileId,
    _Stamp s,
    Map<int, int> chapterIds,
    Map<int, int> branchIds,
  ) async {
    final rows = await (_db.select(
      _db.chapterProgress,
    )..where((t) => _changed(t.updatedAt, s))).get();
    return [
      for (final p in rows)
        if (chapterIds[p.contentUnitId] != null &&
            branchIds[p.branchId] != null)
          {
            'clientId': p.clientId,
            'updatedAt': s.of(p.updatedAt),
            'chapterClientId': chapterIds[p.contentUnitId],
            'branchClientId': branchIds[p.branchId],
            'consumed': p.consumed,
            'consumedAt': p.consumedAt?.millisecondsSinceEpoch,
            'progressPosition': p.progressPosition,
          },
    ];
  }

  Future<List<Map<String, dynamic>>> _sessions(
    int profileId,
    _Stamp s,
    Map<int, int> entryIds,
    Map<int, int> chapterIds,
    Map<int, int> branchIds,
  ) async {
    final rows = await (_db.select(
      _db.readingSessions,
    )..where((t) => _changed(t.updatedAt, s))).get();
    return [
      for (final r in rows)
        if (entryIds[r.libraryEntryId] != null &&
            chapterIds[r.contentUnitId] != null)
          {
            'clientId': r.clientId,
            'updatedAt': s.of(r.updatedAt),
            'entryClientId': entryIds[r.libraryEntryId],
            'chapterClientId': chapterIds[r.contentUnitId],
            'branchClientId': branchIds[r.branchId],
            'readAt': r.readAt.millisecondsSinceEpoch,
          },
    ];
  }
}
