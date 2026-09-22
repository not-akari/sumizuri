import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;

import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/extensions/models/m_page.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

Future<Result<List<MPage>, AppFailure>> loadLocalPages(String dirPath) async {
  try {
    final files = await Directory(dirPath)
        .list()
        .where((e) => e is File)
        .cast<File>()
        .toList();
    files.sort((a, b) => a.path.compareTo(b.path));
    final pages = <MPage>[];
    for (var i = 0; i < files.length; i++) {
      final file = files[i];
      if (p.extension(file.path) == '.txt') {
        pages.add(MPage(index: i, text: await file.readAsString()));
      } else {
        pages.add(
          MPage(index: i, imageUrl: p.normalize(file.path), isLocalFile: true),
        );
      }
    }
    return Ok(pages);
  } catch (error) {
    return Err(ExtensionFailure('Failed to load downloaded pages: $error'));
  }
}

Future<int> resumePageIndex(
  Ref ref,
  int? libraryEntryId,
  String chapterUrl,
  int totalPages,
) async {
  if (libraryEntryId == null || totalPages == 0) return 0;
  final result = await ref
      .read(libraryRepositoryProvider)
      .getChapterProgress(
        libraryEntryId: libraryEntryId,
        chapterUrl: chapterUrl,
      );
  final progress = result.valueOrNull;
  if (progress == null) return 0;
  final resumeIndex = (progress * totalPages).round() - 1;
  return resumeIndex.clamp(0, totalPages - 1);
}
