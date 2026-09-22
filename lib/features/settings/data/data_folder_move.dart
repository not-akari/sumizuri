import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';

const _databaseName = 'sumizuri.sqlite';

const _topLevelSkipped = {
  _databaseName,
  '$_databaseName-wal',
  '$_databaseName-shm',
  '$_databaseName-journal',
  'data_location.txt',
  'before_upgrade.tmp',
  'app_in_foreground',
};

// Columns that hold a full file path, which is why a move must rewrite them.
const _pathColumns = [
  ('content_units', 'local_path'),
  ('library_entries', 'custom_cover_path'),
  ('profiles', 'avatar_path'),
];

enum DataMoveProblem { nested }

class DataFolderMoveException implements Exception {
  const DataFolderMoveException(this.problem);

  final DataMoveProblem problem;
}

Future<bool> folderHasData(String path) =>
    File(p.join(path, _databaseName)).exists();

/// Points the app at a folder that already has data in it, without copying anything.
Future<void> useExistingDataFolder(String path) => _remember(path);

Future<void> moveDataFolder(
  String to, {
  void Function(double progress)? onProgress,
}) async {
  final from = (await appDataDirectory()).path;
  if (p.equals(from, to)) return;
  if (p.isWithin(from, to) || p.isWithin(to, from)) {
    throw const DataFolderMoveException(DataMoveProblem.nested);
  }

  await Directory(to).create(recursive: true);
  final newDatabase = File(p.join(to, _databaseName));
  try {
    final source = sqlite3.sqlite3.open(p.join(from, _databaseName));
    try {
      source.execute('VACUUM INTO ?', [newDatabase.path]);
    } finally {
      source.close();
    }
    _rewritePaths(newDatabase.path, '$from${p.separator}', '$to${p.separator}');

    final files = <(File, String)>[];
    await for (final entity in Directory(
      from,
    ).list(recursive: true, followLinks: false)) {
      if (entity is! File) continue;
      final relative = p.relative(entity.path, from: from);
      if (p.split(relative).length == 1 &&
          _topLevelSkipped.contains(relative)) {
        continue;
      }
      files.add((entity, relative));
    }
    for (var i = 0; i < files.length; i++) {
      final (file, relative) = files[i];
      final destination = File(p.join(to, relative));
      await destination.parent.create(recursive: true);
      await file.copy(destination.path);
      onProgress?.call((i + 1) / files.length);
    }
  } catch (_) {
    // A half-made database must not be mistaken for real data later.
    try {
      await deleteIfExists(newDatabase);
    } catch (_) {}
    rethrow;
  }
  await _remember(to);
}

Future<void> _remember(String path) async {
  final isDefault = p.equals(path, (await defaultDataDirectory()).path);
  await setCustomDataPath(isDefault ? null : path);
}

// Stored file paths start with the old folder. They must start with the new one.
void _rewritePaths(String databasePath, String oldPrefix, String newPrefix) {
  final db = sqlite3.sqlite3.open(databasePath);
  try {
    db.execute('UPDATE sync_state SET applying = 1 WHERE id = 0');
    for (final (table, column) in _pathColumns) {
      db.execute(
        'UPDATE $table SET $column = ? || substr($column, length(?) + 1) '
        'WHERE $column IS NOT NULL AND substr($column, 1, length(?)) = ?',
        [newPrefix, oldPrefix, oldPrefix, oldPrefix],
      );
    }
  } finally {
    try {
      db.execute('UPDATE sync_state SET applying = 0 WHERE id = 0');
    } finally {
      db.close();
    }
  }
}
