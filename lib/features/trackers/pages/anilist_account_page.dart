import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/core/widgets/controls/settings_controls.dart';
import 'package:sumizuri/core/widgets/overlays/app_menu.dart';
import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/theming/theme_shapes.dart';
import 'package:sumizuri/core/utils/formatting/relative_date.dart';
import 'package:sumizuri/core/widgets/ambient/ambient_bloom_background.dart';
import 'package:sumizuri/core/widgets/controls/animated_search_bar.dart';
import 'package:sumizuri/core/widgets/cards/app_card.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/ambient/brush_line_painter.dart';
import 'package:sumizuri/core/widgets/feedback/error_view.dart';
import 'package:sumizuri/core/widgets/content/manga_cover_tile.dart';
import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/library/migration/migration_prompt.dart';
import 'package:sumizuri/features/library/widgets/library_filter_chips.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/settings/models/app_settings_types.dart';
import 'package:sumizuri/features/settings/providers/settings_providers.dart';
import 'package:sumizuri/features/trackers/providers/anilist_account_providers.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_import.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_progress_sync.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_sync_service.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/anilist_account.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/features/trackers/models/anilist_stats.dart';
import 'package:sumizuri/features/trackers/widgets/anilist_entry_editor.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

const _contentWidth = 720.0;

String _reason(Object error) =>
    error is AppFailure ? error.displayMessage : '$error';

/// 8590 as 8,590.
String _grouped(int value) => value.toString().replaceAllMapped(
  RegExp(r'\B(?=(\d{3})+(?!\d))'),
  (_) => ',',
);

enum _Section { anime, manga, queue }

enum _QueueAction { discard }

/// Your AniList account laid out like the library: header, search, filter row and covers.
class AniListAccountPage extends ConsumerStatefulWidget {
  const AniListAccountPage({super.key});

  @override
  ConsumerState<AniListAccountPage> createState() => _AniListAccountPageState();
}

class _AniListAccountPageState extends ConsumerState<AniListAccountPage> {
  final _search = TextEditingController();

  /// Null is the overview.
  _Section? _section;
  AniListListStatus? _status;
  var _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  AniListMediaType? get _type => switch (_section) {
    _Section.anime => AniListMediaType.anime,
    _Section.manga => AniListMediaType.manga,
    _ => null,
  };

  void _pick(_Section? section) => setState(() {
    _section = section;
    _status = null;
    _query = '';
    _search.clear();
  });

  bool _matches(AniListListEntry entry) {
    if (_status != null && entry.status != _status) return false;
    if (_query.isEmpty) return true;
    final media = entry.media;
    if (media == null) return false;
    final haystack = [
      media.title.romaji,
      media.title.english,
      media.title.native,
      ...media.synonyms,
    ].whereType<String>().join(' ').toLowerCase();
    return haystack.contains(_query);
  }

  Future<void> _refreshAll() async {
    ref.invalidate(aniListStatsProvider);
    ref.invalidate(aniListEntriesProvider(AniListMediaType.anime));
    ref.invalidate(aniListEntriesProvider(AniListMediaType.manga));
    ref.invalidate(aniListQueueProvider);
    await ref.read(aniListStatsProvider.future).then((_) {}, onError: (_) {});
  }

  Future<void> _edit(AniListListEntry entry) async {
    final type = entry.media?.type ?? _type;
    final changed = await showAniListEntryEditor(context, entry);
    if (changed && type != null) ref.invalidate(aniListEntriesProvider(type));
  }

