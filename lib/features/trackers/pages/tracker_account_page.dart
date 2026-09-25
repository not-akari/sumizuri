import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_list_row.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/controls/no_scrollbar.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/library/widgets/library_filter_chips.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/pages/tracker_account_actions.dart';
import 'package:sumizuri/features/trackers/providers/tracker_providers.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_entry_editor.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_overview.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_problem_text.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_queue.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _contentWidth = 720.0;
const _wideContentWidth = 1040.0;
const _wideBreakpoint = 900.0;

enum _Section { anime, manga, queue }

enum _MenuAction { refresh, sync, importAll, importShown, open, disconnect }

enum _EntryAction { edit, addToLibrary, open }

/// A tracker account: who is connected, the numbers, both lists as covers, and
/// the progress waiting to be sent. The same page for every tracker.
class TrackerAccountPage extends ConsumerStatefulWidget {
  const TrackerAccountPage({super.key, required this.kind});

  final TrackerKind kind;

  @override
  ConsumerState<TrackerAccountPage> createState() => _TrackerAccountPageState();
}

class _TrackerAccountPageState extends ConsumerState<TrackerAccountPage> {
  final _search = TextEditingController();

  /// Null is the overview.
  _Section? _section;
  TrackerStatus? _status;
  var _query = '';
  var _syncing = false;

  TrackerKind get _kind => widget.kind;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  TrackerMedia? get _media => switch (_section) {
    _Section.anime => TrackerMedia.anime,
    _Section.manga => TrackerMedia.manga,
    _ => null,
  };

  void _pick(_Section? section) => setState(() {
    _section = section;
    _status = null;
    _query = '';
    _search.clear();
  });

  bool _matches(TrackerEntry entry) {
    if (_status != null && entry.status != _status) return false;
    if (_query.isEmpty) return true;
    return [
      entry.title,
      ...entry.synonyms,
    ].join(' ').toLowerCase().contains(_query);
  }

  Future<void> _refreshAll() async {
    refreshTracker(ref, _kind);
    await ref
        .read(trackerStatsProvider(_kind).future)
        .then((_) {}, onError: (_) {});
  }

