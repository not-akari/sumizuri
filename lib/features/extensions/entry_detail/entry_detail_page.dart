import 'package:sumizuri/features/library/widgets/series_download_settings_sheet.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_media_wording.dart';

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/gestures/app_gestures.dart';
import 'package:sumizuri/features/extensions/entry_detail/scanlator_filter_dialog.dart';
import 'package:sumizuri/features/library/models/scanlator_filter.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/features/extensions/data/extension_service.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/features/extensions/models/installed_source.dart';
import 'package:sumizuri/features/extensions/models/m_chapter.dart';
import 'package:sumizuri/features/extensions/models/m_entry.dart';
import 'package:sumizuri/features/extensions/models/season_group.dart';
import 'package:sumizuri/features/extensions/entry_detail/season_cards.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/settings/registry/settings_catalog.dart';
import 'package:sumizuri/features/extensions/cloudflare/challenge_error_view.dart';
import 'package:sumizuri/features/extensions/entry_detail/chapter_overflow_menu.dart';
import 'package:sumizuri/features/extensions/entry_detail/chapter_selection_app_bar.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_branch_widgets.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_chapter_actions.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_chapter_widgets.dart';
import 'package:sumizuri/features/extensions/providers/extension_providers.dart'
    show closeUnwanted;
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_continue_button.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_data_loader.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_navigation.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_poster_actions.dart';
import 'package:sumizuri/features/extensions/entry_detail/entry_detail_scaffold_body.dart';

part 'entry_detail_loading.dart';

class EntryDetailPage extends ConsumerStatefulWidget {
  const EntryDetailPage.fromService({
    super.key,
    required this.entry,
    required ExtensionService service,
    required AppInstalledSource source,
    this.heroTag,
  }) : _service = service, // ignore: prefer_initializing_formals
       _source = source, // ignore: prefer_initializing_formals
       _libraryEntryId = null;

  const EntryDetailPage.fromLibrary({
    super.key,
    required this.entry,
    required AppInstalledSource source,
    required int libraryEntryId,
    this.heroTag,
  }) : _service = null,
       _source = source, // ignore: prefer_initializing_formals
       _libraryEntryId = libraryEntryId; // ignore: prefer_initializing_formals

  const EntryDetailPage.fromSearch({
    super.key,
    required this.entry,
    required AppInstalledSource source,
    this.heroTag,
  }) : _service = null,
       _source = source, // ignore: prefer_initializing_formals
       _libraryEntryId = null;

  final MEntry entry;
  final ExtensionService? _service;
  final AppInstalledSource? _source;
  final int? _libraryEntryId;
  final String? heroTag;

  @override
  ConsumerState<EntryDetailPage> createState() => _EntryDetailPageState();
}