  Future<void> _import(List<AniListListEntry> entries) async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(SnackBar(content: Text(l10n.aniListImportRunning)));
    final result = await _runImport(ref, entries);
    if (!mounted) return;
    messenger.hideCurrentSnackBar();
    await _showMigrate(context, l10n, result);
  }

  Future<void> _menu(AniListListEntry entry, bool inLibrary) async {
    final l10n = AppLocalizations.of(context)!;
    final choice = await showModalBottomSheet<String>(
      context: context,
      showDragHandle: true,
      builder: (sheet) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppListRow(
              icon: Icons.edit_outlined,
              title: l10n.aniListEditTitle,
              onTap: () => Navigator.of(sheet).pop('edit'),
            ),
            if (!inLibrary)
              AppListRow(
                icon: Icons.download_outlined,
                title: l10n.aniListAddToLibrary,
                onTap: () => Navigator.of(sheet).pop('import'),
              ),
            AppListRow(
              icon: Icons.open_in_new,
              title: l10n.aniListOpenOnSite,
              onTap: () => Navigator.of(sheet).pop('open'),
            ),
          ],
        ),
      ),
    );
    if (!mounted) return;
    switch (choice) {
      case 'edit':
        await _edit(entry);
      case 'import':
        await _import([entry]);
      case 'open':
        final media = entry.media;
        final type = media?.type == AniListMediaType.anime ? 'anime' : 'manga';
        await launchUrl(
          Uri.parse(
            media?.siteUrl ?? 'https://anilist.co/$type/${entry.mediaId}',
          ),
          mode: LaunchMode.externalApplication,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final type = _type;
    final entries = type == null
        ? null
        : ref.watch(aniListEntriesProvider(type));
    final all = entries?.value ?? const <AniListListEntry>[];
    final shown = all.where(_matches).toList();
    final queued = ref.watch(aniListQueueProvider).value?.length ?? 0;
    final account = ref.watch(aniListAccountProvider).value;
    final stats = ref.watch(aniListStatsProvider).value;
    final subtitle = [
      ?account?.name,
      if (stats != null) ...[
        '${l10n.aniListTabAnime} ${_grouped(stats.anime.count)}',
        '${l10n.aniListTabManga} ${_grouped(stats.manga.count)}',
      ],
    ].join('   ');

    return Scaffold(
      body: Stack(
        children: [
          const AmbientBloomBackground(),
          RefreshIndicator(
            onRefresh: _refreshAll,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: SizedBox(height: MediaQuery.paddingOf(context).top),
                ),
                SliverToBoxAdapter(
                  child: _Header(
                    title: l10n.aniListAccountTitle,
                    subtitle: subtitle,
                    onBack: () => Navigator.of(context).maybePop(),
                    onRefresh: _refreshAll,
                    onSync: () => _syncEverything(context, ref),
                    onImport: type == null
                        ? () => _importLists(context, ref)
                        : shown.isEmpty
                        ? null
                        : () => _import(shown),
                    syncTooltip: l10n.aniListSyncTitle,
                    importTooltip: l10n.aniListImportTitle,
                  ),
                ),
                if (type != null)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
                      child: AnimatedSearchBar(
                        controller: _search,
                        hintText: l10n.aniListListSearch,
                        onChanged: (v) =>
                            setState(() => _query = v.trim().toLowerCase()),
                        onClear: () => setState(() => _query = ''),
                      ),
                    ),
                  ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: FilterTabRow<_Section>(
                      allLabel: l10n.aniListTabOverview,
                      selected: _section,
                      items: [
                        (_Section.anime, l10n.aniListTabAnime),
                        (_Section.manga, l10n.aniListTabManga),
                        (
                          _Section.queue,
                          queued > 0
                              ? '${l10n.aniListTabQueue} $queued'
                              : l10n.aniListTabQueue,
                        ),
                      ],
                      onSelect: _pick,
                    ),
                  ),
                ),
                if (type != null && entries != null)
                  ..._listSlivers(l10n, type, entries, all, shown),
                if (_section == null)
                  ..._overviewSlivers(l10n, account, queued),
                if (_section == _Section.queue) const _QueueSlivers(),
                const SliverToBoxAdapter(child: SizedBox(height: 96)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _overviewSlivers(
    AppLocalizations l10n,
    AniListAccount? account,
    int queued,
  ) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final stats = ref.watch(aniListStatsProvider);
    return [
      SliverToBoxAdapter(
        child: Align(
          alignment: Alignment.topCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: _contentWidth),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (account != null)
                    AppCard(
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: cs.surfaceContainerHigh,
                            backgroundImage: account.avatarUrl == null
                                ? null
                                : NetworkImage(account.avatarUrl!),
                            child: account.avatarUrl == null
                                ? const Icon(Icons.person_outline)
                                : null,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              account.name,
                              style: theme.textTheme.titleLarge?.copyWith(
                                fontFamily: context.displayFont,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            tooltip: l10n.aniListOpenOnSite,
                            icon: const Icon(Icons.open_in_new),
                            onPressed: () => launchUrl(
                              Uri.parse(
                                'https://anilist.co/user/${account.name}',
                              ),
                              mode: LaunchMode.externalApplication,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 12),
                  stats.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.all(32),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                    error: (error, _) => ErrorView(message: _reason(error)),
                    data: (value) => Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _StatTile(
                            title: l10n.aniListTabAnime,
                            stats: value.anime,
                            anime: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatTile(
                            title: l10n.aniListTabManga,
                            stats: value.manga,
                            anime: false,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: Column(
                      children: [
                        AppListRow(
                          icon: Icons.download_outlined,
                          title: l10n.aniListImportTitle,
                          subtitle: l10n.aniListImportHint,
                          onTap: () => _importLists(context, ref),
                        ),
                        Divider(height: 1, color: cs.outlineVariant),
                        AppListRow(
                          icon: Icons.sync,
                          title: l10n.aniListSyncTitle,
                          subtitle: l10n.aniListSyncHint,
                          onTap: () => _syncEverything(context, ref),
                        ),
                        if (queued > 0) ...[
                          Divider(height: 1, color: cs.outlineVariant),
                          AppListRow(
                            icon: Icons.schedule_send_outlined,
                            title: l10n.aniListTabQueue,
                            subtitle: l10n.aniListStatTitles(queued),
                            onTap: () => _pick(_Section.queue),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _listSlivers(
    AppLocalizations l10n,
    AniListMediaType type,
    AsyncValue<List<AniListListEntry>> entries,
    List<AniListListEntry> all,
    List<AniListListEntry> shown,
  ) {
    final anime = type == AniListMediaType.anime;
    final linked = ref.watch(aniListLinkedProvider).value ?? const <int>{};
    final tileSize =
        ref.watch(libraryGridTileSizeProvider).value ??
        LibraryGridTileSize.medium;
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
            message: l10n.aniListLoadListFailed(_reason(error)),
            onRetry: () => ref.invalidate(aniListEntriesProvider(type)),
          ),
        ),
      ],
      data: (_) => [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: FilterTabRow<int>(
              brush: true,
              allLabel: '${l10n.aniListFilterAll} ${all.length}',
              selected: _status?.index,
              items: [
                for (final status in AniListListStatus.values)
                  if (all.any((e) => e.status == status))
                    (
                      status.index,
                      '${aniListStatusLabel(l10n, status, anime: anime)} ${all.where((e) => e.status == status).length}',
                    ),
              ],
              onSelect: (v) => setState(
                () => _status = v == null ? null : AniListListStatus.values[v],
              ),
            ),
          ),
        ),
        if (shown.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(l10n.aniListListEmpty)),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(12),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: tileSize.maxExtent,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.5,
              ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final entry = shown[index];
                final media = entry.media;
                final total = anime ? media?.episodes : media?.chapters;
                final hasTotal = total != null && total > 0;
                final left = hasTotal ? total - entry.progress : null;
                final inLibrary = linked.contains(entry.mediaId);
                return MangaCoverTile(
                  title: media?.title.display ?? '#${entry.mediaId}',
                  coverUrl: media?.coverUrl,
                  unreadCount: left != null && left > 0 ? left : null,
                  caption: [
                    aniListStatusLabel(l10n, entry.status, anime: anime),
                    hasTotal
                        ? l10n.aniListProgressOf(entry.progress, total)
                        : l10n.aniListProgressOnly(entry.progress),
                    if (entry.score > 0) '${entry.score}',
                  ].where((p) => p.isNotEmpty).join('  '),
                  marked: inLibrary,
                  onTap: () => _edit(entry),
                  onLongPress: () => _menu(entry, inLibrary),
                );
              }, childCount: shown.length),
            ),
          ),
      ],
    );
  }
}

/// The library's own header, with the AniList actions.
class _Header extends StatelessWidget {
  const _Header({
    required this.title,
    required this.subtitle,
    required this.onBack,
    required this.onRefresh,
    required this.onSync,
    required this.onImport,
    required this.syncTooltip,
    required this.importTooltip,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;
  final VoidCallback onRefresh;
  final VoidCallback onSync;
  final VoidCallback? onImport;
  final String syncTooltip;
  final String importTooltip;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final display = Theme.of(context).textTheme.headlineSmall;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 16, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: display?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.download_outlined),
                tooltip: importTooltip,
                onPressed: onImport,
              ),
              IconButton(
                icon: const Icon(Icons.sync),
                tooltip: syncTooltip,
                onPressed: onSync,
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                onPressed: onRefresh,
              ),
            ],
          ),
          if (subtitle.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 0, 0),
              child: Text(
                subtitle,
                style: TextStyle(fontSize: 13, color: cs.onSurfaceVariant),
              ),
            ),
          const SizedBox(height: 14),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: CustomPaint(
              size: const Size(double.infinity, 8),
              painter: BrushLinePainter(
                curvy: context.options.effects.brushStrokes,
                color: cs.outlineVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.title,
    required this.stats,
    required this.anime,
  });

  final String title;
  final AniListKindStats stats;
  final bool anime;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final lines = [
      anime
          ? l10n.aniListStatWatched(_grouped(stats.unitsDone))
          : l10n.aniListStatRead(_grouped(stats.unitsDone)),
      if (anime && stats.minutesWatched > 0)
        l10n.aniListStatDays(stats.daysWatched.toStringAsFixed(1)),
      if (stats.meanScore > 0)
        l10n.aniListStatMean(stats.meanScore.toStringAsFixed(1)),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _grouped(stats.count),
            style: theme.textTheme.headlineMedium?.copyWith(
              fontFamily: context.displayFont,
            ),
          ),
          const SizedBox(height: 10),
          for (final line in lines)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(line, style: theme.textTheme.bodySmall),
            ),
        ],
      ),
    );
  }
}

