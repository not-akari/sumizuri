part of 'sync_page_applier.dart';

extension _ProgressRowsApply on SyncPageApplier {
  Future<bool> _chapter(WireRow w, int profileId) async {
    final entryId = await _idOf('library_entries', w['entryClientId']);
    if (entryId == null) return false;
    final clientId = w['clientId'] as int;
    final incoming = w['updatedAt'] as int;
    final url = w['url'] as String;

    var existing = await (_db.select(
      _db.contentUnits,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    var adopted = false;
    var keepId = clientId;
    if (existing == null) {
      existing =
          await (_db.select(_db.contentUnits)..where(
                (t) => t.libraryEntryId.equals(entryId) & t.url.equals(url),
              ))
              .getSingleOrNull();
      if (existing != null &&
          _deliveredThisRun('chapters', existing.clientId)) {
        _alias('content_units', clientId, existing.clientId!);
        return true;
      } else if (existing != null) {
        // Both devices keep the smaller id, so they always agree on the survivor.
        keepId = existing.clientId! < clientId ? existing.clientId! : clientId;
        await _tombstone(
          profileId,
          'chapters',
          keepId == clientId ? existing.clientId : clientId,
        );
        if (keepId != clientId) _alias('content_units', clientId, keepId);
        await _touch('chapter_progress', 'content_unit_id = ?', [existing.id]);
        await _touch('reading_sessions', 'content_unit_id = ?', [existing.id]);
        adopted = true;
      }
    }
    if (existing != null && !adopted && existing.updatedAt >= incoming) {
      return true;
    }
    final values = ContentUnitsCompanion(
      clientId: Value(keepId),
      updatedAt: Value(incoming),
      libraryEntryId: Value(entryId),
      number: Value((w['number'] as num).toDouble()),
      displayTitle: Value(w['displayTitle'] as String?),
      url: Value(url),
      dateUploaded: Value(_date(w['dateUploaded'] as int)),
      scanlator: w.containsKey('scanlator')
          ? Value(w['scanlator'] as String?)
          : const Value.absent(),
      // An older device does not send this, and must not clear a bookmark made elsewhere.
      bookmarked: w['bookmarked'] is bool
          ? Value(w['bookmarked'] as bool)
          : const Value.absent(),
    );
    if (existing == null) {
      await _db.into(_db.contentUnits).insert(values);
    } else {
      await (_db.update(
        _db.contentUnits,
      )..where((t) => t.id.equals(existing!.id))).write(values);
    }
    if (adopted && keepId != clientId && existing != null) {
      await _touch('content_units', 'id = ?', [existing.id]);
    }
    return true;
  }

  Future<bool> _progress(WireRow w, int profileId) async {
    final chapterId = await _idOf('content_units', w['chapterClientId']);
    final branchId = await _idOf('entry_branches', w['branchClientId']);
    if (chapterId == null || branchId == null) return false;
    final clientId = w['clientId'] as int;
    final incoming = w['updatedAt'] as int;

    var existing = await (_db.select(
      _db.chapterProgress,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    var adopted = false;
    var keepId = clientId;
    if (existing == null) {
      existing =
          await (_db.select(_db.chapterProgress)..where(
                (t) =>
                    t.contentUnitId.equals(chapterId) &
                    t.branchId.equals(branchId),
              ))
              .getSingleOrNull();
      if (existing != null &&
          _deliveredThisRun('progress', existing.clientId)) {
        _alias('chapter_progress', clientId, existing.clientId!);
        return true;
      } else if (existing != null) {
        // Both devices keep the smaller id, so they always agree on the survivor.
        keepId = existing.clientId! < clientId ? existing.clientId! : clientId;
        await _tombstone(
          profileId,
          'progress',
          keepId == clientId ? existing.clientId : clientId,
        );
        if (keepId != clientId) _alias('chapter_progress', clientId, keepId);
        adopted = true;
      }
    }
    if (existing != null && !adopted && existing.updatedAt >= incoming) {
      return true;
    }
    final consumedAt = w['consumedAt'] as int?;
    final values = ChapterProgressCompanion(
      clientId: Value(keepId),
      updatedAt: Value(incoming),
      contentUnitId: Value(chapterId),
      branchId: Value(branchId),
      consumed: Value(w['consumed'] as bool),
      consumedAt: Value(consumedAt == null ? null : _date(consumedAt)),
      progressPosition: Value((w['progressPosition'] as num?)?.toDouble()),
    );
    if (existing == null) {
      await _db.into(_db.chapterProgress).insert(values);
    } else {
      await (_db.update(
        _db.chapterProgress,
      )..where((t) => t.id.equals(existing!.id))).write(values);
    }
    if (adopted && keepId != clientId && existing != null) {
      await _touch('chapter_progress', 'id = ?', [existing.id]);
    }
    return true;
  }

  Future<bool> _session(WireRow w) async {
    final entryId = await _idOf('library_entries', w['entryClientId']);
    final chapterId = await _idOf('content_units', w['chapterClientId']);
    final branchClientId = w['branchClientId'];
    final branchId = await _idOf('entry_branches', branchClientId);
    if (entryId == null ||
        chapterId == null ||
        (branchClientId != null && branchId == null)) {
      return false;
    }
    final clientId = w['clientId'] as int;
    final incoming = w['updatedAt'] as int;
    final existing = await (_db.select(
      _db.readingSessions,
    )..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    if (existing != null && existing.updatedAt >= incoming) return true;

    final values = ReadingSessionsCompanion(
      clientId: Value(clientId),
      updatedAt: Value(incoming),
      libraryEntryId: Value(entryId),
      contentUnitId: Value(chapterId),
      branchId: Value(branchId),
      readAt: Value(_date(w['readAt'] as int)),
    );
    if (existing == null) {
      await _db.into(_db.readingSessions).insert(values);
    } else {
      await (_db.update(
        _db.readingSessions,
      )..where((t) => t.id.equals(existing.id))).write(values);
    }
    return true;
  }
}
