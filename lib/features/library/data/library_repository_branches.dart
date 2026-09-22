// Drift methods for reading and managing an entry's branches.
part of 'library_repository_impl.dart';

mixin DriftLibraryBranchMethods {
  AppDatabase get _db;
  AppLogger get _logger;

  Stream<List<EntryBranch>> watchBranches(int libraryEntryId) {
    return (_db.select(_db.entryBranches)
          ..where((t) => t.libraryEntryId.equals(libraryEntryId))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .watch()
        .map(
          (rows) => [
            for (final row in rows)
              EntryBranch(
                id: row.id,
                libraryEntryId: row.libraryEntryId,
                name: row.name,
                createdAt: row.createdAt,
              ),
          ],
        );
  }

  Stream<int?> watchActiveBranchId(int libraryEntryId) {
    return (_db.select(_db.libraryEntries)
          ..where((t) => t.id.equals(libraryEntryId)))
        .watchSingleOrNull()
        .map((entry) => entry?.activeBranchId);
  }

  Future<Result<EntryBranch, AppFailure>> createBranch({
    required int libraryEntryId,
    required String name,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final trimmed = name.trim();
      final branchId = await _db
          .into(_db.entryBranches)
          .insert(
            EntryBranchesCompanion.insert(
              libraryEntryId: libraryEntryId,
              name: trimmed.isEmpty ? 'Branch' : trimmed,
            ),
          );
      final row = await (_db.select(
        _db.entryBranches,
      )..where((t) => t.id.equals(branchId))).getSingle();
      return EntryBranch(
        id: row.id,
        libraryEntryId: row.libraryEntryId,
        name: row.name,
        createdAt: row.createdAt,
      );
    });
  }

  Future<Result<void, AppFailure>> switchBranch({
    required int libraryEntryId,
    required int branchId,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      await (_db.update(_db.libraryEntries)
            ..where((t) => t.id.equals(libraryEntryId)))
          .write(LibraryEntriesCompanion(activeBranchId: Value(branchId)));
    });
  }

  Future<Result<void, AppFailure>> renameBranch({
    required int branchId,
    required String name,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final trimmed = name.trim();
      if (trimmed.isEmpty) return;
      await (_db.update(_db.entryBranches)..where((t) => t.id.equals(branchId)))
          .write(EntryBranchesCompanion(name: Value(trimmed)));
    });
  }

  Future<Result<void, AppFailure>> deleteBranch({
    required int libraryEntryId,
    required int branchId,
  }) {
    return guardFailure(_logger, DriftLibraryRepository._tag, () async {
      final branches = await (_db.select(
        _db.entryBranches,
      )..where((t) => t.libraryEntryId.equals(libraryEntryId))).get();
      if (branches.length <= 1) {
        throw const DatabaseFailure(
          'Cannot delete the only branch of an entry',
        );
      }
      await _db.transaction(() async {
        final entry = await (_db.select(
          _db.libraryEntries,
        )..where((t) => t.id.equals(libraryEntryId))).getSingleOrNull();
        if (entry?.activeBranchId == branchId) {
          final otherBranch = branches.firstWhere((b) => b.id != branchId);
          await (_db.update(
            _db.libraryEntries,
          )..where((t) => t.id.equals(libraryEntryId))).write(
            LibraryEntriesCompanion(activeBranchId: Value(otherBranch.id)),
          );
        }
        await (_db.delete(
          _db.entryBranches,
        )..where((t) => t.id.equals(branchId))).go();
      });
    });
  }
}
