// Marks a source as needing fetches proxied through a browser page.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';

const _flagFileName = 'use_browser_fetch';

/// Sets browser fetch flag file within [cookieDirPath].
Future<void> markSourceUsesBrowserFetch(String cookieDirPath) async {
  await Directory(cookieDirPath).create(recursive: true);
  await File(p.join(cookieDirPath, _flagFileName)).writeAsString('');
}

Future<bool> sourceUsesBrowserFetch(String cookieDirPath) =>
    File(p.join(cookieDirPath, _flagFileName)).exists();

/// Clears browser fetch flag file within [cookieDirPath].
Future<void> clearSourceUsesBrowserFetch(String cookieDirPath) =>
    deleteIfExists(File(p.join(cookieDirPath, _flagFileName)));
