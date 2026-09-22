import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:drift/drift.dart';
import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/database/app_database.dart';

enum SyncFileKind { theme, font, cover, draft }

/// The server refuses files larger than this, so they are skipped up front.
const syncMaxFileBytes = 12 * 1024 * 1024;

typedef WireRow = Map<String, dynamic>;

class SyncFileEntry {
  const SyncFileEntry({
    required this.kind,
    required this.name,
    required this.sizeBytes,
    required this.modifiedAt,
    required this.file,
  });

  final SyncFileKind kind;
  final String name;
  final int sizeBytes;
  final int modifiedAt;
  final File file;
}

class SyncFileUpload {
  SyncFileUpload({
    required this.rows,
    required this.deletedIds,
    required this.sent,
    required this.gone,
  });

  final List<WireRow> rows;
  final List<int> deletedIds;

  final List<SyncFilesCompanion> sent;
  final List<SyncFileKind> gone;
}

class SyncFileStore {
  SyncFileStore(this._db, {required this.directoryFor});

  final AppDatabase _db;
  final Future<Directory> Function(SyncFileKind kind) directoryFor;

  /// The same file gets the same id on every device, so devices never need to agree.
  static int clientIdOf(SyncFileKind kind, String name) {
    final digest = sha256.convert(utf8.encode('${kind.name}/$name')).bytes;
    var value = 0;
    for (var i = 0; i < 7; i++) {
      value = (value << 8) | digest[i];
    }
    return (value & 0xFFFFFFFFFFFFF) + 1;
  }

  static bool _wanted(SyncFileKind kind, String name) {
    final lower = name.toLowerCase();
    return switch (kind) {
      SyncFileKind.theme => lower.endsWith('.sumizuri-theme.json'),
      SyncFileKind.font =>
        lower.endsWith('.ttf') ||
            lower.endsWith('.otf') ||
            lower.endsWith('.ttc') ||
            lower.endsWith('.woff') ||
            lower.endsWith('.woff2'),
      SyncFileKind.cover =>
        lower.endsWith('.png') ||
            lower.endsWith('.jpg') ||
            lower.endsWith('.jpeg') ||
            lower.endsWith('.webp') ||
            lower.endsWith('.gif'),
      SyncFileKind.draft =>
        lower.startsWith('draft_') && lower.endsWith('.arb'),
    };
  }

  Future<List<SyncFileEntry>> scan() async {
    final found = <SyncFileEntry>[];
    for (final kind in SyncFileKind.values) {
      final dir = await directoryFor(kind);
      if (!await dir.exists()) continue;
      await for (final entity in dir.list(followLinks: false)) {
        if (entity is! File) continue;
        final name = p.basename(entity.path);
        if (!_wanted(kind, name)) continue;
        final stat = await entity.stat();
        found.add(
          SyncFileEntry(
            kind: kind,
            name: name,
            sizeBytes: stat.size,
            modifiedAt: stat.modified.millisecondsSinceEpoch,
            file: entity,
          ),
        );
      }
    }
    return found;
  }

