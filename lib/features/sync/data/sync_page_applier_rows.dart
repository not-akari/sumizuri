part of 'sync_page_applier.dart';

extension _LibraryRowsApply on SyncPageApplier {
  Future<bool> _category(WireRow w, int profileId) async {
    final clientId = w['clientId'] as int;
    final incoming = w['updatedAt'] as int;
    final mediaType = _byName(MediaType.values, w['mediaType']);
    if (mediaType == null) return true;

    var existing = await (_db.select(
      _db.categories,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    var adopted = false;
    var keepId = clientId;
    if (existing == null) {
      existing =
          await (_db.select(_db.categories)..where(
                (t) =>
                    t.profileId.equals(profileId) &
                    t.name.equals(w['name'] as String) &
                    t.mediaType.equals(mediaType.index),
              ))
              .getSingleOrNull();
      if (existing != null &&
          _deliveredThisRun('categories', existing.clientId)) {
        existing = null;
      } else if (existing != null) {
        // Both devices keep the smaller id, so they always agree on the survivor.
        keepId = existing.clientId! < clientId ? existing.clientId! : clientId;
        await _tombstone(
          profileId,
          'categories',
          keepId == clientId ? existing.clientId : clientId,
        );
        if (keepId != clientId) _alias('categories', clientId, keepId);
        await _touch(
          'library_entries',
          'id IN (SELECT library_entry_id FROM entry_categories WHERE category_id = ?)',
          [existing.id],
        );
        adopted = true;
      }
    }
    if (existing != null && !adopted && existing.updatedAt >= incoming) {
      return true;
    }

    final values = CategoriesCompanion(
      clientId: Value(keepId),
      updatedAt: Value(incoming),
      profileId: Value(profileId),
      name: Value(w['name'] as String),
      sortOrder: Value(w['sortOrder'] as int),
      excludeFromUpdate: Value(w['excludeFromUpdate'] as bool),
      mediaType: Value(mediaType),
      useSmartRule: Value(w['useSmartRule'] as bool),
      sortField: Value(
        _byName(CategorySortField.values, w['sortField']) ??
            CategorySortField.title,
      ),
      sortAscending: Value(w['sortAscending'] as bool),
      statusFilter: Value(
        _byName(CategoryStatusFilter.values, w['statusFilter']) ??
            CategoryStatusFilter.any,
      ),
    );
    if (existing == null) {
      await _db.into(_db.categories).insert(values);
    } else if (adopted && existing.updatedAt > incoming) {
      await (_db.update(_db.categories)
            ..where((t) => t.id.equals(existing!.id)))
          .write(CategoriesCompanion(clientId: Value(keepId)));
      await _touch('categories', 'id = ?', [existing.id]);
    } else {
      await (_db.update(
        _db.categories,
      )..where((t) => t.id.equals(existing!.id))).write(values);
    }
    if (adopted && keepId != clientId && existing != null) {
      await _touch('categories', 'id = ?', [existing.id]);
    }
    return true;
  }

  Future<bool> _entry(WireRow w, SyncPending pending, int profileId) async {
    final clientId = w['clientId'] as int;
    final incoming = w['updatedAt'] as int;
    final mediaType = _byName(MediaType.values, w['mediaType']);
    if (mediaType == null) return true;

    var sourceId = w['sourceId'] as String;
    final sourceClientId = w['sourceClientId'] as int?;
    final sourceKey = w['sourceKey'] as String?;
    var lostSource = false;
    if (sourceClientId != null) {
      final local = await _idOf('installed_sources', sourceClientId);
      if (local != null) {
        sourceId = '$local';
      } else if (!pending.finalizing) {
        return false;
      } else {
        lostSource = true;
      }
    } else if (int.tryParse(sourceId) != null) {
      lostSource = true;
    }
    if (lostSource && sourceKey != null) {
      final match = await _installedSourceByKey(sourceKey);
      sourceId = match == null ? 'k:$sourceKey' : '$match';
      if (match != null) lostSource = false;
    }
    final coversDir = await _coversPath?.call();
    final coverFile = w['customCoverFile'] as String?;

    var existing = await (_db.select(
      _db.libraryEntries,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    var adopted = false;
    var keepId = clientId;
    if (existing == null) {
      existing =
          await (_db.select(_db.libraryEntries)..where(
                (t) =>
                    t.profileId.equals(profileId) &
                    t.sourceId.equals(sourceId) &
                    t.externalId.equals(w['externalId'] as String),
              ))
              .getSingleOrNull();
      if (existing != null && _deliveredThisRun('entries', existing.clientId)) {
        _alias('library_entries', clientId, existing.clientId!);
        return true;
      } else if (existing != null) {
        keepId = existing.clientId! < clientId ? existing.clientId! : clientId;
        await _tombstone(
          profileId,
          'entries',
          keepId == clientId ? existing.clientId : clientId,
        );
        if (keepId != clientId) _alias('library_entries', clientId, keepId);
        await _touch('entry_branches', 'library_entry_id = ?', [existing.id]);
        await _touch('content_units', 'library_entry_id = ?', [existing.id]);
        await _touch('reading_sessions', 'library_entry_id = ?', [existing.id]);
        await _touch(
          'chapter_progress',
          'content_unit_id IN (SELECT id FROM content_units WHERE library_entry_id = ?)',
          [existing.id],
        );
        adopted = true;
      }
    }
    if (existing != null && !adopted && existing.updatedAt >= incoming) {
      return true;
    }

    if (existing != null && adopted && existing.updatedAt > incoming) {
      await (_db.update(_db.libraryEntries)
            ..where((t) => t.id.equals(existing!.id)))
          .write(LibraryEntriesCompanion(clientId: Value(keepId)));
      await _touch('library_entries', 'id = ?', [existing.id]);
    } else {
      final values = LibraryEntriesCompanion(
        clientId: Value(keepId),
        updatedAt: Value(incoming),
        profileId: Value(profileId),
        sourceId: Value(sourceId),
        sourceKey: Value(lostSource ? sourceKey : null),
        excludedScanlators: w['excludedScanlators'] is List
            ? Value(
                encodeScanlatorList([
                  for (final v in w['excludedScanlators'] as List)
                    if (v is String) v,
                ]),
              )
            : const Value.absent(),
        externalId: Value(w['externalId'] as String),
        customCoverPath: coversDir == null
            ? const Value.absent()
            : Value(coverFile == null ? null : p.join(coversDir, coverFile)),
        mediaType: Value(mediaType),
        title: Value(w['title'] as String),
        coverUrl: Value(w['coverUrl'] as String?),
        favorite: Value(w['favorite'] as bool),
        addedAt: Value(_date(w['addedAt'] as int)),
        lastUpdatedAt: Value(_date(w['lastUpdatedAt'] as int)),
        readerMode: Value(_byName(ReaderMode.values, w['readerMode'])),
        readerDualPageMode: Value(
          _byName(ReaderDualPageMode.values, w['readerDualPageMode']),
        ),
        settingsOverrides: Value(w['settingsOverrides'] as String?),
        status: Value(w['status'] as String?),
      );
      if (existing == null) {
        await _db.into(_db.libraryEntries).insert(values);
      } else {
        await (_db.update(
          _db.libraryEntries,
        )..where((t) => t.id.equals(existing!.id))).write(values);
      }
    }
    pending.entryLinks[keepId] = SyncEntryLinks(
      (w['categoryClientIds'] as List).cast<int>(),
      w['activeBranchClientId'] as int?,
    );
    if (adopted && keepId != clientId && existing != null) {
      await _touch('library_entries', 'id = ?', [existing.id]);
    }
    return true;
  }

  Future<void> _resolveEntryLinks(SyncPending pending) async {
    for (final entry in [...pending.entryLinks.entries]) {
      final entryId = await _idOf('library_entries', entry.key);
      if (entryId == null) {
        pending.entryLinks.remove(entry.key);
        continue;
      }
      final links = entry.value;
      final categoryIds = <int>[];
      for (final id in links.categoryClientIds) {
        final local = await _idOf('categories', id);
        if (local != null) categoryIds.add(local);
      }
      await (_db.delete(
        _db.entryCategories,
      )..where((t) => t.libraryEntryId.equals(entryId))).go();
      await _db.batch((batch) {
        batch.insertAll(_db.entryCategories, [
          for (final id in categoryIds)
            EntryCategoriesCompanion.insert(
              libraryEntryId: entryId,
              categoryId: id,
            ),
        ]);
      });

      final branchId = await _idOf(
        'entry_branches',
        links.activeBranchClientId,
      );
      if (links.activeBranchClientId == null || branchId != null) {
        await (_db.update(_db.libraryEntries)
              ..where((t) => t.id.equals(entryId)))
            .write(LibraryEntriesCompanion(activeBranchId: Value(branchId)));
      }
      final done =
          categoryIds.length == links.categoryClientIds.length &&
          (links.activeBranchClientId == null || branchId != null);
      if (done) pending.entryLinks.remove(entry.key);
    }
  }

  Future<bool> _branch(WireRow w, int profileId) async {
    final entryId = await _idOf('library_entries', w['entryClientId']);
    if (entryId == null) return false;
    final clientId = w['clientId'] as int;
    final incoming = w['updatedAt'] as int;
    final name = w['name'] as String;

    var existing = await (_db.select(
      _db.entryBranches,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    var adopted = false;
    var keepId = clientId;
    if (existing == null) {
      existing =
          await (_db.select(_db.entryBranches)..where(
                (t) => t.libraryEntryId.equals(entryId) & t.name.equals(name),
              ))
              .getSingleOrNull();
      if (existing != null &&
          _deliveredThisRun('branches', existing.clientId)) {
        existing = null;
      } else if (existing != null) {
        // Both devices keep the smaller id, so they always agree on the survivor.
        keepId = existing.clientId! < clientId ? existing.clientId! : clientId;
        await _tombstone(
          profileId,
          'branches',
          keepId == clientId ? existing.clientId : clientId,
        );
        if (keepId != clientId) _alias('entry_branches', clientId, keepId);
        await _touch('chapter_progress', 'branch_id = ?', [existing.id]);
        await _touch('reading_sessions', 'branch_id = ?', [existing.id]);
        await _touch('library_entries', 'id = ?', [entryId]);
        adopted = true;
      }
    }
    if (existing != null && !adopted && existing.updatedAt >= incoming) {
      return true;
    }
    final values = EntryBranchesCompanion(
      clientId: Value(keepId),
      updatedAt: Value(incoming),
      libraryEntryId: Value(entryId),
      name: Value(name),
      createdAt: Value(_date(w['createdAt'] as int)),
    );
    if (existing == null) {
      await _db.into(_db.entryBranches).insert(values);
    } else {
      await (_db.update(
        _db.entryBranches,
      )..where((t) => t.id.equals(existing!.id))).write(values);
    }
    if (adopted && keepId != clientId && existing != null) {
      await _touch('entry_branches', 'id = ?', [existing.id]);
    }
    return true;
  }
}
