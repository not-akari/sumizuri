import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/features/extensions/models/source_key.dart';

/// Points every entry that lost its source at sourceRowId, when its remembered key is key.
Future<int> relinkEntriesToSource(
  AppDatabase db, {
  required int sourceRowId,
  required String key,
}) {
  return db.customUpdate(
    'UPDATE OR IGNORE library_entries SET source_id = ?, source_key = NULL '
    'WHERE source_key = ? '
    'AND source_id NOT IN (SELECT CAST(id AS TEXT) FROM installed_sources)',
    variables: [Variable.withString('$sourceRowId'), Variable.withString(key)],
    updates: {db.libraryEntries},
    updateKind: UpdateKind.update,
  );
}

Future<void> rememberSourceOnEntries(AppDatabase db, InstalledSource row) {
  return db.customUpdate(
    'UPDATE library_entries SET source_key = ? WHERE source_id = ?',
    variables: [
      Variable.withString(installedSourceKey(row)),
      Variable.withString('${row.id}'),
    ],
    updates: {db.libraryEntries},
    updateKind: UpdateKind.update,
  );
}

String installedSourceKey(InstalledSource row) => sourceKeyOf(
  repoUrl: row.repoUrl,
  repoSourceId: row.repoSourceId,
  name: row.name,
  baseUrl: row.baseUrl,
);
