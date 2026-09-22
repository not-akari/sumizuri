// Drift backed repository for app log entries, capped to a maximum count.
import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/features/settings/data/setting_rows.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/settings/models/log_entry.dart';
import 'package:sumizuri/features/settings/data/log_repository.dart';
import 'package:sumizuri/core/errors/failure_mapper.dart';

class DriftLogRepository implements LogRepository {
  DriftLogRepository(this._db);

  final AppDatabase _db;

  static const _maxEntries = 2000;

  @override
  Future<Set<String>> disabledCategories() async {
    final raw = await _db.readSettingRow(Settings.disabledLogCategories);
    return {
      for (final c in raw.split(','))
        if (c.isNotEmpty) c,
    };
  }

  @override
  Future<void> setDisabledCategories(Set<String> categories) async {
    await _db.writeSettingRow(
      Settings.disabledLogCategories,
      categories.join(','),
    );
  }

  @override
  Future<Result<void, AppFailure>> add(AppLogEntry entry) async {
    try {
      await _db
          .into(_db.logEntries)
          .insert(
            LogEntriesCompanion.insert(
              timestamp: Value(entry.timestamp),
              level: entry.level,
              tag: entry.tag,
              message: entry.message,
              stackTrace: Value(entry.stackTrace),
            ),
          );
      await _prune();
      return const Ok(null);
    } catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }

  Future<void> _prune() async {
    final keepIds =
        await (_db.select(_db.logEntries)
              ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
              ..limit(_maxEntries))
            .map((row) => row.id)
            .get();
    if (keepIds.isEmpty) return;
    await (_db.delete(
      _db.logEntries,
    )..where((t) => t.id.isNotIn(keepIds))).go();
  }

  @override
  Stream<List<AppLogEntry>> watchRecent({int limit = 200}) {
    final query = _db.select(_db.logEntries)
      ..orderBy([(t) => OrderingTerm.desc(t.timestamp)])
      ..limit(limit);
    return query.watch().map(
      (rows) => rows
          .map(
            (row) => AppLogEntry(
              timestamp: row.timestamp,
              level: row.level,
              tag: row.tag,
              message: row.message,
              stackTrace: row.stackTrace,
            ),
          )
          .toList(),
    );
  }

  @override
  Future<Result<void, AppFailure>> clear() async {
    try {
      await _db.delete(_db.logEntries).go();
      return const Ok(null);
    } catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }

  @override
  Future<Result<String, AppFailure>> exportAsText() async {
    try {
      final rows = await (_db.select(
        _db.logEntries,
      )..orderBy([(t) => OrderingTerm.asc(t.timestamp)])).get();
      final buffer = StringBuffer();
      for (final row in rows) {
        buffer
          ..write(row.timestamp.toIso8601String())
          ..write(' [')
          ..write(row.level.name)
          ..write('] ')
          ..write(row.tag)
          ..write(': ')
          ..writeln(row.message);
        if (row.stackTrace != null) buffer.writeln(row.stackTrace);
      }
      return Ok(buffer.toString());
    } catch (error) {
      return Err(mapExceptionToFailure(error));
    }
  }
}
