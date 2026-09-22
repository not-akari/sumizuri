import 'dart:async';

import 'package:flutter/material.dart';

import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/player/pages/player_screen.dart';
import 'package:sumizuri/features/reader/models/chapter_lock_checker.dart';
import 'package:sumizuri/features/reader/pages/reader_screen.dart';
import 'package:sumizuri/features/reader/widgets/chapter_locked_dialog.dart';
import 'package:sumizuri/features/extensions/cloudflare/cloudflare_solver_page.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_comments_sheet.dart';

Future<void> openEntryChapter({
  required BuildContext context,
  required ExtensionService service,
  required MChapter chapter,
  required List<MChapter> chapters,
  required int? libraryEntryId,
  required bool hasChapterComments,
  required void Function(MChapter) onChapterComments,
  required VoidCallback onReturn,
}) async {
  if (isChapterLocked(chapter)) {
    await showChapterLockedDialog(context, chapter);
    return;
  }
  if (service.info.mediaType == MediaType.anime) {
    await PlayerScreen.push(
      context,
      service: service,
      chapter: chapter,
      chapters: chapters,
      libraryEntryId: libraryEntryId,
    );
  } else {
    await ReaderScreen.push(
      context,
      service: service,
      chapter: chapter,
      chapters: chapters,
      libraryEntryId: libraryEntryId,
      hasChapterComments: hasChapterComments,
      onChapterComments: onChapterComments,
    );
  }
  onReturn();
}

void openEntryCommentsModal({
  required BuildContext context,
  required ExtensionService service,
  required MEntry entry,
}) {
  showCommentsSheet(
    context,
    title: entry.title,
    fetch: (sort) => service.getComments(entry, sort: sort),
  );
}

void openChapterCommentsModal({
  required BuildContext context,
  required ExtensionService service,
  required MChapter chapter,
}) {
  showCommentsSheet(
    context,
    title: chapter.title,
    fetch: (sort) => service.getChapterComments(chapter, sort: sort),
  );
}

Future<void> openEntryWebview({
  required BuildContext context,
  required String url,
  required String sourceId,
  required Future<void> Function() onSolved,
}) async {
  final solved = await CloudflareSolverPage.push(
    context,
    url: url,
    sourceId: sourceId,
  );
  if (solved == true) await onSolved();
}
