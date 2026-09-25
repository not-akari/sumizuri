// Marks a source as needing fetches proxied through a browser page.
import 'dart:io';

import 'package:path/path.dart' as p;

const _flagFileName = 'use_browser_fetch';

/// Sets browser fetch flag file within [cookieDirPath].
Future<void> markSourceUsesBrowserFetch(String cookieDirPath) async {
  await Directory(cookieDirPath).create(recursive: true);
  await File(p.join(cookieDirPath, _flagFileName)).writeAsString('');
}

Future<bool> sourceUsesBrowserFetch(String cookieDirPath) =>
    File(p.join(cookieDirPath, _flagFileName)).exists();
