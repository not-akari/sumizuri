import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_media_wording.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

import 'package:sumizuri/features/extensions/entry_detail/entry_detail_poster_actions.dart'
    show ChapterMenuAction;

extension on ChapterMenuAction {
  String label(AppLocalizations l10n, MediaType type) => switch (this) {
    ChapterMenuAction.downloadAll => l10n.chapterMenuDownloadAll,
    ChapterMenuAction.markAllRead => l10n.markAllRead(type),
    ChapterMenuAction.markAllUnread => l10n.markAllUnread(type),
    ChapterMenuAction.selectAll => l10n.chapterMenuSelectAll,
    ChapterMenuAction.filterScanlators => l10n.chapterMenuFilterScanlators,
    ChapterMenuAction.seriesDownloadSettings =>
      l10n.chapterMenuSeriesDownloadSettings,
  };
}

Widget? chapterOverflowMenu({
  required AppLocalizations l10n,
  required List<MChapter>? chapters,
  bool hasScanlators = false,
  bool inLibrary = false,
  required void Function(ChapterMenuAction action, List<MChapter> chapters)
  onSelected,
}) {
  if (chapters == null || (chapters.isEmpty && !hasScanlators)) return null;
  return Builder(
    builder: (context) {
      final mediaType = EntryMediaType.of(context);
      return AppMenu<ChapterMenuAction>.of(
        iconSize: 20,
        tooltip: l10n.chapterMenuMoreOptions,
        onSelected: (action) => onSelected(action, chapters),
        values: ChapterMenuAction.values,
        label: (a) => a.label(l10n, mediaType),
        visible: (a) => switch (a) {
          ChapterMenuAction.filterScanlators => hasScanlators,
          ChapterMenuAction.seriesDownloadSettings => inLibrary,
          _ => true,
        },
      );
    },
  );
}