Future<void> _showMigrate(
  BuildContext context,
  AppLocalizations l10n,
  ImportResult result,
) async {
  final text = l10n.aniListImportDone(
    result.added,
    result.skipped,
    result.failed,
  );
  showMigratePrompt(context, text, result.addedIds);
}

Future<ImportResult> _runImport(
  WidgetRef ref,
  List<AniListListEntry> entries,
) async {
  final result = await importAniListEntries(
    library: ref.read(libraryRepositoryProvider),
    store: ref.read(trackerStoreProvider),
    profileId: ref.read(currentProfileIdProvider),
    entries: entries,
  );
  ref.invalidate(aniListLinkedProvider);
  return result;
}

Future<void> _importLists(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  List<AniListListEntry> anime;
  List<AniListListEntry> manga;
  try {
    anime = await ref.read(
      aniListEntriesProvider(AniListMediaType.anime).future,
    );
    manga = await ref.read(
      aniListEntriesProvider(AniListMediaType.manga).future,
    );
  } catch (error) {
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.aniListLoadListFailed(_reason(error)))),
    );
    return;
  }
  if (!context.mounted) return;
  var pickAnime = anime.isNotEmpty;
  var pickManga = manga.isNotEmpty;
  final chosen = await showDialog<bool>(
    context: context,
    builder: (dialog) => StatefulBuilder(
      builder: (dialog, setState) => AlertDialog(
        title: Text(l10n.aniListImportPickTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppToggleTile(
              checkbox: true,
              dense: false,
              value: pickAnime,
              onChanged: anime.isEmpty
                  ? null
                  : (v) => setState(() => pickAnime = v),
              title: l10n.aniListImportAnime(anime.length),
            ),
            AppToggleTile(
              checkbox: true,
              dense: false,
              value: pickManga,
              onChanged: manga.isEmpty
                  ? null
                  : (v) => setState(() => pickManga = v),
              title: l10n.aniListImportManga(manga.length),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialog).pop(false),
            child: Text(l10n.browseAddWarningCancel),
          ),
          FilledButton(
            onPressed: pickAnime || pickManga
                ? () => Navigator.of(dialog).pop(true)
                : null,
            child: Text(l10n.aniListImportTitle),
          ),
        ],
      ),
    ),
  );
  if (chosen != true) return;
  messenger.showSnackBar(SnackBar(content: Text(l10n.aniListImportRunning)));
  final result = await _runImport(ref, [
    if (pickAnime) ...anime,
    if (pickManga) ...manga,
  ]);
  if (!context.mounted) return;
  messenger.hideCurrentSnackBar();
  await _showMigrate(context, l10n, result);
}

