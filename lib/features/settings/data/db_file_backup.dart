// Creates and restores raw sqlite file backups, keeping only the most recent copies.
import 'dart:io';

import 'package:file_selector/file_selector.dart';
import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/core/utils/formatting/timestamps.dart';
import 'package:sumizuri/bootstrap/database/app_database.dart'
    show appDatabaseSchemaVersion, oldestUpgradableSchemaVersion;
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/core/utils/files/file_export_helper.dart';

const _keepBackups = 5;

const _sidecarSuffixes = ['-wal', '-shm', '-journal'];

Future<int?> onDiskSchemaVersion() async {
  final dbFile = await databaseFile();
  if (!await dbFile.exists()) return null;
  // Only read, so this never takes a write lock the app needs while it opens the same file.
  final db = sqlite3.sqlite3.open(dbFile.path, mode: sqlite3.OpenMode.readOnly);
  try {
    return db.select('PRAGMA user_version').first.values.first as int;
  } finally {
    db.close();
  }
}

Future<int?> pendingMigrationFromVersion() async {
  final current = await onDiskSchemaVersion();
  // Version 0 means uninitialized database, treated same as null.
  if (current == null || current == 0 || current >= appDatabaseSchemaVersion) {
    return null;
  }
  return current;
}

Future<int?> unsupportedDatabaseVersion() async {
  final current = await onDiskSchemaVersion();
  if (current == null || current == 0) return null;
  return current < oldestUpgradableSchemaVersion ? current : null;
}

/// Saves one self-contained copy of the database where the user chooses.
Future<String?> exportDatabaseCopy() async {
  final dbFile = await databaseFile();
  final version = await onDiskSchemaVersion();
  final scratch = await Directory.systemTemp.createTemp('sumizuri_export_');
  try {
    final copy = File(p.join(scratch.path, 'copy.sqlite'));
    final db = sqlite3.sqlite3.open(dbFile.path);
    try {
      db.execute('VACUUM INTO ?', [copy.path]);
    } finally {
      db.close();
    }
    final stamp = fileStamp();
    return await saveExportedBytes(
      suggestedName: 'sumizuri_old_data_v${version}_$stamp.sqlite',
      bytes: await copy.readAsBytes(),
      acceptedTypeGroups: const [
        XTypeGroup(label: 'SQLite database', extensions: ['sqlite']),
      ],
    );
  } finally {
    await scratch.delete(recursive: true);
  }
}

/// Deletes the database so the next launch starts a new one.
Future<void> deleteDatabaseFiles() async {
  final dbFile = await databaseFile();
  for (final path in [
    dbFile.path,
    for (final suffix in _sidecarSuffixes) '${dbFile.path}$suffix',
  ]) {
    final file = File(path);
    await deleteIfExists(file);
  }
}

Future<File> backUpDatabaseNow() async {
  final dbFile = await databaseFile();
  final backupsDir = await dbBackupsDirectory();
  final timestamp = fileStamp();
  final backupFile = File(
    p.join(backupsDir.path, 'sumizuri_$timestamp.sqlite'),
  );
  await dbFile.copy(backupFile.path);
  for (final suffix in _sidecarSuffixes) {
    final sidecar = File('${dbFile.path}$suffix');
    if (await sidecar.exists()) await sidecar.copy('${backupFile.path}$suffix');
  }
  await _pruneOldBackups(backupsDir);
  return backupFile;
}

Future<void> _pruneOldBackups(Directory backupsDir) async {
  final files = await backupsDir
      .list()
      .where((entry) => entry is File && entry.path.endsWith('.sqlite'))
      .cast<File>()
      .toList();
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  for (final file in files.skip(_keepBackups)) {
    await file.delete();
    for (final suffix in _sidecarSuffixes) {
      final sidecar = File('${file.path}$suffix');
      await deleteIfExists(sidecar);
    }
  }
}

Future<List<File>> listBackups() async {
  final backupsDir = await dbBackupsDirectory();
  final files = await backupsDir
      .list()
      .where((entry) => entry is File && entry.path.endsWith('.sqlite'))
      .cast<File>()
      .toList();
  files.sort((a, b) => b.statSync().modified.compareTo(a.statSync().modified));
  return files;
}

Future<void> restoreBackup(File backupFile) async {
  final dbFile = await databaseFile();
  for (final suffix in _sidecarSuffixes) {
    final sidecar = File('${dbFile.path}$suffix');
    await deleteIfExists(sidecar);
  }
  await backupFile.copy(dbFile.path);
}