  Future<void> _sync() async {
    if (_syncing) return;
    setState(() => _syncing = true);
    try {
      await syncTrackerNow(context, ref, _kind);
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  Future<void> _edit(TrackerEntry entry) async {
    final changed = await showTrackerEntryEditor(context, entry);
    if (changed && mounted) {
      ref.invalidate(trackerEntriesProvider((_kind, entry.media)));
      ref.invalidate(trackerStatsProvider(_kind));
    }
  }

  Future<void> _openSite(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  Future<void> _entryMenu(TrackerEntry entry, bool inLibrary) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showAppSheet<_EntryAction>(
      context,
      builder: (sheet) => AppSheet(
        title: entry.title,
        children: [
          AppListRow(
            icon: Icons.edit_outlined,
            title: l10n.trackerEditTitle,
            onTap: () => Navigator.of(sheet).pop(_EntryAction.edit),
          ),
          if (!inLibrary)
            AppListRow(
              icon: Icons.download_outlined,
              title: l10n.trackerAddToLibrary,
              onTap: () => Navigator.of(sheet).pop(_EntryAction.addToLibrary),
            ),
          AppListRow(
            icon: Icons.open_in_new,
            title: l10n.trackerOpenOnSite(_kind.label),
            onTap: () => Navigator.of(sheet).pop(_EntryAction.open),
          ),
        ],
      ),
    );
    if (!mounted || choice == null) return;
    switch (choice) {
      case _EntryAction.edit:
        await _edit(entry);
      case _EntryAction.addToLibrary:
        await importTrackerTitles(context, ref, _kind, [entry]);
      case _EntryAction.open:
        final url = entry.siteUrl;
        if (url != null) await _openSite(url);
    }
  }

  Future<void> _onMenu(
    _MenuAction action,
    TrackerAccountInfo? account,
    List<TrackerEntry> shown,
  ) async {
    switch (action) {
      case _MenuAction.refresh:
        await _refreshAll();
      case _MenuAction.sync:
        await _sync();
      case _MenuAction.importAll:
        await importTrackerLists(context, ref, _kind);
      case _MenuAction.importShown:
        await importTrackerTitles(context, ref, _kind, shown);
      case _MenuAction.open:
        if (account != null) await _openSite(account.profileUrl);
      case _MenuAction.disconnect:
        if (await confirmTrackerDisconnect(context, ref, _kind) && mounted) {
          Navigator.of(context).maybePop();
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final media = _media;
    final entries = media == null
        ? null
        : ref.watch(trackerEntriesProvider((_kind, media)));
    final all = entries?.value ?? const <TrackerEntry>[];
    final shown = all.where(_matches).toList();
    final queued = ref.watch(trackerQueueProvider(_kind)).value?.length ?? 0;
    final account = ref.watch(trackerAccountProvider(_kind)).value;
    final gutter = context.layout.gutter;

    return Scaffold(
      body: Stack(
        children: [
          const AmbientBloomBackground(),
          RefreshIndicator(
            onRefresh: _refreshAll,
            child: ScrollConfiguration(
              behavior: const NoScrollbarBehavior(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverAppBar(
                    floating: true,
                    snap: true,
                    title: Text(l10n.trackerAccountTitle(_kind.label)),
                    backgroundColor: Colors.transparent,
                    flexibleSpace: const WindowAmbient(),
                    scrolledUnderElevation: 0,
                    surfaceTintColor: Colors.transparent,
                    actions: [
                      AppMenu<_MenuAction>(
                        entries: [
                          AppMenuEntry(
                            _MenuAction.refresh,
                            l10n.trackerMenuRefresh,
                            icon: Icons.refresh_rounded,
                          ),
                          AppMenuEntry(
                            _MenuAction.sync,
                            l10n.trackerSyncTitle,
                            icon: Icons.sync,
                          ),
                          if (media == null)
                            AppMenuEntry(
                              _MenuAction.importAll,
                              l10n.trackerImportTitle,
                              icon: Icons.download_outlined,
                            )
                          else if (shown.isNotEmpty)
                            AppMenuEntry(
                              _MenuAction.importShown,
                              l10n.trackerImportShown(shown.length),
                              icon: Icons.download_outlined,
                            ),
                          AppMenuEntry(
                            _MenuAction.open,
                            l10n.trackerOpenOnSite(_kind.label),
                            icon: Icons.open_in_new,
                            dividerBefore: true,
                          ),
                          AppMenuEntry(
                            _MenuAction.disconnect,
                            l10n.trackerDisconnectConfirm,
                            icon: Icons.link_off,
                            destructive: true,
                          ),
                        ],
                        onSelected: (action) => _onMenu(action, account, shown),
                      ),
                    ],
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: gutter - 8),
                      child: FilterTabRow<_Section>(
                        allLabel: l10n.trackerTabOverview,
                        selected: _section,
                        items: [
                          (_Section.anime, l10n.trackerTabAnime),
                          (_Section.manga, l10n.trackerTabManga),
                          (
                            _Section.queue,
                            queued > 0
                                ? '${l10n.trackerTabQueue} $queued'
                                : l10n.trackerTabQueue,
                          ),
                        ],
                        onSelect: _pick,
                      ),
                    ),
                  ),
                  if (media != null)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(gutter, 4, gutter, 4),
                        child: AnimatedSearchBar(
                          controller: _search,
                          hintText: l10n.trackerListSearch,
                          onChanged: (v) =>
                              setState(() => _query = v.trim().toLowerCase()),
                          onClear: () => setState(() => _query = ''),
                        ),
                      ),
                    ),
                  if (media != null && entries != null)
                    ..._listSlivers(l10n, media, entries, all, shown),
                  if (_section == null) _overview(l10n, account, queued),
                  if (_section == _Section.queue)
                    TrackerQueueSlivers(kind: _kind),
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: context.layout.scrollBottomOf(context, 32),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _overview(
    AppLocalizations l10n,
    TrackerAccountInfo? account,
    int queued,
  ) {
    final cs = Theme.of(context).colorScheme;
    final stats = ref.watch(trackerStatsProvider(_kind));
    final wide = MediaQuery.sizeOf(context).width >= _wideBreakpoint;
    final gutter = context.layout.gutter;

    final hero = TrackerHeroCard(
      kind: _kind,
      account: account,
      syncing: _syncing,
      onSync: _sync,
    );
    final kinds = stats.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (error, _) => ErrorView(
        message: trackerReason(l10n, _kind, error),
        onRetry: () => ref.invalidate(trackerStatsProvider(_kind)),
      ),
      // Both cards as tall as the taller one, in a page that scrolls.
      data: (value) => IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TrackerKindCard(
                title: l10n.trackerTabAnime,
                icon: Icons.tv_rounded,
                stats: value.anime,
                anime: true,
                onTap: () => _pick(_Section.anime),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TrackerKindCard(
                title: l10n.trackerTabManga,
                icon: Icons.menu_book_rounded,
                stats: value.manga,
                anime: false,
                onTap: () => _pick(_Section.manga),
              ),
            ),
          ],
        ),
      ),
    );
    final tools = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppSectionLabel(label: l10n.trackerSectionTools),
        AppListRow(
          icon: Icons.download_outlined,
          iconColor: cs.primary,
          title: l10n.trackerImportTitle,
          subtitle: l10n.trackerImportHint(_kind.label),
          onTap: () => importTrackerLists(context, ref, _kind),
        ),
        AppListRow(
          icon: Icons.sync,
          iconColor: cs.primary,
          title: l10n.trackerSyncTitle,
          subtitle: l10n.trackerSyncHint(_kind.label),
          onTap: _sync,
        ),
        AppListRow(
          icon: Icons.schedule_send_outlined,
          iconColor: cs.primary,
          title: l10n.trackerTabQueue,
          subtitle: queued > 0
              ? l10n.trackerStatTitles(queued)
              : l10n.trackerQueueEmpty,
          onTap: () => _pick(_Section.queue),
        ),
      ],
    );

    return SliverToBoxAdapter(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: wide ? _wideContentWidth : _contentWidth,
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(gutter, 12, gutter, 0),
            child: AppRowStyle(
              horizontalMargin: 0,
              child: wide
                  ? Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [hero, const SizedBox(height: 10), kinds],
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(flex: 2, child: tools),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        hero,
                        const SizedBox(height: 10),
                        kinds,
                        tools,
                      ],
                    ),
            ),
          ),
        ),
      ),
    );
  }

  /// The titles of a list in the layout the person chose for the library.
  Widget _entries(
    AppLocalizations l10n,
    bool anime,
    List<TrackerEntry> shown,
    Set<TrackerTitleKey> linked,
    LibraryDisplayStyle displayStyle,
    LibraryGridTileSize tileSize,
    double gutter,
  ) {
    Widget item(BuildContext context, int index) {
      final entry = shown[index];
      final total = entry.total;
      final left = total == null ? null : total - entry.progress;
      final inLibrary = linked.contains(entry.key);
      final unread = left != null && left > 0 ? left : null;
      final caption = [
        // Redundant when the list is already narrowed to one status.
        if (_status == null)
          trackerStatusLabel(l10n, entry.status, anime: anime),
        total != null
            ? l10n.trackerProgressOf(entry.progress, total)
            : l10n.trackerProgressOnly(entry.progress),
        if (entry.score > 0) trackerScoreText(entry.score),
      ].where((p) => p.isNotEmpty).join('  ');
      if (!displayStyle.isGrid) {
        return MangaCoverListRow(
          title: entry.title,
          coverUrl: entry.coverUrl,
          caption: caption,
          dense: displayStyle == LibraryDisplayStyle.compactList,
          unreadCount: unread,
          marked: inLibrary,
          onTap: () => _edit(entry),
          onLongPress: () => _entryMenu(entry, inLibrary),
        );
      }
      return MangaCoverTile(
        variant: switch (displayStyle) {
          LibraryDisplayStyle.compactGrid => CoverTileVariant.compact,
          LibraryDisplayStyle.coverGrid => CoverTileVariant.coverOnly,
          _ => CoverTileVariant.comfortable,
        },
        title: entry.title,
        coverUrl: entry.coverUrl,
        unreadCount: unread,
        caption: caption,
        marked: inLibrary,
        onTap: () => _edit(entry),
        onLongPress: () => _entryMenu(entry, inLibrary),
      );
    }

    if (!displayStyle.isGrid) {
      return SliverPadding(
        padding: const EdgeInsets.only(top: 8),
        sliver: SliverList.builder(itemCount: shown.length, itemBuilder: item),
      );
    }
    return SliverPadding(
      padding: EdgeInsets.all(gutter - 4),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: tileSize.maxExtent,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: displayStyle == LibraryDisplayStyle.comfortableGrid
              ? 0.5
              : coverAspectRatio,
        ),
        delegate: SliverChildBuilderDelegate(item, childCount: shown.length),
      ),
    );
  }

  List<Widget> _listSlivers(
    AppLocalizations l10n,
    TrackerMedia media,
    AsyncValue<List<TrackerEntry>> entries,
    List<TrackerEntry> all,
    List<TrackerEntry> shown,
  ) {
    final anime = media == TrackerMedia.anime;
    final linked =
        ref.watch(trackerLinkedProvider(_kind)).value ??
        const <TrackerTitleKey>{};
    final tileSize =
        ref.watch(libraryGridTileSizeProvider).value ??
        LibraryGridTileSize.medium;
    final displayStyle =
        ref.watch(libraryDisplayStyleProvider).value ??
        LibraryDisplayStyle.comfortableGrid;
    final gutter = context.layout.gutter;
    return entries.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
      error: (error, _) => [
        SliverToBoxAdapter(
          child: ErrorView(
            message: l10n.trackerLoadListFailed(
              trackerReason(l10n, _kind, error),
            ),
            onRetry: () =>
                ref.invalidate(trackerEntriesProvider((_kind, media))),
          ),
        ),
      ],
      data: (_) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: gutter - 8),
            child: FilterTabRow<TrackerStatus>(
              brush: true,
              allLabel: '${l10n.trackerFilterAll} ${all.length}',
              selected: _status,
              items: [
                for (final status in TrackerStatus.values)
                  if (all.any((e) => e.status == status))
                    (
                      status,
                      '${trackerStatusLabel(l10n, status, anime: anime)} ${all.where((e) => e.status == status).length}',
                    ),
              ],
              onSelect: (v) => setState(() => _status = v),
            ),
          ),
        ),
        if (shown.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(l10n.trackerListEmpty)),
            ),
          )
        else
          _entries(l10n, anime, shown, linked, displayStyle, tileSize, gutter),
      ],
    );
  }
}