Future<void> _syncEverything(BuildContext context, WidgetRef ref) async {
  final l10n = AppLocalizations.of(context)!;
  final messenger = ScaffoldMessenger.of(context);
  messenger.showSnackBar(SnackBar(content: Text(l10n.aniListSyncRunning)));
  try {
    // Read fresh, so what was edited on the site a moment ago counts.
    ref.invalidate(aniListEntriesProvider(AniListMediaType.anime));
    ref.invalidate(aniListEntriesProvider(AniListMediaType.manga));
    final remote = [
      ...await ref.read(aniListEntriesProvider(AniListMediaType.anime).future),
      ...await ref.read(aniListEntriesProvider(AniListMediaType.manga).future),
    ];
    final result = await syncProgress(
      library: ref.read(libraryRepositoryProvider),
      store: ref.read(trackerStoreProvider),
      profileId: ref.read(currentProfileIdProvider),
      remote: remote,
    );
    ref.invalidate(aniListQueueProvider);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          l10n.aniListSyncDone(result.pulled, result.pushed, result.waiting),
        ),
      ),
    );
  } catch (error) {
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(
      SnackBar(content: Text(l10n.aniListLoadListFailed(_reason(error)))),
    );
  }
}

class _QueueSlivers extends ConsumerStatefulWidget {
  const _QueueSlivers();

