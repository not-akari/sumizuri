// Writes a chapter's pages into a folder so an interrupted download can resume.
import 'dart:io';

import 'package:path/path.dart' as p;

import 'package:sumizuri/core/utils/downloads/download_stopped.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';

const _manifestName = '.pages';
const _partSuffix = '.part';

String pageFileName(int index, String? imageUrl) {
  final base = index.toString().padLeft(4, '0');
  if (imageUrl == null) return '$base.txt';
  final ext = p.extension(Uri.parse(imageUrl).path);
  return '$base${ext.isEmpty ? '.jpg' : ext}';
}

Future<Set<int>> savedPages(Directory dir) async {
  if (!await dir.exists()) return {};
  final saved = <int>{};
  await for (final entity in dir.list()) {
    if (entity is! File) continue;
    final name = p.basename(entity.path);
    if (name.startsWith('.') || name.endsWith(_partSuffix)) continue;
    final index = int.tryParse(p.basenameWithoutExtension(name));
    if (index != null && await entity.length() > 0) saved.add(index);
  }
  return saved;
}

Future<void> writeChapterPages({
  required Directory dir,
  required List<MPage> pages,
  required Future<List<int>> Function(String url) fetch,
  int attempts = 3,
  Duration retryDelay = const Duration(milliseconds: 400),
  bool Function()? shouldStop,
}) async {
  await dir.create(recursive: true);
  final manifest = File(p.join(dir.path, _manifestName));
  final expected = '${pages.length}';
  if (await manifest.exists() && await manifest.readAsString() != expected) {
    await for (final entity in dir.list()) {
      await entity.delete(recursive: true);
    }
  }
  await manifest.writeAsString(expected);

  await for (final entity in dir.list()) {
    if (entity is File && entity.path.endsWith(_partSuffix)) {
      await entity.delete();
    }
  }

  final done = await savedPages(dir);
  for (final page in pages) {
    if (shouldStop?.call() ?? false) throw const DownloadStopped();
    if (done.contains(page.index)) continue;
    final text = page.text;
    final imageUrl = page.imageUrl;
    if (text == null && imageUrl == null) continue;
    final target = File(p.join(dir.path, pageFileName(page.index, imageUrl)));
    final part = File('${target.path}$_partSuffix');
    if (text != null) {
      await part.writeAsString(text);
    } else {
      await part.writeAsBytes(
        await _fetchWithRetry(
          fetch,
          imageUrl!,
          attempts,
          retryDelay,
          shouldStop,
        ),
      );
    }
    await part.rename(target.path);
  }
  await manifest.delete();
}

Future<List<int>> _fetchWithRetry(
  Future<List<int>> Function(String url) fetch,
  String url,
  int attempts,
  Duration delay,
  bool Function()? shouldStop,
) async {
  for (var attempt = 1; ; attempt++) {
    try {
      return await fetch(url);
    } on Object {
      // A stopped download is not tried again.
      if (shouldStop?.call() ?? false) throw const DownloadStopped();
      if (attempt >= attempts) rethrow;
      await Future<void>.delayed(delay * attempt);
    }
  }
}
