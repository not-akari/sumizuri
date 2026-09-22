import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

Future<void> showAniListTrackingSheet(
  BuildContext context, {
  required int libraryEntryId,
  required String title,
  required MediaType mediaType,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => _TrackingSheet(
      libraryEntryId: libraryEntryId,
      title: title,
      mediaType: mediaType,
    ),
  );
}

class _TrackingSheet extends ConsumerStatefulWidget {
  const _TrackingSheet({
    required this.libraryEntryId,
    required this.title,
    required this.mediaType,
  });

  final int libraryEntryId;
  final String title;

  final MediaType mediaType;

  @override
  ConsumerState<_TrackingSheet> createState() => _TrackingSheetState();
}

class _TrackingSheetState extends ConsumerState<_TrackingSheet> {
  late final TextEditingController _query = TextEditingController(
    text: widget.title,
  );
  TrackerLink? _link;
  bool _loaded = false;
  bool _searching = false;
  bool _choosing = false;
  bool _queued = false;
  bool _busy = false;
  String? _error;
  String? _notice;
  List<AniListMedia>? _results;
  AniListMedia? _remote;

  @override
  void initState() {
    super.initState();
    unawaited(_load());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  int get _profileId => ref.read(currentProfileIdProvider);

  Future<void> _load() async {
    final store = ref.read(trackerStoreProvider);
    final link = await store.linkFor(widget.libraryEntryId);
    final queued = link != null && await store.isQueued(widget.libraryEntryId);
    if (!mounted) return;
    setState(() {
      _link = link;
      _queued = queued;
      _loaded = true;
      _choosing = link == null;
    });
    if (link != null) unawaited(_loadRemote(link));
  }

  Future<void> _loadRemote(TrackerLink link) async {
    final result = await ref
        .read(aniListRepositoryProvider)
        .media(_profileId, link.mediaId);
    if (!mounted) return;
    setState(() => _remote = result.valueOrNull);
  }

  Future<void> _search() async {
    final text = _query.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _searching = true;
      _error = null;
    });
    final result = await ref
        .read(aniListRepositoryProvider)
        .search(
          _profileId,
          text,
          type: widget.mediaType == MediaType.anime
              ? AniListMediaType.anime
              : AniListMediaType.manga,
          novel: widget.mediaType == MediaType.novel,
        );
    if (!mounted) return;
    setState(() {
      _searching = false;
      result.when(
        ok: (page) => _results = page.results,
        err: (failure) => _error = failure.displayMessage,
      );
    });
  }

  Future<void> _choose(AniListMedia media) async {
    await ref
        .read(trackerStoreProvider)
        .link(
          libraryEntryId: widget.libraryEntryId,
          mediaId: media.id,
          title: media.title.display,
          chapters: media.chapters,
        );
    _remote = null;
    _results = null;
    await _load();
  }

  Future<void> _stop() async {
    await ref.read(trackerStoreProvider).unlink(widget.libraryEntryId);
    _remote = null;
    _notice = null;
    await _load();
  }

  Future<void> _sendNow() async {
    setState(() {
      _busy = true;
      _notice = null;
    });
    final result = await ref
        .read(aniListSyncServiceProvider)
        .flush(_profileId, force: true);
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = false;
      _notice = l10n.trackingSent;
    });
    await _load();
    if (!mounted) return;
    if (result.failed > 0) {
      setState(() => _error = '${result.failed} not saved by AniList.');
    }
  }

  String _statusLabel(AppLocalizations l10n, AniListListStatus? status) =>
      switch (status) {
        AniListListStatus.current => l10n.trackingStatusCurrent,
        AniListListStatus.planning => l10n.trackingStatusPlanning,
        AniListListStatus.completed => l10n.trackingStatusCompleted,
        AniListListStatus.dropped => l10n.trackingStatusDropped,
        AniListListStatus.paused => l10n.trackingStatusPaused,
        AniListListStatus.repeating => l10n.trackingStatusRepeating,
        null => '',
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final account = ref.watch(aniListAccountProvider).value;

    Widget body;
    if (!_loaded) {
      body = const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CircularProgressIndicator()),
      );
    } else if (account == null) {
      body = Padding(
        padding: EdgeInsets.fromLTRB(
          context.layout.gutter,
          8,
          context.layout.gutter,
          32,
        ),
        child: Text(l10n.trackingConnectFirst),
      );
    } else if (_choosing) {
      body = _buildSearch(l10n, cs);
    } else {
      body = _buildLinked(l10n, cs);
    }

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppSheetHeader(title: l10n.trackingTitle),
              body,
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSearch(AppLocalizations l10n, ColorScheme cs) {
    final results = _results;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: context.layout.gutter),
          child: TextField(
            controller: _query,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            decoration: InputDecoration(
              hintText: l10n.trackingSearchHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
            ),
          ),
        ),
        if (_error != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              12,
              context.layout.gutter,
              0,
            ),
            child: Text(_error!, style: TextStyle(color: cs.error)),
          ),
        if (results != null && results.isEmpty)
          Padding(
            padding: const EdgeInsets.all(20),
            child: Text(l10n.trackingNoResults),
          ),
        if (results != null)
          for (final media in results)
            InkWell(
              onTap: () => _choose(media),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 40,
                      height: 60,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: CoverImage(url: media.coverUrl, iconSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            media.title.display,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            [
                              if (media.format != null) media.format!,
                              if (media.startYear != null) '${media.startYear}',
                            ].join(' · '),
                            style: TextStyle(fontSize: 12, color: cs.outline),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        if (results == null && !_searching)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              12,
              context.layout.gutter,
              24,
            ),
            child: FilledButton.tonal(
              onPressed: _search,
              child: Text(l10n.trackingSearchHint),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLinked(AppLocalizations l10n, ColorScheme cs) {
    final link = _link!;
    final entry = _remote?.entry;
    final remoteLine = _remote == null
        ? null
        : entry == null
        ? l10n.trackingNotOnList
        : l10n.trackingRemote(_statusLabel(l10n, entry.status), entry.progress);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListRow(
          icon: Icons.auto_awesome_outlined,
          title: l10n.trackingLinkedTo(link.title),
          subtitle: remoteLine,
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            context.layout.gutter,
            4,
            context.layout.gutter,
            8,
          ),
          child: Text(
            _queued ? l10n.trackingQueued : l10n.trackingUpToDate,
            style: TextStyle(fontSize: 12, color: cs.outline),
          ),
        ),
        if (_notice != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              0,
              context.layout.gutter,
              8,
            ),
            child: Text(_notice!),
          ),
        if (_error != null)
          Padding(
            padding: EdgeInsets.fromLTRB(
              context.layout.gutter,
              0,
              context.layout.gutter,
              8,
            ),
            child: Text(_error!, style: TextStyle(color: cs.error)),
          ),
        Padding(
          padding: EdgeInsets.symmetric(
            horizontal: context.layout.gutter,
            vertical: 8,
          ),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              if (_queued)
                FilledButton(
                  onPressed: _busy ? null : _sendNow,
                  child: Text(l10n.trackingSendNow),
                ),
              OutlinedButton(
                onPressed: () => setState(() {
                  _choosing = true;
                  _results = null;
                }),
                child: Text(l10n.trackingChange),
              ),
              TextButton(onPressed: _stop, child: Text(l10n.trackingStop)),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
