// Drift methods for syncing chapters and reading and writing reading progress.
part of 'library_repository_impl.dart';

mixin DriftLibraryChapterMethods {
  AppDatabase get _db;
  AppLogger get _logger;
  int get profileId;

  Future<int?> _ensureActiveBranch(int libraryEntryId) async {
    final entry = await (_db.select(
      _db.libraryEntries,
    )..where((t) => t.id.equals(libraryEntryId))).getSingleOrNull();
    if (entry == null) {
      return null;
    }
    if (entry.activeBranchId != null) {
      return entry.activeBranchId!;
    }
    final existingBranch =
        await (_db.select(_db.entryBranches)
              ..where((t) => t.libraryEntryId.equals(libraryEntryId))
              ..limit(1))
            .getSingleOrNull();
    if (existingBranch != null) {
      await (_db.update(
        _db.libraryEntries,
      )..where((t) => t.id.equals(libraryEntryId))).write(
        LibraryEntriesCompanion(activeBranchId: Value(existingBranch.id)),
      );
      return existingBranch.id;
    }
    final branchId = await _db
        .into(_db.entryBranches)
        .insert(
          EntryBranchesCompanion.insert(
            libraryEntryId: libraryEntryId,
            name: 'Main',
          ),
        );
    await (_db.update(_db.libraryEntries)
          ..where((t) => t.id.equals(libraryEntryId)))
        .write(LibraryEntriesCompanion(activeBranchId: Value(branchId)));
    return branchId;
  }

  Future<Result<void, AppFailure>> syncChapters({
    required int libraryEntryId,
    required List<ChapterSyncItem> chapters,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await _reconcileChapters(libraryEntryId, chapters);
      await _db.batch((batch) {
        for (final chapter in chapters) {
          final number = chapter.number ?? 0;
          final dateUploaded = chapter.dateUploaded ?? DateTime.now();
          batch.insert(
            _db.contentUnits,
            ContentUnitsCompanion.insert(
              libraryEntryId: libraryEntryId,
              url: chapter.url,
              number: number,
              displayTitle: Value(chapter.title),
              dateUploaded: Value(dateUploaded),
              scanlator: Value(chapter.scanlator),
            ),
            onConflict: DoUpdate(
              (old) => ContentUnitsCompanion(
                number: Value(number),
                displayTitle: Value(chapter.title),
                dateUploaded: Value(dateUploaded),
                scanlator: Value(chapter.scanlator),
              ),
              target: [_db.contentUnits.libraryEntryId, _db.contentUnits.url],
            ),
          );
        }
      });
    });
  }

  Future<void> _reconcileChapters(
    int libraryEntryId,
    List<ChapterSyncItem> listed,
  ) async {
    final saved = await (_db.select(
      _db.contentUnits,
    )..where((t) => t.libraryEntryId.equals(libraryEntryId))).get();
    final plan = planReconcile(
      saved: [
        for (final unit in saved)
          KnownChapter(
            id: unit.id,
            url: unit.url,
            number: unit.number,
            title: unit.displayTitle,
          ),
      ],
      listed: [
        for (final chapter in listed)
          ListedChapter(
            url: chapter.url,
            number: chapter.number ?? 0,
            title: chapter.title,
          ),
      ],
    );
    if (plan.isEmpty) return;

    final byId = {for (final unit in saved) unit.id: unit};
    await _db.transaction(() async {
      for (final rename in plan.renames.entries) {
        await (_db.update(_db.contentUnits)
              ..where((t) => t.id.equals(rename.key)))
            .write(ContentUnitsCompanion(url: Value(rename.value)));
      }
      for (final merge in plan.merges.entries) {
        final old = byId[merge.key]!;
        final keep = byId[merge.value]!;
        // What was watched moves to the copy that stays, unless it has its own branch record.
        final held = {
          for (final progress in await (_db.select(
            _db.chapterProgress,
          )..where((t) => t.contentUnitId.equals(keep.id))).get())
            progress.branchId,
        };
        for (final progress in await (_db.select(
          _db.chapterProgress,
        )..where((t) => t.contentUnitId.equals(old.id))).get()) {
          if (held.contains(progress.branchId)) continue;
          await (_db.update(_db.chapterProgress)
                ..where((t) => t.id.equals(progress.id)))
              .write(ChapterProgressCompanion(contentUnitId: Value(keep.id)));
        }
        await (_db.update(_db.readingSessions)
              ..where((t) => t.contentUnitId.equals(old.id)))
            .write(ReadingSessionsCompanion(contentUnitId: Value(keep.id)));
        await (_db.update(
          _db.contentUnits,
        )..where((t) => t.id.equals(keep.id))).write(
          ContentUnitsCompanion(
            bookmarked: Value(old.bookmarked || keep.bookmarked),
            localPath: Value(keep.localPath ?? old.localPath),
            downloaded: Value(keep.downloaded || old.downloaded),
          ),
        );
        await (_db.delete(
          _db.contentUnits,
        )..where((t) => t.id.equals(old.id))).go();
      }
    });
    _logger.info(
      'Recognised ${plan.renames.length} chapter(s) under a new address and folded ${plan.merges.length} old copy(ies) into the current ones',
      tag: DriftLibraryRepository._tag,
    );
  }

  Future<Result<void, AppFailure>> markChapterConsumed({
    required int libraryEntryId,
    required String chapterUrl,
  }) => markChaptersConsumed(
    libraryEntryId: libraryEntryId,
    chapterUrls: [chapterUrl],
    consumed: true,
    recordSession: true,
  );

  Future<Result<void, AppFailure>> recordChapterSession({
    required int libraryEntryId,
    required String chapterUrl,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final branchId = await _ensureActiveBranch(libraryEntryId);
      if (branchId == null) return;
      final unit =
          await (_db.select(_db.contentUnits)..where(
                (t) =>
                    t.libraryEntryId.equals(libraryEntryId) &
                    t.url.equals(chapterUrl),
              ))
              .getSingleOrNull();
      if (unit == null) return;
      await _db
          .into(_db.readingSessions)
          .insert(
            ReadingSessionsCompanion.insert(
              libraryEntryId: libraryEntryId,
              contentUnitId: unit.id,
              branchId: Value(branchId),
              readAt: Value(DateTime.now()),
            ),
          );
    });
  }

  Future<Result<void, AppFailure>> markChaptersConsumed({
    required int libraryEntryId,
    required List<String> chapterUrls,
    required bool consumed,
    bool recordSession = false,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      if (chapterUrls.isEmpty) return;
      final branchId = await _ensureActiveBranch(libraryEntryId);
      if (branchId == null) return;
      final units =
          await (_db.select(_db.contentUnits)..where(
                (t) =>
                    t.libraryEntryId.equals(libraryEntryId) &
                    t.url.isIn(chapterUrls),
              ))
              .get();
      if (units.isEmpty) return;
      final now = DateTime.now();
      await _db.transaction(() async {
        for (final unit in units) {
          await _db
              .into(_db.chapterProgress)
              .insert(
                ChapterProgressCompanion.insert(
                  contentUnitId: unit.id,
                  branchId: branchId,
                  consumed: Value(consumed),
                  consumedAt: Value(consumed ? now : null),
                ),
                onConflict: DoUpdate(
                  (old) => ChapterProgressCompanion(
                    consumed: Value(consumed),
                    consumedAt: Value(consumed ? now : null),
                  ),
                  target: [
                    _db.chapterProgress.contentUnitId,
                    _db.chapterProgress.branchId,
                  ],
                ),
              );
          if (consumed && recordSession) {
            await _db
                .into(_db.readingSessions)
                .insert(
                  ReadingSessionsCompanion.insert(
                    libraryEntryId: libraryEntryId,
                    contentUnitId: unit.id,
                    branchId: Value(branchId),
                    readAt: Value(now),
                  ),
                );
          }
        }
      });
    });
  }

  Future<Result<void, AppFailure>> updateChapterProgress({
    required int libraryEntryId,
    required String chapterUrl,
    required double progressPosition,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final branchId = await _ensureActiveBranch(libraryEntryId);
      if (branchId == null) return;
      final unit =
          await (_db.select(_db.contentUnits)..where(
                (t) =>
                    t.libraryEntryId.equals(libraryEntryId) &
                    t.url.equals(chapterUrl),
              ))
              .getSingleOrNull();
      if (unit == null) return;
      await _db
          .into(_db.chapterProgress)
          .insert(
            ChapterProgressCompanion.insert(
              contentUnitId: unit.id,
              branchId: branchId,
              progressPosition: Value(progressPosition),
            ),
            onConflict: DoUpdate(
              (old) => ChapterProgressCompanion(
                progressPosition: Value(progressPosition),
              ),
              target: [
                _db.chapterProgress.contentUnitId,
                _db.chapterProgress.branchId,
              ],
            ),
          );
    });
  }

  Future<Result<double?, AppFailure>> getChapterProgress({
    required int libraryEntryId,
    required String chapterUrl,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final branchId = await _ensureActiveBranch(libraryEntryId);
      if (branchId == null) return null;
      final unit =
          await (_db.select(_db.contentUnits)..where(
                (t) =>
                    t.libraryEntryId.equals(libraryEntryId) &
                    t.url.equals(chapterUrl),
              ))
              .getSingleOrNull();
      if (unit == null) return null;
      final progress =
          await (_db.select(_db.chapterProgress)..where(
                (t) =>
                    t.contentUnitId.equals(unit.id) &
                    t.branchId.equals(branchId),
              ))
              .getSingleOrNull();
      return progress?.progressPosition;
    });
  }

  Stream<String?> watchChapterLocalPath({
    required int libraryEntryId,
    required String chapterUrl,
  }) {
    return (_db.select(_db.contentUnits)..where(
          (t) =>
              t.libraryEntryId.equals(libraryEntryId) &
              t.url.equals(chapterUrl),
        ))
        .watchSingleOrNull()
        .map((row) => row?.localPath);
  }

  Future<Result<void, AppFailure>> setChapterLocalPath({
    required int libraryEntryId,
    required String chapterUrl,
    required String? path,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await (_db.update(_db.contentUnits)..where(
            (t) =>
                t.libraryEntryId.equals(libraryEntryId) &
                t.url.equals(chapterUrl),
          ))
          .write(
            ContentUnitsCompanion(
              localPath: Value(path),
              downloaded: Value(path != null),
            ),
          );
    });
  }

  // Scanlators a title hides. Kept as a JSON list on the entry so it travels with it.
  Stream<List<String>> watchExcludedScanlators(int libraryEntryId) {
    return (_db.select(_db.libraryEntries)
          ..where((t) => t.id.equals(libraryEntryId)))
        .watchSingleOrNull()
        .map((row) => decodeScanlatorList(row?.excludedScanlators));
  }

  Future<Result<void, AppFailure>> setExcludedScanlators(
    int libraryEntryId,
    List<String> scanlators,
  ) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await (_db.update(
        _db.libraryEntries,
      )..where((t) => t.id.equals(libraryEntryId))).write(
        LibraryEntriesCompanion(
          excludedScanlators: Value(encodeScanlatorList(scanlators)),
        ),
      );
    });
  }

  Stream<bool> watchChapterBookmarked({
    required int libraryEntryId,
    required String chapterUrl,
  }) {
    return (_db.select(_db.contentUnits)..where(
          (t) =>
              t.libraryEntryId.equals(libraryEntryId) &
              t.url.equals(chapterUrl),
        ))
        .watchSingleOrNull()
        .map((row) => row?.bookmarked ?? false);
  }

  Future<Result<void, AppFailure>> setChaptersBookmarked({
    required int libraryEntryId,
    required List<String> chapterUrls,
    required bool bookmarked,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      if (chapterUrls.isEmpty) return;
      await (_db.update(_db.contentUnits)..where(
            (t) =>
                t.libraryEntryId.equals(libraryEntryId) &
                t.url.isIn(chapterUrls),
          ))
          .write(ContentUnitsCompanion(bookmarked: Value(bookmarked)));
    });
  }

  Future<Result<List<ChapterRecord>, AppFailure>> getAllChapters(
    int libraryEntryId,
  ) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final branchId = await _ensureActiveBranch(libraryEntryId);
      if (branchId == null) return [];
      final query =
          _db.select(_db.contentUnits).join([
              leftOuterJoin(
                _db.chapterProgress,
                _db.chapterProgress.contentUnitId.equalsExp(
                      _db.contentUnits.id,
                    ) &
                    _db.chapterProgress.branchId.equals(branchId),
              ),
            ])
            ..where(_db.contentUnits.libraryEntryId.equals(libraryEntryId))
            ..orderBy([OrderingTerm.asc(_db.contentUnits.number)]);

      final rows = await query.get();
      return [
        for (final row in rows)
          ChapterRecord(
            url: row.readTable(_db.contentUnits).url,
            number: row.readTable(_db.contentUnits).number,
            title: row.readTable(_db.contentUnits).displayTitle,
            dateUploaded: row.readTable(_db.contentUnits).dateUploaded,
            consumed:
                row.readTableOrNull(_db.chapterProgress)?.consumed ?? false,
            consumedAt: row.readTableOrNull(_db.chapterProgress)?.consumedAt,
            progressPosition: row
                .readTableOrNull(_db.chapterProgress)
                ?.progressPosition,
            bookmarked: row.readTable(_db.contentUnits).bookmarked,
            scanlator: row.readTable(_db.contentUnits).scanlator,
          ),
      ];
    });
  }
}
