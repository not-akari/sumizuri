// Drift methods for the reading history and continue reading feeds.
part of 'library_repository_impl.dart';

mixin DriftLibraryHistoryMethods {
  AppDatabase get _db;
  AppLogger get _logger;
  int get profileId;

  ChapterFeedRow _readChapterFeedRow(TypedResult row);

  JoinedSelectStatement<HasResultSet, dynamic> _chapterFeedQuery(
    Expression<bool> where,
    OrderingTerm orderBy,
    int limit,
  );

  Stream<List<HistoryChapterSummary>> watchHistory({
    MediaType? mediaType,
    int limit = 200,
  }) {
    var where =
        _db.libraryEntries.profileId.equals(profileId) &
        _db.chapterProgress.consumed.equals(true);
    if (mediaType != null) {
      where = where & _db.libraryEntries.mediaType.equalsValue(mediaType);
    }
    final query = _chapterFeedQuery(
      where,
      OrderingTerm.desc(_db.chapterProgress.consumedAt),
      limit,
    );

    return query.watch().map(
      (rows) => rows.map((row) {
        final fields = _readChapterFeedRow(row);
        return HistoryChapterSummary(
          libraryEntryId: fields.libraryEntryId,
          entryTitle: fields.entryTitle,
          entryCoverUrl: fields.entryCoverUrl,
          customCoverPath: fields.customCoverPath,
          sourceId: fields.sourceId,
          externalId: fields.externalId,
          chapterUrl: fields.chapterUrl,
          chapterNumber: fields.chapterNumber,
          chapterTitle: fields.chapterTitle,
          consumedAt:
              row.readTableOrNull(_db.chapterProgress)?.consumedAt ??
              DateTime.now(),
        );
      }).toList(),
    );
  }

  Stream<double?> watchFurthestRead(int libraryEntryId) {
    final maxNumber = _db.contentUnits.number.max();
    final query =
        _db.selectOnly(_db.contentUnits).join([
            innerJoin(
              _db.libraryEntries,
              _db.libraryEntries.id.equalsExp(_db.contentUnits.libraryEntryId),
            ),
            innerJoin(
              _db.chapterProgress,
              _db.chapterProgress.contentUnitId.equalsExp(_db.contentUnits.id) &
                  _db.chapterProgress.branchId.equalsExp(
                    _db.libraryEntries.activeBranchId,
                  ),
            ),
          ])
          ..addColumns([maxNumber])
          ..where(
            _db.contentUnits.libraryEntryId.equals(libraryEntryId) &
                _db.chapterProgress.consumed.equals(true),
          );
    return query.watchSingleOrNull().map((row) => row?.read(maxNumber));
  }

  Stream<Map<int, double?>> watchFurthestReadMany(List<int> libraryEntryIds) {
    if (libraryEntryIds.isEmpty) return Stream.value(const {});
    final entryId = _db.contentUnits.libraryEntryId;
    final maxNumber = _db.contentUnits.number.max();
    final query =
        _db.selectOnly(_db.contentUnits).join([
            innerJoin(
              _db.libraryEntries,
              _db.libraryEntries.id.equalsExp(entryId),
            ),
            innerJoin(
              _db.chapterProgress,
              _db.chapterProgress.contentUnitId.equalsExp(_db.contentUnits.id) &
                  _db.chapterProgress.branchId.equalsExp(
                    _db.libraryEntries.activeBranchId,
                  ),
            ),
          ])
          ..addColumns([entryId, maxNumber])
          ..where(
            entryId.isIn(libraryEntryIds) &
                _db.chapterProgress.consumed.equals(true),
          )
          ..groupBy([entryId]);
    return query.watch().map(
      (rows) => {
        for (final row in rows) row.read(entryId)!: row.read(maxNumber),
      },
    );
  }

  Stream<List<ReadingSessionRecord>> watchTimeline({
    int? libraryEntryId,
    MediaType? mediaType,
    int? limit = 200,
  }) {
    var where = _db.libraryEntries.profileId.equals(profileId);
    if (mediaType != null) {
      where = where & _db.libraryEntries.mediaType.equalsValue(mediaType);
    }
    if (libraryEntryId != null) {
      where = where & _db.readingSessions.libraryEntryId.equals(libraryEntryId);
    }

    final query =
        _db.select(_db.readingSessions).join([
            innerJoin(
              _db.libraryEntries,
              _db.libraryEntries.id.equalsExp(
                _db.readingSessions.libraryEntryId,
              ),
            ),
            innerJoin(
              _db.contentUnits,
              _db.contentUnits.id.equalsExp(_db.readingSessions.contentUnitId),
            ),
          ])
          ..where(where)
          ..orderBy([
            OrderingTerm.desc(_db.readingSessions.readAt),
            OrderingTerm.desc(_db.readingSessions.id),
          ]);
    if (limit != null) {
      query.limit(limit);
    }

    return query.watch().map((rows) {
      return rows.map((row) {
        final session = row.readTable(_db.readingSessions);
        final entry = row.readTable(_db.libraryEntries);
        final unit = row.readTable(_db.contentUnits);
        return ReadingSessionRecord(
          id: session.id,
          libraryEntryId: entry.id,
          branchId: session.branchId,
          entryTitle: entry.title,
          entryCoverUrl: entry.coverUrl,
          customCoverPath: entry.customCoverPath,
          sourceId: entry.sourceId,
          externalId: entry.externalId,
          contentUnitId: unit.id,
          chapterUrl: unit.url,
          chapterNumber: unit.number,
          chapterTitle: unit.displayTitle,
          readAt: session.readAt,
        );
      }).toList();
    });
  }

  Stream<List<UpdateChapterSummary>> watchAllChapterDates({
    MediaType? mediaType,
  }) {
    var where = _db.libraryEntries.profileId.equals(profileId);
    if (mediaType != null) {
      where = where & _db.libraryEntries.mediaType.equalsValue(mediaType);
    }
    final query = _chapterFeedQuery(
      where,
      OrderingTerm.asc(_db.contentUnits.dateUploaded),
      1000000,
    );

    return query.watch().map(
      (rows) => rows.map((row) {
        final fields = _readChapterFeedRow(row);
        return UpdateChapterSummary(
          libraryEntryId: fields.libraryEntryId,
          mediaType: fields.mediaType,
          entryTitle: fields.entryTitle,
          entryCoverUrl: fields.entryCoverUrl,
          customCoverPath: fields.customCoverPath,
          sourceId: fields.sourceId,
          externalId: fields.externalId,
          chapterUrl: fields.chapterUrl,
          chapterNumber: fields.chapterNumber,
          chapterTitle: fields.chapterTitle,
          dateUploaded: row.readTable(_db.contentUnits).dateUploaded,
        );
      }).toList(),
    );
  }

  Stream<String?> watchCustomCoverPath(int entryId) {
    return (_db.select(_db.libraryEntries)..where((t) => t.id.equals(entryId)))
        .watchSingleOrNull()
        .map((row) => row?.customCoverPath);
  }

  Future<Result<void, AppFailure>> setCustomCoverPath({
    required int entryId,
    required String? path,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await (_db.update(_db.libraryEntries)..where((t) => t.id.equals(entryId)))
          .write(LibraryEntriesCompanion(customCoverPath: Value(path)));
    });
  }
}
