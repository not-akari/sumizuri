import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_media_wording.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_chapter_actions.dart';

extension on _SelectionAction {
  String label(AppLocalizations l10n, MediaType type) => switch (this) {
    _SelectionAction.markPrevious => l10n.markPreviousRead(type),
    _SelectionAction.download => l10n.chapterDownloadSelected,
    _SelectionAction.deleteDownload => l10n.chapterDeleteDownload,
  };

  IconData get icon => switch (this) {
    _SelectionAction.markPrevious => Icons.arrow_upward_rounded,
    _SelectionAction.download => Icons.download_rounded,
    _SelectionAction.deleteDownload => Icons.delete_outline_rounded,
  };
}

enum _SelectionAction { markPrevious, download, deleteDownload }

class ChapterSelectionAppBar extends StatelessWidget
    implements PreferredSizeWidget {
  const ChapterSelectionAppBar({
    super.key,
    required this.selectedCount,
    required this.totalCount,
    required this.onClose,
    required this.onSelectAll,
    required this.onInvertSelection,
    required this.onMarkAsRead,
    required this.onMarkAsUnread,
    this.onMarkPreviousAsRead,
    required this.onDownloadSelected,
    required this.onDeleteDownloaded,
  });

  final int selectedCount;
  final int totalCount;
  final VoidCallback onClose;
  final VoidCallback onSelectAll;
  final VoidCallback onInvertSelection;
  final VoidCallback onMarkAsRead;
  final VoidCallback onMarkAsUnread;
  final VoidCallback? onMarkPreviousAsRead;
  final VoidCallback onDownloadSelected;
  final VoidCallback onDeleteDownloaded;

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return AppBar(
      backgroundColor: cs.surfaceContainerHigh,
      leading: IconButton(
        icon: const Icon(Icons.close),
        tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
        onPressed: onClose,
      ),
      title: Text(
        l10n.chapterSelectedCount(selectedCount),
        style: theme.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.bold,
        ),
      ),
      actions: [
        IconButton(
          icon: Icon(
            selectedCount == totalCount
                ? Icons.deselect_outlined
                : Icons.select_all,
          ),
          tooltip: l10n.chapterSelectAll,
          onPressed: onSelectAll,
        ),
        IconButton(
          icon: const Icon(Icons.flip_to_back_outlined),
          tooltip: l10n.chapterInvertSelection,
          onPressed: onInvertSelection,
        ),
        IconButton(
          icon: const Icon(Icons.done_all),
          tooltip: l10n.chapterMarkAsRead,
          onPressed: onMarkAsRead,
        ),
        IconButton(
          icon: const Icon(Icons.remove_done),
          tooltip: l10n.chapterMarkAsUnread,
          onPressed: onMarkAsUnread,
        ),
        Builder(
          builder: (context) => AppMenu<_SelectionAction>.of(
            onSelected: (action) => switch (action) {
              _SelectionAction.markPrevious => onMarkPreviousAsRead?.call(),
              _SelectionAction.download => onDownloadSelected(),
              _SelectionAction.deleteDownload => onDeleteDownloaded(),
            },
            values: _SelectionAction.values,
            label: (a) => a.label(l10n, EntryMediaType.of(context)),
            visible: (a) =>
                a != _SelectionAction.markPrevious ||
                onMarkPreviousAsRead != null,
            icon: (a) => a.icon,
          ),
        ),
      ],
    );
  }
}

PreferredSizeWidget buildChapterSelectionAppBar({
  required EntryDetailChapterSelection selection,
  required List<MChapter>? chapters,
  required EntryDetailChapterActions actions,
  required VoidCallback onStateChanged,
}) {
  final allChapters = chapters ?? const [];
  return ChapterSelectionAppBar(
    selectedCount: selection.length,
    totalCount: allChapters.length,
    onClose: () {
      selection.clear();
      onStateChanged();
    },
    onSelectAll: () {
      selection.selectAll(allChapters);
      onStateChanged();
    },
    onInvertSelection: () {
      selection.invert(allChapters);
      onStateChanged();
    },
    onMarkAsRead: () async {
      onStateChanged();
      await actions.bulkMarkConsumed(selection: selection, consumed: true);
      onStateChanged();
    },
    onMarkAsUnread: () async {
      onStateChanged();
      await actions.bulkMarkConsumed(selection: selection, consumed: false);
      onStateChanged();
    },
    onMarkPreviousAsRead: () async {
      onStateChanged();
      await actions.markPreviousAsRead(
        selection: selection,
        allChapters: allChapters,
      );
      onStateChanged();
    },
    onDownloadSelected: () async {
      onStateChanged();
      await actions.bulkDownload(
        selection: selection,
        allChapters: allChapters,
      );
      onStateChanged();
    },
    onDeleteDownloaded: () async {
      onStateChanged();
      await actions.bulkDeleteDownloads(
        selection: selection,
        allChapters: allChapters,
      );
      onStateChanged();
    },
  );
}