  Future<SyncFileUpload> collect({
    required int profileId,
    bool everything = false,
    int? forceUpdatedAt,
  }) async {
    final onDisk = await scan();
    final manifest = {
      for (final row in await (_db.select(
        _db.syncFiles,
      )..where((t) => t.profileId.equals(profileId))).get())
        (row.kind, row.name): row,
    };

    final rows = <WireRow>[];
    final sent = <SyncFilesCompanion>[];
    for (final entry in onDisk) {
      if (entry.sizeBytes > syncMaxFileBytes) continue;
      final known = manifest[(entry.kind.name, entry.name)];
      final unchanged =
          known != null &&
          known.modifiedAt == entry.modifiedAt &&
          known.sizeBytes == entry.sizeBytes;
      if (unchanged && !everything) continue;

      final bytes = await entry.file.readAsBytes();
      final hash = sha256.convert(bytes).toString();
      final sameContent = known != null && known.sha256 == hash;
      sent.add(
        SyncFilesCompanion.insert(
          profileId: profileId,
          kind: entry.kind.name,
          name: entry.name,
          sha256: hash,
          sizeBytes: bytes.length,
          modifiedAt: entry.modifiedAt,
        ),
      );
      if (sameContent && !everything) continue;
      rows.add({
        'clientId': clientIdOf(entry.kind, entry.name),
        'updatedAt': forceUpdatedAt ?? entry.modifiedAt,
        'kind': entry.kind.name,
        'name': entry.name,
        'sha256': hash,
        'size': bytes.length,
        'data': base64Encode(bytes),
      });
    }

    final present = {for (final e in onDisk) (e.kind.name, e.name)};
    final gone = <SyncFileKind>[];
    final deletedIds = <int>[];
    if (!everything) {
      for (final row in manifest.values) {
        if (present.contains((row.kind, row.name))) continue;
        final kind = SyncFileKind.values.byName(row.kind);
        gone.add(kind);
        deletedIds.add(clientIdOf(kind, row.name));
      }
    }
    return SyncFileUpload(
      rows: rows,
      deletedIds: deletedIds,
      sent: sent,
      gone: gone,
    );
  }

  Future<void> commit(int profileId, SyncFileUpload upload) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.syncFiles, upload.sent);
    });
    if (upload.deletedIds.isEmpty) return;
    final names = await (_db.select(
      _db.syncFiles,
    )..where((t) => t.profileId.equals(profileId))).get();
    for (final row in names) {
      final kind = SyncFileKind.values.byName(row.kind);
      if (upload.deletedIds.contains(clientIdOf(kind, row.name)) &&
          !(await _existsOnDisk(kind, row.name))) {
        await (_db.delete(_db.syncFiles)..where(
              (t) =>
                  t.profileId.equals(profileId) &
                  t.kind.equals(row.kind) &
                  t.name.equals(row.name),
            ))
            .go();
      }
    }
  }

  Future<bool> _existsOnDisk(SyncFileKind kind, String name) async =>
      File(p.join((await directoryFor(kind)).path, name)).exists();

  Future<void> apply(
    int profileId,
    List<WireRow> rows,
    List<int> deletedIds,
  ) async {
    for (final row in rows) {
      final kind = SyncFileKind.values.asNameMap()[row['kind']];
      final name = row['name'] as String;
      // A name from the network is never trusted as a path.
      if (kind == null || name != p.basename(name) || !_wanted(kind, name)) {
        continue;
      }
      final incoming = row['updatedAt'] as int;
      final target = File(p.join((await directoryFor(kind)).path, name));
      if (await target.exists()) {
        final local = (await target.stat()).modified.millisecondsSinceEpoch;
        if (local >= incoming) continue;
      }
      final bytes = base64Decode(row['data'] as String);
      final hash = sha256.convert(bytes).toString();
      if (hash != row['sha256']) continue;

      await target.parent.create(recursive: true);
      await target.writeAsBytes(bytes, flush: true);
      await target.setLastModified(
        DateTime.fromMillisecondsSinceEpoch(incoming),
      );
      final stat = await target.stat();
      await _db
          .into(_db.syncFiles)
          .insertOnConflictUpdate(
            SyncFilesCompanion.insert(
              profileId: profileId,
              kind: kind.name,
              name: name,
              sha256: hash,
              sizeBytes: bytes.length,
              modifiedAt: stat.modified.millisecondsSinceEpoch,
            ),
          );
    }

    if (deletedIds.isEmpty) return;
    for (final entry in await scan()) {
      if (!deletedIds.contains(clientIdOf(entry.kind, entry.name))) continue;
      await entry.file.delete();
      await (_db.delete(_db.syncFiles)..where(
            (t) =>
                t.profileId.equals(profileId) &
                t.kind.equals(entry.kind.name) &
                t.name.equals(entry.name),
          ))
          .go();
    }
  }
}