  @override
  ConsumerState<_QueueSlivers> createState() => _QueueSliversState();
}

class _QueueSliversState extends ConsumerState<_QueueSlivers> {
  var _sending = false;

  Future<void> _sendNow() async {
    final l10n = AppLocalizations.of(context)!;
    final messenger = ScaffoldMessenger.of(context);
    final profileId = ref.read(currentProfileIdProvider);
    setState(() => _sending = true);
    await ref.read(trackerStoreProvider).makeAllDue(profileId);
    final result = await ref
        .read(aniListSyncServiceProvider)
        .flush(profileId, force: true);
    ref.invalidate(aniListQueueProvider);
    ref.invalidate(aniListEntriesProvider(AniListMediaType.anime));
    ref.invalidate(aniListEntriesProvider(AniListMediaType.manga));
    if (!mounted) return;
    setState(() => _sending = false);
    final text = switch (result.outcome) {
      AniListFlushOutcome.sent => l10n.aniListSendResultSent(
        result.sent,
        result.failed,
      ),
      AniListFlushOutcome.noAccount => l10n.aniListSendResultNoAccount,
      AniListFlushOutcome.loginExpired => l10n.aniListSendResultExpired,
      AniListFlushOutcome.postponed => l10n.aniListSendResultLater,
      _ => l10n.aniListSendResultNothing,
    };
    messenger.showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _discard(int linkId) async {
    await ref.read(trackerStoreProvider).discard(linkId);
    ref.invalidate(aniListQueueProvider);
  }

  Widget _card(BuildContext context, AppLocalizations l10n, QueuedTitle item) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final meta = [
      formatRelativeDate(
        l10n,
        DateTime.fromMillisecondsSinceEpoch(item.firstQueuedAt),
      ),
      if (item.attempts > 0) l10n.aniListQueueTries(item.attempts),
    ].join('   ');
    return AppCard(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.fromLTRB(16, 10, 4, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  meta,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                ),
                if (item.lastError != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      item.lastError!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: cs.error,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          AppMenu<_QueueAction>.of(
            values: _QueueAction.values,
            label: (_) => l10n.aniListQueueDiscard,
            onSelected: (_) => _discard(item.linkId),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final queue = ref.watch(aniListQueueProvider);
    return SliverList.list(
      children: [
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            16,
            context.layout.gutter,
            8,
          ),
          child: Text(
            l10n.aniListQueueHint,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        queue.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (error, _) => ErrorView(message: _reason(error)),
          data: (items) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.upload_outlined),
                    label: Text(l10n.aniListSendNow),
                    onPressed: items.isEmpty || _sending ? null : _sendNow,
                  ),
                ),
              ),
              if (items.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(l10n.aniListQueueEmpty)),
                ),
              for (final item in items) _card(context, l10n, item),
            ],
          ),
        ),
      ],
    );
  }
}
