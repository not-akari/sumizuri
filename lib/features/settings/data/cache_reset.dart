import 'dart:io';

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/features/extensions/render/render_broker.dart';
import 'package:sumizuri/features/settings/data/storage_breakdown.dart';

Future<int> clearDirectoryContents(Directory dir) async {
  if (!await dir.exists()) return 0;
  var freed = 0;
  await for (final entity in dir.list()) {
    try {
      if (entity is File) {
        final size = await entity.length();
        await entity.delete();
        freed += size;
      } else if (entity is Directory) {
        final size = await directoryBytes(entity);
        await entity.delete(recursive: true);
        freed += size;
      }
    } on FileSystemException {
      // A file in use stays, and is not counted as freed.
    }
  }
  return freed;
}

Future<int> clearSourceSessions() async =>
    clearDirectoryContents(await cookiesRootDirectory());

Future<bool> clearHiddenBrowserData() =>
    RenderBroker.instance.clearBrowserData();

class ResetResult {
  const ResetResult({required this.freedBytes, required this.browserCleared});

  final int freedBytes;
  final bool browserCleared;
}

Future<ResetResult> resetSourceSessions() async {
  final freed = await clearSourceSessions();
  final browser = await clearHiddenBrowserData();
  return ResetResult(freedBytes: freed, browserCleared: browser);
}
