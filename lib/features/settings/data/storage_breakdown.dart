import 'dart:io';

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/features/library/models/downloaded_entry.dart';

class StorageBreakdown {
  const StorageBreakdown({
    required this.database,
    required this.autoBackups,
    required this.safetyCopies,
    required this.themesAndFonts,
    required this.customCovers,
    this.downloads = 0,
    this.unfinishedDownloads = 0,
    this.sourceSessions = 0,
  });

  final int sourceSessions;

  final int downloads;

  final int unfinishedDownloads;

  final int database;
  final int autoBackups;
  final int safetyCopies;
  final int themesAndFonts;
  final int customCovers;

  int get total =>
      database +
      autoBackups +
      safetyCopies +
      themesAndFonts +
      customCovers +
      sourceSessions +
      downloads;
}

Future<int> directoryBytes(Directory dir) async {
  if (!await dir.exists()) return 0;
  var total = 0;
  await for (final entity in dir.list(recursive: true)) {
    if (entity is File) {
      try {
        total += await entity.length();
      } catch (_) {}
    }
  }
  return total;
}

/// How much disk each downloaded entry uses, and all of them together.
Future<({Map<int, int> byEntry, int total})> measureDownloadedEntries(
  List<DownloadedEntry> entries,
) async {
  final byEntry = <int, int>{};
  var total = 0;
  for (final entry in entries) {
    var bytes = 0;
    for (final chapter in entry.chapters) {
      bytes += await directoryBytes(Directory(chapter.localPath));
    }
    byEntry[entry.entryId] = bytes;
    total += bytes;
  }
  return (byEntry: byEntry, total: total);
}

Future<int> _fileBytes(File file) async {
  try {
    return await file.exists() ? await file.length() : 0;
  } catch (_) {
    return 0;
  }
}

Future<List<Directory>> unfinishedDownloadFolders(Directory downloads) async {
  if (!await downloads.exists()) return [];
  final found = <Directory>[];
  await for (final entity in downloads.list(recursive: true)) {
    if (entity is File &&
        entity.path.split(RegExp(r'[\\/]')).last == '.pages') {
      found.add(entity.parent);
    }
  }
  return found;
}

Future<int> clearUnfinishedDownloads(
  Directory downloads, {
  Set<String> keep = const {},
}) async {
  var freed = 0;
  for (final folder in await unfinishedDownloadFolders(downloads)) {
    if (keep.contains(folder.path)) continue;
    freed += await directoryBytes(folder);
    await folder.delete(recursive: true);
  }
  return freed;
}

Future<StorageBreakdown> measureStorage({String? downloadsPath}) async {
  final db = await databaseFile();
  final database =
      await _fileBytes(db) +
      await _fileBytes(File('${db.path}-wal')) +
      await _fileBytes(File('${db.path}-shm'));
  final downloadsDir = await downloadsDirectory(overridePath: downloadsPath);
  var unfinished = 0;
  for (final folder in await unfinishedDownloadFolders(downloadsDir)) {
    unfinished += await directoryBytes(folder);
  }
  return StorageBreakdown(
    downloads: await directoryBytes(downloadsDir),
    unfinishedDownloads: unfinished,
    database: database,
    autoBackups: await directoryBytes(await autoBackupsDirectory()),
    safetyCopies: await directoryBytes(await dbBackupsDirectory()),
    themesAndFonts:
        await directoryBytes(await themesDirectory()) +
        await directoryBytes(await fontsDirectory()),
    customCovers: await directoryBytes(await customCoversDirectory()),
    sourceSessions: await directoryBytes(await cookiesRootDirectory()),
  );
}
