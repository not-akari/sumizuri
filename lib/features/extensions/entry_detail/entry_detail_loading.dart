part of 'entry_detail_page.dart';

mixin _EntryDetailLoading on ConsumerState<EntryDetailPage> {
  abstract ExtensionService? _service;
  abstract bool _ownsService;
  set _serviceLoadError(AppFailure? value);
  abstract MEntry _entry;
  abstract List<MChapter>? _allChapters;
  abstract Set<String> _excludedScanlators;
  set _chapters(List<MChapter>? value);
  List<MChapter>? get _visibleChapters;
  set _error(AppFailure? value);
  abstract bool? _sortAscendingOverride;
  abstract int? _libraryEntryId;
  set _capabilities(ExtensionCapabilities? value);
  EntryDetailChapterSelection get _selection;
  EntryDetailChapterActions get _chapterActions;

  bool get _isLive => mounted && context.mounted;

  Future<void> _loadOwnService() async {
    final result = await loadEntryService(
      context: context,
      ref: ref,
      source: widget._source!,
    );
    if (!_isLive) {
      unawaited(closeUnwanted(result));
      return;
    }
    result.when(
      ok: (service) {
        _ownsService = true;
        setState(() => _service = service);
        _init();
      },
      err: (failure) => setState(() => _serviceLoadError = failure),
    );
  }

  void _init() {
    _loadDetails();
    _loadCapabilities();
    if (_libraryEntryId == null) {
      // Opened from search/browse: the library id isn't known yet, so
      // loading chapters right away would always take the slow live-network
      // branch even when this title is already in the library with chapters
      // cached locally. Wait for the (now O(1)) membership check first, so a
      // cache hit actually gets to use the cache.
      _loadLibraryMembership().then((_) {
        if (_isLive) _loadChapters();
      });
    } else {
      _loadChapters();
    }
  }

  Future<void> _loadLibraryMembership() async {
    final exactMatchId = await checkEntryLibraryMembership(
      ref: ref,
      service: _service!,
      entry: _entry,
    );
    if (!_isLive) return;
    if (exactMatchId != null) {
      setState(() => _libraryEntryId = exactMatchId);
      _syncChaptersIfPossible();
      _saveCoverIfMissing();
    }
  }

  void _saveCoverIfMissing() {
    final id = widget._libraryEntryId ?? _libraryEntryId;
    final cover = _entry.coverUrl;
    if (id == null || cover == null || cover.isEmpty) return;
    unawaited(ref.read(libraryRepositoryProvider).fillMissingCover(id, cover));
  }

  Future<int?> _ensureInLibrary() async {
    if (_libraryEntryId != null) return _libraryEntryId;
    final added = await addEntryToLibraryFromDetail(
      ref: ref,
      service: _service,
      entry: _entry,
    );
    if (added) {
      await _loadLibraryMembership();
    }
    return _libraryEntryId;
  }

  void _syncChaptersIfPossible([List<MChapter>? all]) {
    final libraryEntryId = _libraryEntryId;
    final chapters = all ?? _allChapters;
    if (libraryEntryId == null || chapters == null) return;
    syncEntryChapters(
      ref: ref,
      libraryEntryId: libraryEntryId,
      chapters: chapters,
    );
  }

  Future<void> _reloadServiceAndRetry() async {
    if (_ownsService) await _service?.dispose();
    if (!_isLive) return;
    setState(() {
      _service = null;
      _ownsService = false;
      _error = null;
      _chapters = null;
    });
    await _loadOwnService();
  }

  Future<void> _loadCapabilities() async {
    final result = await _service!.readCapabilities();
    if (!_isLive) return;
    result.when(
      ok: (capabilities) => setState(() => _capabilities = capabilities),
      err: (_) {},
    );
  }

  Future<void> _loadChapters({bool forceNetwork = false}) async {
    // The saved direction comes from the database, so it may not have arrived yet.
    final saved =
        _sortAscendingOverride ??
        await ref
            .read(settingsRepositoryProvider)
            .watchChapterSortAscending()
            .first;
    if (!_isLive) return;
    _sortAscendingOverride ??= saved;
    final result = await loadEntryChapters(
      ref: ref,
      service: _service!,
      entry: widget.entry,
      libraryEntryId: widget._libraryEntryId ?? _libraryEntryId,
      ascending: _currentSortAscending(),
      forceNetwork: forceNetwork,
    );
    if (!_isLive) return;
    result.when(
      ok: (chapters) async {
        // What this title hides comes from the library, so it is read before the list is shown.
        final entryId = widget._libraryEntryId ?? _libraryEntryId;
        if (entryId != null) {
          _excludedScanlators =
              (await ref
                      .read(libraryRepositoryProvider)
                      .watchExcludedScanlators(entryId)
                      .first)
                  .toSet();
        }
        if (!_isLive) return;
        setState(() {
          _allChapters = chapters;
          _chapters = withoutScanlators(
            chapters,
            _excludedScanlators,
            (c) => c.scanlator,
          );
        });
        _syncChaptersIfPossible(chapters);
      },
      err: (failure) => setState(() => _error = failure),
    );
  }

  void _doChapterAction(MChapter chapter, ChapterRowAction action) {
    switch (action) {
      case ChapterRowAction.toggleRead:
        _chapterActions.toggleChapterRead(chapter);
      case ChapterRowAction.download:
        _chapterActions.downloadChapters([chapter]);
      case ChapterRowAction.toggleBookmark:
        _chapterActions.toggleChapterBookmark(chapter);
      case ChapterRowAction.select:
        setState(() => _selection.toggle(chapter.url));
      case ChapterRowAction.none:
        break;
    }
  }

  Future<void> _refreshChapters() async {
    await _loadChapters(forceNetwork: true);
  }

  bool _currentSortAscending() =>
      _sortAscendingOverride ??
      ref.read(chapterSortAscendingProvider).value ??
      false;

  void _toggleChapterSort() {
    final ascending = !_currentSortAscending();
    final all = _allChapters;
    setState(() {
      _sortAscendingOverride = ascending;
      if (all != null) {
        _allChapters = sortChapters(all, ascending: ascending);
        _chapters = withoutScanlators(
          _allChapters!,
          _excludedScanlators,
          (c) => c.scanlator,
        );
      }
    });
    unawaited(
      ref.read(settingsRepositoryProvider).setChapterSortAscending(ascending),
    );
  }

  Future<void> _chooseScanlators() async {
    final all = _allChapters;
    if (all == null) return;
    final names = scanlatorsOf(all, (c) => c.scanlator);
    final chosen = await showScanlatorFilterDialog(
      context,
      names: names,
      hidden: _excludedScanlators,
    );
    if (chosen == null || !_isLive) return;
    final entryId = await _ensureInLibrary();
    if (entryId == null) return;
    await ref
        .read(libraryRepositoryProvider)
        .setExcludedScanlators(entryId, chosen.toList());
    if (!_isLive) return;
    setState(() {
      _excludedScanlators = chosen;
      _chapters = withoutScanlators(all, chosen, (c) => c.scanlator);
    });
  }

  Widget? _chapterOverflowMenu(AppLocalizations l10n) {
    return chapterOverflowMenu(
      l10n: l10n,
      chapters: _visibleChapters,
      hasScanlators:
          scanlatorsOf(
            _allChapters ?? const <MChapter>[],
            (c) => c.scanlator,
          ).length >
          1,
      inLibrary: _libraryEntryId != null,
      onSelected: (action, chapters) {
        switch (action) {
          case ChapterMenuAction.seriesDownloadSettings:
            final id = _libraryEntryId;
            if (id != null) unawaited(showSeriesDownloadSettings(context, id));
          case ChapterMenuAction.filterScanlators:
            unawaited(_chooseScanlators());
          case ChapterMenuAction.downloadAll:
            _chapterActions.downloadChapters(chapters);
          case ChapterMenuAction.markAllRead:
            _chapterActions.markChaptersConsumed(
              chapterUrls: [for (final c in chapters) c.url],
              consumed: true,
            );
          case ChapterMenuAction.markAllUnread:
            _chapterActions.markChaptersConsumed(
              chapterUrls: [for (final c in chapters) c.url],
              consumed: false,
            );
          case ChapterMenuAction.selectAll:
            setState(() => _selection.selectAll(chapters));
        }
      },
    );
  }

  Future<void> _loadDetails() async {
    final details = await loadEntryDetails(
      ref: ref,
      service: _service!,
      entry: widget.entry,
      libraryEntryId: widget._libraryEntryId,
      source: widget._source,
    );
    if (_isLive && details != null) {
      setState(() => _entry = details.mergedOver(_entry));
      _saveCoverIfMissing();
    }
  }
}
