// Drift methods for reading and managing library categories.
part of 'library_repository_impl.dart';

// Shared category watch per profile replayed to client-side filtered listeners.
final _sharedCategoryWatches =
    Expando<Map<int, SharedStreamReplay<List<Category>>>>(
      'sharedCategoryWatches',
    );

mixin DriftLibraryCategoryMethods {
  AppDatabase get _db;
  AppLogger get _logger;
  int get profileId;

  Stream<List<Category>> _watchAllCategories() {
    final byProfile = _sharedCategoryWatches[_db] ??= {};
    final shared = byProfile.putIfAbsent(profileId, () {
      final query = _db.select(_db.categories)
        ..where((t) => t.profileId.equals(profileId))
        ..orderBy([(t) => OrderingTerm.asc(t.sortOrder)]);
      return SharedStreamReplay(
        query.watch().map(
          (rows) => rows
              .map(
                (r) => Category(
                  id: r.id,
                  name: r.name,
                  sortOrder: r.sortOrder,
                  excludeFromUpdate: r.excludeFromUpdate,
                  mediaType: r.mediaType,
                  useSmartRule: r.useSmartRule,
                  sortField: r.sortField,
                  sortAscending: r.sortAscending,
                  statusFilter: r.statusFilter,
                ),
              )
              .toList(),
        ),
      );
    });
    return shared.watch();
  }

  Stream<List<Category>> watchCategories({MediaType? mediaType}) {
    final all = _watchAllCategories();
    if (mediaType == null) return all;
    return all.map(
      (categories) => [
        for (final c in categories)
          if (c.mediaType == mediaType) c,
      ],
    );
  }

  Future<Result<int, AppFailure>> createCategory(
    String name, {
    required MediaType mediaType,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final existing =
          await (_db.select(_db.categories)..where(
                (t) =>
                    t.profileId.equals(profileId) &
                    t.mediaType.equalsValue(mediaType),
              ))
              .get();
      return _db
          .into(_db.categories)
          .insert(
            CategoriesCompanion.insert(
              name: name,
              sortOrder: Value(existing.length),
              mediaType: Value(mediaType),
              profileId: Value(profileId),
            ),
          );
    });
  }

  Future<Result<void, AppFailure>> renameCategory({
    required int id,
    required String name,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(name: Value(name)),
      );
    });
  }

  Future<Result<void, AppFailure>> deleteCategory(int id) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await (_db.delete(_db.categories)..where((t) => t.id.equals(id))).go();
    });
  }

  Future<Result<void, AppFailure>> reorderCategories(List<int> orderedIds) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await _db.batch((batch) {
        for (var i = 0; i < orderedIds.length; i++) {
          batch.update(
            _db.categories,
            CategoriesCompanion(sortOrder: Value(i)),
            where: (t) => t.id.equals(orderedIds[i]),
          );
        }
      });
    });
  }

  Future<Result<void, AppFailure>> setCategoryExcludeFromUpdate({
    required int id,
    required bool exclude,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(excludeFromUpdate: Value(exclude)),
      );
    });
  }

  Future<Result<void, AppFailure>> setCategorySmartRule({
    required int id,
    required bool useSmartRule,
    required CategorySortField sortField,
    required bool sortAscending,
    required CategoryStatusFilter statusFilter,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await (_db.update(_db.categories)..where((t) => t.id.equals(id))).write(
        CategoriesCompanion(
          useSmartRule: Value(useSmartRule),
          sortField: Value(sortField),
          sortAscending: Value(sortAscending),
          statusFilter: Value(statusFilter),
        ),
      );
    });
  }

  Stream<Set<int>> watchEntryCategoryIds(int entryId) {
    final query = _db.select(_db.entryCategories)
      ..where((t) => t.libraryEntryId.equals(entryId));
    return query.watch().map((rows) => rows.map((r) => r.categoryId).toSet());
  }

  Stream<Map<int, Set<int>>> watchAllEntryCategoryIds() {
    final query = _db.select(_db.entryCategories).join([
      innerJoin(
        _db.libraryEntries,
        _db.libraryEntries.id.equalsExp(_db.entryCategories.libraryEntryId),
      ),
    ])..where(_db.libraryEntries.profileId.equals(profileId));

    return query.watch().map((rows) {
      final map = <int, Set<int>>{};
      for (final row in rows) {
        final entryCategory = row.readTable(_db.entryCategories);
        map
            .putIfAbsent(entryCategory.libraryEntryId, () => {})
            .add(entryCategory.categoryId);
      }
      return map;
    });
  }

  Future<Result<void, AppFailure>> setEntryCategories({
    required int entryId,
    required Set<int> categoryIds,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await _db.transaction(() async {
        await (_db.delete(
          _db.entryCategories,
        )..where((t) => t.libraryEntryId.equals(entryId))).go();
        if (categoryIds.isEmpty) return;
        await _db.batch((batch) {
          batch.insertAll(_db.entryCategories, [
            for (final categoryId in categoryIds)
              EntryCategoriesCompanion.insert(
                libraryEntryId: entryId,
                categoryId: categoryId,
              ),
          ]);
        });
      });
    });
  }

  Future<Result<List<LibraryEntrySummary>, AppFailure>>
  entriesEligibleForUpdate({int skip = 0}) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final excludedRows =
          await (_db.selectOnly(_db.entryCategories)
                ..addColumns([_db.entryCategories.libraryEntryId])
                ..join([
                  innerJoin(
                    _db.categories,
                    _db.categories.id.equalsExp(_db.entryCategories.categoryId),
                  ),
                ])
                ..where(_db.categories.excludeFromUpdate.equals(true)))
              .get();
      final excludedIds = excludedRows
          .map((r) => r.read(_db.entryCategories.libraryEntryId)!)
          .toSet();

      final allEntries = await (_db.select(
        _db.libraryEntries,
      )..where((t) => t.profileId.equals(profileId))).get();

      final needsCounts =
          LibraryUpdateSkip.has(skip, LibraryUpdateSkip.unread) ||
          LibraryUpdateSkip.has(skip, LibraryUpdateSkip.notStarted);
      final totals = <int, int>{};
      final reads = <int, int>{};
      if (needsCounts) {
        final rows = await _db
            .customSelect(
              'SELECT c.library_entry_id AS entry, COUNT(*) AS total, '
              'COUNT(DISTINCT CASE WHEN p.consumed = 1 THEN c.id END) AS read '
              'FROM content_units c '
              'LEFT JOIN chapter_progress p ON p.content_unit_id = c.id '
              'GROUP BY c.library_entry_id',
              readsFrom: {_db.contentUnits, _db.chapterProgress},
            )
            .get();
        for (final row in rows) {
          final entry = row.read<int>('entry');
          totals[entry] = row.read<int>('total');
          reads[entry] = row.read<int>('read');
        }
      }

      return allEntries
          .where((e) => !excludedIds.contains(e.id))
          .where(
            (e) => !skipsInUpdate(
              mask: skip,
              status: e.status,
              total: totals[e.id] ?? 0,
              read: reads[e.id] ?? 0,
            ),
          )
          .map(
            (e) => LibraryEntrySummary(
              id: e.id,
              title: e.title,
              coverUrl: e.coverUrl,
              customCoverPath: e.customCoverPath,
              mediaType: e.mediaType,
              favorite: e.favorite,
              unreadCount: 0,
              sourceId: e.sourceId,
              externalId: e.externalId,
              status: e.status,
              addedAt: e.addedAt,
              lastUpdatedAt: e.lastUpdatedAt,
            ),
          )
          .toList();
    });
  }
}
