// Drift implementation of the library repository, combining the mixins in this folder.
import 'dart:async';

import 'package:drift/drift.dart';

import 'package:sumizuri/features/library/models/series_overrides.dart';
import 'package:sumizuri/bootstrap/database/app_database.dart' hide Category;
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/utils/async/shared_stream_replay.dart';
import 'package:sumizuri/features/library/data/chapter_reconcile.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/library/models/category.dart';
import 'package:sumizuri/features/library/models/category_smart_rule.dart';
import 'package:sumizuri/features/library/models/downloaded_entry.dart';
import 'package:sumizuri/features/library/models/entry_branch.dart';
import 'package:sumizuri/features/library/models/library_duplicate_match.dart';
import 'package:sumizuri/features/library/models/library_entry_summary.dart';
import 'package:sumizuri/features/library/models/library_feed_types.dart';
import 'package:sumizuri/features/library/data/library_repository.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/library/models/library_update_rules.dart';
import 'package:sumizuri/features/library/models/scanlator_filter.dart';
import 'package:sumizuri/features/library/models/reading_session_record.dart';
import 'package:sumizuri/features/reader/models/reader_settings_types.dart';
import 'package:sumizuri/core/errors/guard_failure.dart';

part 'library_repository_branches.dart';
part 'library_repository_categories.dart';
part 'library_repository_chapters.dart';
part 'library_repository_history.dart';
part 'library_repository_move.dart';
part 'library_repository_restore.dart';

/// One line of the history and updates feeds, read from a joined chapter and entry row.
typedef ChapterFeedRow = ({
  int libraryEntryId,
  String entryTitle,
  String? entryCoverUrl,
  String? customCoverPath,
  String sourceId,
  String externalId,
  String chapterUrl,
  double chapterNumber,
  String? chapterTitle,
});

