// Drift methods for reading sessions, restoring backup chapters, and downloaded entries.
part of 'library_repository_impl.dart';

mixin DriftLibraryRestoreMethods {
  AppDatabase get _db;
  AppLogger get _logger;
  int get profileId;
  Future<int?> _ensureActiveBranch(int libraryEntryId);

  Future<Result<List<({String chapterUrl, DateTime readAt})>, AppFailure>>
  getReadingSessions(int libraryEntryId) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final rows =
          await (_db.select(_db.readingSessions).join([
                innerJoin(
                  _db.contentUnits,
                  _db.contentUnits.id.equalsExp(
                    _db.readingSessions.contentUnitId,
                  ),
                ),
              ])..where(
                _db.readingSessions.libraryEntryId.equals(libraryEntryId),
              ))
              .get();
      return [
        for (final row in rows)
          (
            chapterUrl: row.readTable(_db.contentUnits).url,
            readAt: row.readTable(_db.readingSessions).readAt,
          ),
      ];
    });
  }

  Future<Result<void, AppFailure>> restoreReadingSessions({
    required int libraryEntryId,
    required List<({String chapterUrl, DateTime readAt})> sessions,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final branchId = await _ensureActiveBranch(libraryEntryId);
      await _db.transaction(() async {
        for (final session in sessions) {
          final unit =
              await (_db.select(_db.contentUnits)..where(
                    (t) =>
                        t.libraryEntryId.equals(libraryEntryId) &
                        t.url.equals(session.chapterUrl),
                  ))
                  .getSingleOrNull();
          if (unit == null) continue;
          final existing =
              await (_db.select(_db.readingSessions)
                    ..where(
                      (t) =>
                          t.libraryEntryId.equals(libraryEntryId) &
                          t.contentUnitId.equals(unit.id) &
                          t.readAt.equals(session.readAt),
                    )
                    ..limit(1))
                  .getSingleOrNull();
          if (existing != null) continue;
          await _db
              .into(_db.readingSessions)
              .insert(
                ReadingSessionsCompanion.insert(
                  libraryEntryId: libraryEntryId,
                  contentUnitId: unit.id,
                  branchId: Value(branchId),
                  readAt: Value(session.readAt),
                ),
              );
        }
      });
    });
  }

  Future<Result<void, AppFailure>> restoreChapters({
    required int libraryEntryId,
    required List<ChapterRecord> chapters,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final branchId = await _ensureActiveBranch(libraryEntryId);
      if (branchId == null) return;
      await _db.transaction(() async {
        for (final chapter in chapters) {
          final unitId = await _db
              .into(_db.contentUnits)
              .insert(
                ContentUnitsCompanion.insert(
                  libraryEntryId: libraryEntryId,
                  url: chapter.url,
                  number: chapter.number,
                  displayTitle: Value(chapter.title),
                  dateUploaded: Value(chapter.dateUploaded ?? DateTime.now()),
                  bookmarked: Value(chapter.bookmarked),
                ),
                onConflict: DoUpdate(
                  (old) => ContentUnitsCompanion(
                    number: Value(chapter.number),
                    displayTitle: Value(chapter.title),
                    dateUploaded: Value(chapter.dateUploaded ?? DateTime.now()),
                    // A backup without the bookmark must not clear one made since.
                    bookmarked: chapter.bookmarked
                        ? const Value(true)
                        : const Value.absent(),
                  ),
                  target: [
                    _db.contentUnits.libraryEntryId,
                    _db.contentUnits.url,
                  ],
                ),
              );
          final effectiveUnitId = unitId > 0
              ? unitId
              : (await (_db.select(_db.contentUnits)..where(
                          (t) =>
                              t.libraryEntryId.equals(libraryEntryId) &
                              t.url.equals(chapter.url),
                        ))
                        .getSingle())
                    .id;
          if (chapter.consumed || chapter.progressPosition != null) {
            await _db
                .into(_db.chapterProgress)
                .insert(
                  ChapterProgressCompanion.insert(
                    contentUnitId: effectiveUnitId,
                    branchId: branchId,
                    consumed: Value(chapter.consumed),
                    consumedAt: Value(chapter.consumedAt),
                    progressPosition: Value(chapter.progressPosition),
                  ),
                  onConflict: DoUpdate(
                    (old) => ChapterProgressCompanion(
                      consumed: Value(chapter.consumed),
                      consumedAt: Value(chapter.consumedAt),
                      progressPosition: Value(chapter.progressPosition),
                    ),
                    target: [
                      _db.chapterProgress.contentUnitId,
                      _db.chapterProgress.branchId,
                    ],
                  ),
                );
          }
        }
      });
    });
  }

  Stream<List<DownloadedEntry>> watchDownloadedEntries() {
    final query =
        _db.select(_db.contentUnits).join([
          innerJoin(
            _db.libraryEntries,
            _db.libraryEntries.id.equalsExp(_db.contentUnits.libraryEntryId),
          ),
        ])..where(
          _db.libraryEntries.profileId.equals(profileId) &
              _db.contentUnits.localPath.isNotNull(),
        );

    return query.watch().map((rows) {
      final chaptersByEntry = <int, List<DownloadedChapterRef>>{};
      final entryById = <int, LibraryEntry>{};
      for (final row in rows) {
        final chapter = row.readTable(_db.contentUnits);
        final entry = row.readTable(_db.libraryEntries);
        final localPath = chapter.localPath;
        if (localPath == null) continue;
        chaptersByEntry
            .putIfAbsent(entry.id, () => [])
            .add(
              DownloadedChapterRef(
                chapterUrl: chapter.url,
                localPath: localPath,
              ),
            );
        entryById[entry.id] = entry;
      }
      return [
        for (final entryId in chaptersByEntry.keys)
          DownloadedEntry(
            entryId: entryId,
            title: entryById[entryId]!.title,
            coverUrl: entryById[entryId]!.coverUrl,
            customCoverPath: entryById[entryId]!.customCoverPath,
            chapters: chaptersByEntry[entryId]!,
          ),
      ];
    });
  }
}
