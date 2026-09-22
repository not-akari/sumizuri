import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/flows/chapter_download_flow.dart';
import 'package:sumizuri/features/settings/pages/download_queue_page.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';

class EntryDetailChapterSelection {
  final Set<String> _selectedUrls = {};

  Set<String> get selectedUrls => _selectedUrls;
  bool get isEmpty => _selectedUrls.isEmpty;
  bool get isNotEmpty => _selectedUrls.isNotEmpty;
  int get length => _selectedUrls.length;

  bool contains(String url) => _selectedUrls.contains(url);

  void toggle(String url) {
    if (!_selectedUrls.remove(url)) {
      _selectedUrls.add(url);
    }
  }

  void selectAll(List<MChapter> chapters) {
    if (_selectedUrls.length == chapters.length) {
      _selectedUrls.clear();
    } else {
      _selectedUrls.addAll(chapters.map((c) => c.url));
    }
  }

  void invert(List<MChapter> chapters) {
    final inverted = chapters
        .map((c) => c.url)
        .where((u) => !_selectedUrls.contains(u))
        .toSet();
    _selectedUrls
      ..clear()
      ..addAll(inverted);
  }

  void clear() => _selectedUrls.clear();
}

class EntryDetailChapterActions {
  const EntryDetailChapterActions({
    required this.ref,
    required this.context,
    required this.entry,
    required this.source,
    required this.service,
    required this.getLibraryEntryId,
    required this.ensureLibraryEntry,
    required this.onReloadChapters,
  });

  final WidgetRef ref;
  final BuildContext context;
  final MEntry entry;
  final AppInstalledSource? source;
  final ExtensionService? service;
  final int? Function() getLibraryEntryId;
  final Future<int?> Function() ensureLibraryEntry;
  final VoidCallback onReloadChapters;

  Future<void> markChaptersConsumed({
    required List<String> chapterUrls,
    required bool consumed,
  }) async {
    final entryId = await ensureLibraryEntry();
    if (entryId == null || chapterUrls.isEmpty) return;
    await ref
        .read(libraryRepositoryProvider)
        .markChaptersConsumed(
          libraryEntryId: entryId,
          chapterUrls: chapterUrls,
          consumed: consumed,
        );
    onReloadChapters();
  }

  Future<void> toggleChapterBookmark(MChapter chapter) async {
    final entryId = await ensureLibraryEntry();
    if (entryId == null) return;
    await ref
        .read(libraryRepositoryProvider)
        .setChaptersBookmarked(
          libraryEntryId: entryId,
          chapterUrls: [chapter.url],
          bookmarked: !chapter.bookmarked,
        );
    onReloadChapters();
  }

  Future<void> toggleChapterRead(MChapter chapter) async {
    await markChaptersConsumed(
      chapterUrls: [chapter.url],
      consumed: !chapter.read,
    );
  }

  Future<void> markPreviousChaptersRead({
    required MChapter anchor,
    required List<MChapter> allChapters,
  }) async {
    final urls = <String>[];
    if (anchor.number != null) {
      urls.addAll(
        allChapters
            .where((c) => c.number != null && c.number! <= anchor.number!)
            .map((c) => c.url),
      );
    } else {
      final idx = allChapters.indexOf(anchor);
      if (idx != -1) {
        urls.addAll(allChapters.sublist(idx).map((c) => c.url));
      }
    }
    if (urls.isNotEmpty) {
      await markChaptersConsumed(chapterUrls: urls, consumed: true);
    }
  }

  Future<void> downloadChapters(List<MChapter> chapters) async {
    final currentService = service;
    if (currentService == null || chapters.isEmpty) return;
    final container = ProviderScope.containerOf(context, listen: false);
    final l10n = AppLocalizations.of(context);
    final entryId = await ensureLibraryEntry();
    if (entryId == null) return;

    final added = await downloadAllChapters(
      container: container,
      service: currentService,
      libraryEntryId: entryId,
      sourceId: currentService.info.id,
      entryTitle: entry.title,
      chapters: chapters,
    );
    if (context.mounted && l10n != null) {
      final navigator = Navigator.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.downloadQueueAdded(added)),
          action: SnackBarAction(
            label: l10n.downloadQueueView,
            onPressed: () => navigator.push(
              MaterialPageRoute<void>(
                builder: (_) => const DownloadQueuePage(),
              ),
            ),
          ),
        ),
      );
    }
  }

  Future<void> deleteDownloads(List<MChapter> chapters) async {
    final entryId = getLibraryEntryId();
    if (entryId == null || chapters.isEmpty) return;

    final repo = ref.read(libraryRepositoryProvider);
    for (final chapter in chapters) {
      final localPath = await repo
          .watchChapterLocalPath(
            libraryEntryId: entryId,
            chapterUrl: chapter.url,
          )
          .first;
      if (localPath != null) {
        await deleteChapterDownload(
          repository: repo,
          libraryEntryId: entryId,
          chapterUrl: chapter.url,
          localPath: localPath,
        );
      }
    }
  }

  Future<void> bulkMarkConsumed({
    required EntryDetailChapterSelection selection,
    required bool consumed,
  }) async {
    final urls = selection.selectedUrls.toList();
    selection.clear();
    await markChaptersConsumed(chapterUrls: urls, consumed: consumed);
  }

  Future<void> bulkDownload({
    required EntryDetailChapterSelection selection,
    required List<MChapter> allChapters,
  }) async {
    final chapters = allChapters
        .where((c) => selection.contains(c.url))
        .toList();
    selection.clear();
    await downloadChapters(chapters);
  }

  Future<void> bulkDeleteDownloads({
    required EntryDetailChapterSelection selection,
    required List<MChapter> allChapters,
  }) async {
    final chapters = allChapters
        .where((c) => selection.contains(c.url))
        .toList();
    selection.clear();
    await deleteDownloads(chapters);
  }

  Future<void> markPreviousAsRead({
    required EntryDetailChapterSelection selection,
    required List<MChapter> allChapters,
  }) async {
    if (selection.isEmpty) return;
    final anchor = allChapters.firstWhere(
      (c) => selection.contains(c.url),
      orElse: () => allChapters.first,
    );
    selection.clear();
    await markPreviousChaptersRead(anchor: anchor, allChapters: allChapters);
  }
}
