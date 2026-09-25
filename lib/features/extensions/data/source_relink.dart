import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/features/extensions/models/source_key.dart';
import 'package:sumizuri/features/repos/data/repo_url.dart';

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

/// Installed sources that came from the same repo source more than once,
/// grouped, so each group is one source installed several times.
List<List<InstalledSource>> duplicateSourceGroups(List<InstalledSource> rows) {
  final byKey = <String, List<InstalledSource>>{};
  for (final row in rows) {
    final repoUrl = row.repoUrl;
    final repoSourceId = row.repoSourceId;
    if (repoUrl == null || repoSourceId == null) continue;
    (byKey['${normalizeRepoUrl(repoUrl)}\n$repoSourceId'] ??= []).add(row);
  }
  return [
    for (final group in byKey.values)
      if (group.length > 1) group,
  ];
}