class _EntryDetailPageState extends ConsumerState<EntryDetailPage>
    with _EntryDetailLoading {
  @override
  ExtensionService? _service;
  @override
  bool _ownsService = false;
  AppFailure? _serviceLoadError;

  @override
  late MEntry _entry = widget.entry;
  @override
  List<MChapter>? _allChapters;
  @override
  Set<String> _excludedScanlators = {};
  @override
  List<MChapter>? _chapters;

  ({String? key})? _openSeason;

  bool _hideDuplicates = false;

  // Read from the setting in build; the getters below run outside it.
  bool _detectDuplicates = true;

  @override
  List<MChapter>? get _visibleChapters {
    final list = _visibleChaptersWithDuplicates;
    if (list == null || !_detectDuplicates || !_hideDuplicates) return list;
    return withoutDuplicateChapters(list);
  }

  List<MChapter>? get _visibleChaptersWithDuplicates {
    final all = _chapters;
    final open = _openSeason;
    if (all == null || open == null) return all;
    return [
      for (final chapter in all)
        if (chapter.season == open.key) chapter,
    ];
  }

  List<SeasonGroup> get _seasons {
    final all = _chapters;
    if (all == null || _openSeason != null) return const [];
    return groupSeasons(all);
  }

  AppFailure? _error;
  @override
  bool? _sortAscendingOverride;

  @override
  int? _libraryEntryId;
  ExtensionCapabilities? _capabilities;

  // Set once from the entry the page opened with, never from details that arrive later.
  late final String? _heroTag =
      widget.heroTag ??
      (widget.entry.coverUrl == null || widget.entry.coverUrl!.isEmpty
          ? null
          : 'cover:${widget.entry.coverUrl}');
  Timer? _countdownTimer;

  final _scrollOffset = ValueNotifier<double>(0);

  @override
  final _selection = EntryDetailChapterSelection();

  @override
  EntryDetailChapterActions get _chapterActions => EntryDetailChapterActions(
    ref: ref,
    context: context,
    entry: _entry,
    source: widget._source,
    service: _service,
    getLibraryEntryId: () => _libraryEntryId,
    ensureLibraryEntry: _ensureInLibrary,
    onReloadChapters: _loadChapters,
  );

  @override
  void initState() {
    super.initState();
    _libraryEntryId = widget._libraryEntryId;
    final service = widget._service;
    if (service != null) {
      _service = service;
      _init();
    } else {
      _loadOwnService();
    }
    _countdownTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (_isLive) setState(() {});
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _scrollOffset.dispose();
    if (_ownsService) _service?.dispose();
    super.dispose();
  }

  Future<void> _openChapter(MChapter chapter) async {
    await openEntryChapter(
      context: context,
      service: _service!,
      chapter: chapter,
      chapters: _visibleChapters ?? [chapter],
      libraryEntryId: _libraryEntryId,
      hasChapterComments: _capabilities?.hasChapterComments ?? true,
      onChapterComments: _openChapterComments,
      onReturn: () {
        if (_isLive) _loadChapters();
      },
    );
  }

  void _openEntryComments() => openEntryCommentsModal(
    context: context,
    service: _service!,
    entry: widget.entry,
  );

  void _openChapterComments(MChapter chapter) => openChapterCommentsModal(
    context: context,
    service: _service!,
    chapter: chapter,
  );

  Future<void> _openWebview() => openEntryWebview(
    context: context,
    url: _entry.webUrl ?? _entry.url,
    sourceId: _service!.info.id,
    onSolved: _reloadServiceAndRetry,
  );

  void _handleChapterTap(MChapter chapter) {
    if (_selection.isNotEmpty) {
      setState(() => _selection.toggle(chapter.url));
    } else {
      _openChapter(chapter);
    }
  }

  static const _wideBreakpoint = 700.0;

  List<Widget> _chapterSlivers(AppLocalizations l10n) {
    final effectiveEntryId = widget._libraryEntryId ?? _libraryEntryId;
    final gestures =
        ref.watch(appGesturesProvider).value ?? AppGestures.defaults;
    final seasons = _seasons;
    final open = _openSeason;
    final openGroup = open == null
        ? null
        : groupSeasons(_chapters ?? const [])
              .where((g) => g.key == open.key)
              .firstOrNull;
    final slivers = buildChapterSlivers(
      context: context,
      l10n: l10n,
      // Given outright: this context is above the page's own EntryMediaType, which it cannot see.
      mediaType: _service?.info.mediaType ?? MediaType.manga,
      chapters: seasons.isNotEmpty ? const [] : _visibleChapters,
      seasonHeading: openGroup == null ? null : seasonTitle(l10n, openGroup),
      onLeaveSeason: open == null
          ? null
          : () => setState(() {
              _openSeason = null;
              _selection.clear();
            }),
      layout:
          ref.watch(chapterListLayoutProvider).value ?? ChapterListLayout.list,
      hasChapterComments: _capabilities?.hasChapterComments ?? true,
      libraryEntryId: _libraryEntryId,
      sourceId: _service?.info.id,
      entryTitle: _entry.title,
      service: _service,
      branchSelector: effectiveEntryId != null
          ? BranchSelectorRow(
              libraryEntryId: effectiveEntryId,
              onBranchChanged: () => _loadChapters(),
            )
          : null,
      duplicateCount: !_detectDuplicates
          ? 0
          : duplicateChapterCount(_visibleChaptersWithDuplicates ?? const []),
      hidingDuplicates: _detectDuplicates && _hideDuplicates,
      onToggleDuplicates: () =>
          setState(() => _hideDuplicates = !_hideDuplicates),
      onRefresh: _chapters == null ? null : _refreshChapters,
      sortAscending:
          _sortAscendingOverride ??
          ref.watch(chapterSortAscendingProvider).value ??
          false,
      onToggleSort: _chapters == null ? null : _toggleChapterSort,
      overflowMenu: _chapterOverflowMenu(l10n),
      onOpenChapter: _openChapter,
      onOpenChapterComments: _openChapterComments,
      selectedChapterUrls: _selection.selectedUrls,
      onChapterLongPress: gestures.chapterLongPress == ChapterRowAction.none
          ? null
          : (chapter) => _doChapterAction(chapter, gestures.chapterLongPress),
      onChapterTap: _handleChapterTap,
      gestures: gestures,
      onChapterAction: _doChapterAction,
    );
    if (seasons.isEmpty) return slivers;
    return [
      ...slivers.take(slivers.length - 1),
      buildSeasonGrid(
        seasons: seasons,
        fallbackCoverUrl: _entry.coverUrl,
        onOpen: (group) => setState(() => _openSeason = (key: group.key)),
      ),
    ];
  }

  List<Widget> _posterActions(AppLocalizations l10n) => buildPosterActions(
    context: context,
    ref: ref,
    l10n: l10n,
    entry: _entry,
    libraryEntryId: _libraryEntryId,
    service: _service,
    hasComments: _capabilities?.hasComments ?? true,
    onLibraryAdded: () async => _isLive ? _loadLibraryMembership() : null,
    onLibraryRemoved: () =>
        _isLive ? setState(() => _libraryEntryId = null) : null,
    onOpenComments: _openEntryComments,
    onOpenWebview: _openWebview,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    _detectDuplicates =
        ref
            .watch(boolSettingProvider(Settings.detectDuplicateChapters))
            .value ??
        true;
    final entry = _entry;
    if (_service == null) {
      return Scaffold(
        appBar: AppBar(),
        body: Stack(
          children: [
            const AmbientBloomBackground(),
            _serviceLoadError != null
                ? ErrorView(message: _serviceLoadError!.displayMessage)
                : const Center(child: CircularProgressIndicator()),
          ],
        ),
      );
    }
    final isWide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final libraryEntryId = _libraryEntryId;
    final customCoverPath = libraryEntryId == null
        ? null
        : ref.watch(customCoverPathProvider(libraryEntryId)).value;
    final furthestChapter = libraryEntryId == null
        ? null
        : ref.watch(furthestReadProvider(libraryEntryId)).value;
    final sessions = libraryEntryId == null
        ? null
        : ref
              .watch(timelineSessionsProvider(libraryEntryId: libraryEntryId))
              .value;
    final latestSession = sessions?.firstOrNull;

    final continueButton = EntryContinueReadingButton(
      chapters: _chapters,
      furthestRead: furthestChapter,
      latestSession: latestSession,
      onOpenChapter: _openChapter,
    );
    final posterActions = _posterActions(l10n);
    final chapterSlivers = _chapterSlivers(l10n);

    return EntryMediaType(
      mediaType: _service!.info.mediaType,
      child: PopScope(
        canPop: _selection.isEmpty && _openSeason == null,
        onPopInvokedWithResult: (didPop, _) {
          if (didPop) return;
          if (_selection.isNotEmpty) {
            setState(_selection.clear);
          } else if (_openSeason != null) {
            setState(() => _openSeason = null);
          }
        },
        child: Scaffold(
          extendBodyBehindAppBar: _selection.isEmpty,
          appBar: _selection.isNotEmpty
              ? buildChapterSelectionAppBar(
                  selection: _selection,
                  chapters: _visibleChapters,
                  actions: _chapterActions,
                  onStateChanged: () => setState(() {}),
                )
              : buildEntryDetailAppBar(
                  isWide: isWide,
                  title: entry.title,
                  scrollOffset: _scrollOffset,
                ),
          body: Stack(
            children: [
              const AmbientBloomBackground(),
              _error is ChallengeFailure
                  ? ChallengeErrorView(
                      failure: _error! as ChallengeFailure,
                      sourceId: _service!.info.id,
                      onSolved: _reloadServiceAndRetry,
                    )
                  : _error != null
                  ? ErrorView(message: _error!.displayMessage)
                  : EntryDetailBody(
                      isWide: isWide,
                      entry: entry,
                      sourceName: _service!.info.name,
                      mediaType: _service!.info.mediaType,
                      chapters: _chapters,
                      posterActions: posterActions,
                      continueButton: continueButton,
                      chapterSlivers: chapterSlivers,
                      libraryEntryId: libraryEntryId,
                      customCoverPath: customCoverPath,
                      furthestChapter: furthestChapter,
                      heroTag: _heroTag,
                      scrollOffset: _scrollOffset,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
