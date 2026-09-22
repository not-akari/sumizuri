// Drift method for moving a library entry to another source.
part of 'library_repository_impl.dart';

mixin DriftLibraryMoveMethods {
  AppDatabase get _db;
  AppLogger get _logger;
  int get profileId;
  Future<Result<MoveOutcome, AppFailure>> moveEntryToSource({
    required int entryId,
    required String sourceId,
    required String externalId,
    String? coverUrl,
    String? status,
    required List<ChapterSyncItem> newChapters,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      return _db.transaction(() async {
        final oldUnits = await (_db.select(
          _db.contentUnits,
        )..where((t) => t.libraryEntryId.equals(entryId))).get();

        await (_db.update(
          _db.libraryEntries,
        )..where((t) => t.id.equals(entryId))).write(
          LibraryEntriesCompanion(
            sourceId: Value(sourceId),
            externalId: Value(externalId),
            coverUrl: Value(coverUrl),
            status: Value(status),
            sourceKey: const Value(null),
            lastUpdatedAt: Value(DateTime.now()),
          ),
        );

        await _db.batch((batch) {
          for (final chapter in newChapters) {
            batch.insert(
              _db.contentUnits,
              ContentUnitsCompanion.insert(
                libraryEntryId: entryId,
                url: chapter.url,
                number: chapter.number ?? 0,
                displayTitle: Value(chapter.title),
                dateUploaded: Value(chapter.dateUploaded ?? DateTime.now()),
                scanlator: Value(chapter.scanlator),
              ),
              mode: InsertMode.insertOrIgnore,
            );
          }
        });
        final newUnits =
            await (_db.select(_db.contentUnits)..where(
                  (t) =>
                      t.libraryEntryId.equals(entryId) &
                      t.url.isIn([for (final c in newChapters) c.url]),
                ))
                .get();
        final newIds = {for (final u in newUnits) u.id};
        final byNumber = <double, ContentUnit>{};
        for (final unit in newUnits) {
          byNumber.putIfAbsent(unit.number, () => unit);
        }
        ContentUnit? counterpart(ContentUnit old) {
          for (final entry in byNumber.entries) {
            if ((entry.key - old.number).abs() < 1e-6) return entry.value;
          }
          return null;
        }

        var carried = 0;
        var dropped = 0;
        var bookmarks = 0;
        for (final old in oldUnits) {
          if (newIds.contains(old.id)) continue;
          final target = counterpart(old);
          if (target == null) {
            dropped++;
            continue;
          }
          final progress = await (_db.select(
            _db.chapterProgress,
          )..where((t) => t.contentUnitId.equals(old.id))).get();
          for (final row in progress) {
            await _db
                .into(_db.chapterProgress)
                .insert(
                  ChapterProgressCompanion.insert(
                    contentUnitId: target.id,
                    branchId: row.branchId,
                    consumed: Value(row.consumed),
                    consumedAt: Value(row.consumedAt),
                    progressPosition: Value(row.progressPosition),
                  ),
                  onConflict: DoUpdate(
                    (_) => ChapterProgressCompanion(
                      consumed: Value(row.consumed),
                      consumedAt: Value(row.consumedAt),
                      progressPosition: Value(row.progressPosition),
                    ),
                    target: [
                      _db.chapterProgress.contentUnitId,
                      _db.chapterProgress.branchId,
                    ],
                  ),
                );
          }
          final sessions =
              await (_db.update(
                _db.readingSessions,
              )..where((t) => t.contentUnitId.equals(old.id))).write(
                ReadingSessionsCompanion(contentUnitId: Value(target.id)),
              );
          if (old.bookmarked && !target.bookmarked) {
            await (_db.update(_db.contentUnits)
                  ..where((t) => t.id.equals(target.id)))
                .write(const ContentUnitsCompanion(bookmarked: Value(true)));
            bookmarks++;
          }
          if (progress.isNotEmpty || sessions > 0) carried++;
        }

        await (_db.delete(_db.contentUnits)..where(
              (t) => t.libraryEntryId.equals(entryId) & t.id.isNotIn(newIds),
            ))
            .go();
        return MoveOutcome(
          carried: carried,
          dropped: dropped,
          bookmarks: bookmarks,
        );
      });
    });
  }
}
