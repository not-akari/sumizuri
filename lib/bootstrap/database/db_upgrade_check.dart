import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:sqlite3/sqlite3.dart' as sqlite3;

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/bootstrap/database/app_database.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/features/settings/data/db_file_backup.dart';

Future<Object?> upgradeDatabaseNow() async {
  final dbFile = await databaseFile();
  final before = File(
    p.join((await appDataDirectory()).path, 'before_upgrade.tmp'),
  );
  try {
    await deleteIfExists(before);
    final raw = sqlite3.sqlite3.open(dbFile.path);
    try {
      raw.execute('VACUUM INTO ?', [before.path]);
    } finally {
      raw.close();
    }
  } catch (error) {
    return error;
  }

  final db = AppDatabase();
  Object? failure;
  try {
    await db.customSelect('SELECT 1').get();
  } catch (error) {
    failure = error;
  }
  try {
    await db.close();
  } catch (_) {
    // Closing a database that never opened is not worth reporting.
  }

  if (failure != null) {
    await deleteDatabaseFiles();
    await before.copy(dbFile.path);
  }
  await before.delete();
  return failure;
}