class DriftLibraryRepository
    with
        DriftLibraryCategoryMethods,
        DriftLibraryChapterMethods,
        DriftLibraryMoveMethods,
        DriftLibraryRestoreMethods,
        DriftLibraryBranchMethods,
        DriftLibraryHistoryMethods
    implements LibraryRepository {
  DriftLibraryRepository(this._db, this._logger, {this.profileId = 1});

  @override
  final AppDatabase _db;
  @override
  final AppLogger _logger;
  @override
  final int profileId;

  static const _tag = 'library';

  @override
  Future<String?> entryTitle(int libraryEntryId) async {
    final row = await (_db.select(
      _db.libraryEntries,
    )..where((t) => t.id.equals(libraryEntryId))).getSingleOrNull();
    return row?.title;
  }

  @override
  Stream<List<LibraryEntrySummary>> watchLibrary({MediaType? mediaType}) {
    final units = _db.contentUnits.actualTableName;
    final entries = _db.libraryEntries.actualTableName;
    final hidden = CustomExpression<bool>(
      '$units.scanlator IS NOT NULL AND $entries.excluded_scanlators IS NOT NULL '
      'AND instr($entries.excluded_scanlators, json_quote($units.scanlator)) > 0',
    );
    final unreadCount = _db.contentUnits.id.count(
      filter:
          _db.contentUnits.id.isNotNull() &
          (_db.chapterProgress.consumed.isNull() |
              _db.chapterProgress.consumed.equals(false)) &
          hidden.equals(false),
    );

    final query = _db.select(_db.libraryEntries).join([
      leftOuterJoin(
        _db.contentUnits,
        _db.contentUnits.libraryEntryId.equalsExp(_db.libraryEntries.id),
      ),
      leftOuterJoin(
        _db.chapterProgress,
        _db.chapterProgress.contentUnitId.equalsExp(_db.contentUnits.id) &
            _db.chapterProgress.branchId.equalsExp(
              _db.libraryEntries.activeBranchId,
            ),
      ),
    ])..addColumns([unreadCount]);

    var where = _db.libraryEntries.profileId.equals(profileId);
    if (mediaType != null) {
      where = where & _db.libraryEntries.mediaType.equalsValue(mediaType);
    }
    query.where(where);

    query
      ..groupBy([_db.libraryEntries.id])
      ..orderBy([OrderingTerm.desc(_db.libraryEntries.lastUpdatedAt)]);

    return query.watch().map(
      (rows) => rows.map((row) {
        final entry = row.readTable(_db.libraryEntries);
        return LibraryEntrySummary(
          id: entry.id,
          title: entry.title,
          coverUrl: entry.coverUrl,
          customCoverPath: entry.customCoverPath,
          mediaType: entry.mediaType,
          favorite: entry.favorite,
          unreadCount: row.read(unreadCount) ?? 0,
          sourceId: entry.sourceId,
          externalId: entry.externalId,
          status: entry.status,
          addedAt: entry.addedAt,
          lastUpdatedAt: entry.lastUpdatedAt,
        );
      }).toList(),
    );
  }

  @override
  Future<Result<void, AppFailure>> addToLibrary({
    required String title,
    String? coverUrl,
    required MediaType mediaType,
    required String sourceId,
    required String externalId,
  }) {
    return guardFailure(_logger, _tag, () async {
      await _db.transaction(() async {
        final entryId = await _db
            .into(_db.libraryEntries)
            .insert(
              LibraryEntriesCompanion.insert(
                title: title,
                coverUrl: Value(coverUrl),
                mediaType: mediaType,
                sourceId: sourceId,
                externalId: externalId,
                profileId: Value(profileId),
              ),
              mode: InsertMode.insertOrIgnore,
            );
        if (entryId > 0) {
          final branchId = await _db
              .into(_db.entryBranches)
              .insert(
                EntryBranchesCompanion.insert(
                  libraryEntryId: entryId,
                  name: 'Main',
                ),
              );
          await (_db.update(_db.libraryEntries)
                ..where((t) => t.id.equals(entryId)))
              .write(LibraryEntriesCompanion(activeBranchId: Value(branchId)));
        }
      });
    });
  }

  @override
  Future<Result<LibraryMatch, AppFailure>> checkLibraryMatch({
    required String title,
    required String sourceId,
    required String externalId,
  }) {
    return guardFailure(_logger, _tag, () async {
      final exact =
          await (_db.select(_db.libraryEntries)..where(
                (t) =>
                    t.profileId.equals(profileId) &
                    t.sourceId.equals(sourceId) &
                    t.externalId.equals(externalId),
              ))
              .getSingleOrNull();
      if (exact != null) return LibraryMatch(exactMatchId: exact.id);

      final all = await (_db.select(
        _db.libraryEntries,
      )..where((t) => t.profileId.equals(profileId))).get();
      final lowerTitle = title.toLowerCase();
      final matches = all
          .where(
            (e) =>
                e.sourceId != sourceId && e.title.toLowerCase() == lowerTitle,
          )
          .map(
            (e) => LibraryDuplicateCandidate(
              id: e.id,
              title: e.title,
              coverUrl: e.coverUrl,
              sourceId: e.sourceId,
            ),
          )
          .toList();
      return LibraryMatch(otherSourceMatches: matches);
    });
  }

  @override
  Future<Result<void, AppFailure>> migrateLibraryEntry({
    required int entryId,
    required String sourceId,
    required String externalId,
    required MediaType mediaType,
    String? coverUrl,
    String? status,
  }) {
    return guardFailure(_logger, _tag, () async {
      await (_db.update(
            _db.libraryEntries,
          )..where((t) => t.profileId.equals(profileId) & t.id.equals(entryId)))
          .write(
            LibraryEntriesCompanion(
              sourceId: Value(sourceId),
              externalId: Value(externalId),
              mediaType: Value(mediaType),
              coverUrl: Value.absentIfNull(coverUrl),
              status: Value.absentIfNull(status),
              lastUpdatedAt: Value(DateTime.now()),
            ),
          );
    });
  }

  @override
  Future<Result<void, AppFailure>> fillMissingCover(
    int entryId,
    String coverUrl,
  ) {
    return guardFailure(_logger, _tag, () async {
      await (_db.update(_db.libraryEntries)..where(
            (t) =>
                t.profileId.equals(profileId) &
                t.id.equals(entryId) &
                (t.coverUrl.isNull() | t.coverUrl.equals('')),
          ))
          .write(LibraryEntriesCompanion(coverUrl: Value(coverUrl)));
    });
  }

  @override
  Stream<Set<String>> watchLibraryExternalIds(String sourceId) {
    final query = _db.select(_db.libraryEntries)
      ..where(
        (t) => t.profileId.equals(profileId) & t.sourceId.equals(sourceId),
      );
    return query.watch().map((rows) => rows.map((r) => r.externalId).toSet());
  }

  @override
  Future<Result<void, AppFailure>> removeFromLibrary(int entryId) {
    return guardFailure(_logger, _tag, () async {
      await (_db.delete(
            _db.libraryEntries,
          )..where((t) => t.profileId.equals(profileId) & t.id.equals(entryId)))
          .go();
    });
  }

  @override
  Stream<ReaderMode?> watchEntryReaderMode(int entryId) {
    return (_db.select(_db.libraryEntries)..where((t) => t.id.equals(entryId)))
        .watchSingleOrNull()
        .map((row) => row?.readerMode);
  }

  @override
  Stream<SeriesOverrides> watchEntryOverrides(int entryId) {
    return (_db.select(_db.libraryEntries)..where((t) => t.id.equals(entryId)))
        .watchSingleOrNull()
        .map((row) => SeriesOverrides.decode(row?.settingsOverrides))
        .distinct();
  }

  @override
  Future<Result<void, AppFailure>> updateEntryOverrides({
    required int entryId,
    required SeriesOverrides overrides,
  }) {
    return guardFailure(_logger, _tag, () async {
      await (_db.update(
        _db.libraryEntries,
      )..where((t) => t.id.equals(entryId))).write(
        LibraryEntriesCompanion(settingsOverrides: Value(overrides.encode())),
      );
    });
  }

  @override
  Stream<ReaderDualPageMode?> watchEntryDualPageMode(int entryId) {
    return (_db.select(_db.libraryEntries)..where((t) => t.id.equals(entryId)))
        .watchSingleOrNull()
        .map((row) => row?.readerDualPageMode);
  }

  @override
  Future<Result<void, AppFailure>> updateEntryDualPageMode({
    required int entryId,
    required ReaderDualPageMode? mode,
  }) {
    return guardFailure(_logger, _tag, () async {
      await (_db.update(_db.libraryEntries)..where((t) => t.id.equals(entryId)))
          .write(LibraryEntriesCompanion(readerDualPageMode: Value(mode)));
    });
  }

  @override
  Future<Result<void, AppFailure>> updateEntryReaderMode({
    required int entryId,
    required ReaderMode? readerMode,
  }) {
    return guardFailure(_logger, _tag, () async {
      await (_db.update(_db.libraryEntries)..where((t) => t.id.equals(entryId)))
          .write(LibraryEntriesCompanion(readerMode: Value(readerMode)));
    });
  }

  @override
  Future<bool> hasCheckedReaderMode(int entryId) async {
    final row =
        await (_db.select(
          _db.libraryEntries,
        )..where((t) => t.id.equals(entryId))).getSingleOrNull();
    return row?.readerModeChecked ?? false;
  }

  @override
  Future<Result<void, AppFailure>> markReaderModeChecked(int entryId) {
    return guardFailure(_logger, _tag, () async {
      await (_db.update(_db.libraryEntries)..where((t) => t.id.equals(entryId)))
          .write(const LibraryEntriesCompanion(readerModeChecked: Value(true)));
    });
  }

  @override
  JoinedSelectStatement<HasResultSet, dynamic> _chapterFeedQuery(
    Expression<bool> where,
    OrderingTerm orderBy,
    int limit,
  ) {
    return _db.select(_db.contentUnits).join([
        innerJoin(
          _db.libraryEntries,
          _db.libraryEntries.id.equalsExp(_db.contentUnits.libraryEntryId),
        ),
        leftOuterJoin(
          _db.chapterProgress,
          _db.chapterProgress.contentUnitId.equalsExp(_db.contentUnits.id) &
              _db.chapterProgress.branchId.equalsExp(
                _db.libraryEntries.activeBranchId,
              ),
        ),
      ])
      ..where(where)
      ..orderBy([orderBy])
      ..limit(limit);
  }

  @override
  ChapterFeedRow _readChapterFeedRow(TypedResult row) {
    final chapter = row.readTable(_db.contentUnits);
    final entry = row.readTable(_db.libraryEntries);
    return (
      libraryEntryId: entry.id,
      entryTitle: entry.title,
      entryCoverUrl: entry.coverUrl,
      customCoverPath: entry.customCoverPath,
      sourceId: entry.sourceId,
      externalId: entry.externalId,
      chapterUrl: chapter.url,
      chapterNumber: chapter.number,
      chapterTitle: chapter.displayTitle,
    );
  }

  @override
  Stream<List<UpdateChapterSummary>> watchUpdates({
    MediaType? mediaType,
    int limit = 200,
  }) {
    var where =
        _db.libraryEntries.profileId.equals(profileId) &
        (_db.chapterProgress.consumed.isNull() |
            _db.chapterProgress.consumed.equals(false));
    if (mediaType != null) {
      where = where & _db.libraryEntries.mediaType.equalsValue(mediaType);
    }
    final query = _chapterFeedQuery(
      where,
      OrderingTerm.desc(_db.contentUnits.dateUploaded),
      limit,
    );

    return query.watch().map(
      (rows) => rows.map((row) {
        final fields = _readChapterFeedRow(row);
        return UpdateChapterSummary(
          libraryEntryId: fields.libraryEntryId,
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
}
