// Drift backed repository for installed source extensions.
import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/data/source_relink.dart';
import 'package:sumizuri/features/repos/data/repo_url.dart';
import 'package:sumizuri/features/extensions/data/installed_source_repository.dart';
import 'package:sumizuri/features/extensions/models/source_key.dart';
import 'package:sumizuri/features/extensions/models/engine_kind.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/core/errors/guard_failure.dart';

class DriftInstalledSourceRepository implements InstalledSourceRepository {
  DriftInstalledSourceRepository(this._db, this._logger);

  final AppDatabase _db;
  final AppLogger _logger;

  static const _tag = 'installed_source';

  AppInstalledSource _fromRow(InstalledSource row) => AppInstalledSource(
    id: row.id,
    name: row.name,
    lang: row.lang,
    mediaType: row.mediaType,
    jsSource: row.jsSource,
    iconUrl: row.iconUrl,
    baseUrl: row.baseUrl,
    enabled: row.enabled,
    engineKind: EngineKind.fromStorage(row.engineKind),
    addedAt: row.addedAt,
    repoUrl: row.repoUrl,
    repoSourceId: row.repoSourceId,
    version: row.version,
    nsfw: row.nsfw,
  );

  @override
  Stream<List<AppInstalledSource>> watchAll() {
    final query = _db.select(_db.installedSources)
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch().map((rows) => rows.map(_fromRow).toList());
  }

  @override
  Future<Result<int, AppFailure>> add({
    required String name,
    required String lang,
    required MediaType mediaType,
    required String jsSource,
    required String iconUrl,
    required String baseUrl,
    EngineKind engineKind = EngineKind.js,
    String? repoUrl,
    String? repoSourceId,
    int version = 1,
    bool nsfw = false,
  }) {
    return guardFailure(_logger, _tag, () async {
      // Installing the same repo source twice (a double tap, or the list not
      // having refreshed yet) updates the row that is there instead of adding
      // a second copy of it. Repo urls are compared normalized, so the same
      // repo written slightly differently still counts as the same one.
      if (repoUrl != null && repoSourceId != null) {
        final wanted = normalizeRepoUrl(repoUrl);
        final candidates = await (_db.select(
          _db.installedSources,
        )..where((t) => t.repoSourceId.equals(repoSourceId))).get();
        for (final row in candidates) {
          if (row.repoUrl != null && normalizeRepoUrl(row.repoUrl!) == wanted) {
            await (_db.update(
              _db.installedSources,
            )..where((t) => t.id.equals(row.id))).write(
              InstalledSourcesCompanion(
                name: Value(name),
                lang: Value(lang),
                mediaType: Value(mediaType),
                jsSource: Value(jsSource),
                iconUrl: Value(iconUrl),
                baseUrl: Value(baseUrl),
                engineKind: Value(engineKind.storageValue),
                version: Value(version),
                nsfw: Value(nsfw),
              ),
            );
            return row.id;
          }
        }
      }
      final id = await _db
          .into(_db.installedSources)
          .insert(
            InstalledSourcesCompanion.insert(
              name: name,
              lang: Value(lang),
              mediaType: mediaType,
              jsSource: jsSource,
              iconUrl: Value(iconUrl),
              baseUrl: Value(baseUrl),
              engineKind: Value(engineKind.storageValue),
              repoUrl: Value(repoUrl),
              repoSourceId: Value(repoSourceId),
              version: Value(version),
              nsfw: Value(nsfw),
            ),
          );
      // Entries that lost this source when it was removed earlier point back to it.
      await relinkEntriesToSource(
        _db,
        sourceRowId: id,
        key: sourceKeyOf(
          repoUrl: repoUrl,
          repoSourceId: repoSourceId,
          name: name,
          baseUrl: baseUrl,
        ),
      );
      return id;
    });
  }

  @override
  Future<Result<void, AppFailure>> update({
    required int id,
    required String name,
    required String lang,
    required MediaType mediaType,
    required String jsSource,
    required String iconUrl,
    required String baseUrl,
    EngineKind engineKind = EngineKind.js,
    String? repoUrl,
    String? repoSourceId,
    int? version,
    bool? nsfw,
  }) {
    return guardFailure(_logger, _tag, () async {
      await (_db.update(
        _db.installedSources,
      )..where((t) => t.id.equals(id))).write(
        InstalledSourcesCompanion(
          name: Value(name),
          lang: Value(lang),
          mediaType: Value(mediaType),
          jsSource: Value(jsSource),
          iconUrl: Value(iconUrl),
          baseUrl: Value(baseUrl),
          engineKind: Value(engineKind.storageValue),
          repoUrl: Value(repoUrl),
          repoSourceId: Value(repoSourceId),
          version: version == null ? const Value.absent() : Value(version),
          nsfw: nsfw == null ? const Value.absent() : Value(nsfw),
        ),
      );
    });
  }

  @override
  Future<Result<int, AppFailure>> mergeDuplicates() {
    return guardFailure(_logger, _tag, () async {
      final groups = duplicateSourceGroups(
        await _db.select(_db.installedSources).get(),
      );
      var removed = 0;
      await _db.transaction(() async {
        for (final group in groups) {
          // Keep the newest version; the earliest install breaks a tie.
          final sorted = [...group]
            ..sort((a, b) {
              final byVersion = b.version.compareTo(a.version);
              return byVersion != 0 ? byVersion : a.id.compareTo(b.id);
            });
          final keeper = sorted.first;
          for (final extra in sorted.skip(1)) {
            // OR IGNORE: a title already on the kept copy stays where it is
            // rather than colliding; that copy is then left alone below.
            await _db.customUpdate(
              'UPDATE OR IGNORE library_entries SET source_id = ? WHERE source_id = ?',
              variables: [
                Variable.withString('${keeper.id}'),
                Variable.withString('${extra.id}'),
              ],
              updates: {_db.libraryEntries},
              updateKind: UpdateKind.update,
            );
            final left =
                await (_db.selectOnly(_db.libraryEntries)
                      ..addColumns([_db.libraryEntries.id])
                      ..where(
                        _db.libraryEntries.sourceId.equals('${extra.id}'),
                      ))
                    .get();
            if (left.isNotEmpty) continue;
            await (_db.delete(
              _db.installedSources,
            )..where((t) => t.id.equals(extra.id))).go();
            removed++;
          }
        }
      });
      return removed;
    });
  }

  @override
  Future<Result<void, AppFailure>> remove(int id) {
    return guardFailure(_logger, _tag, () async {
      final row = await (_db.select(
        _db.installedSources,
      )..where((t) => t.id.equals(id))).getSingleOrNull();
      if (row != null) await rememberSourceOnEntries(_db, row);
      await (_db.delete(
        _db.installedSources,
      )..where((t) => t.id.equals(id))).go();
    });
  }

  @override
  Future<Result<void, AppFailure>> setEnabled(int id, bool enabled) {
    return guardFailure(_logger, _tag, () async {
      await (_db.update(_db.installedSources)..where((t) => t.id.equals(id)))
          .write(InstalledSourcesCompanion(enabled: Value(enabled)));
    });
  }
}
