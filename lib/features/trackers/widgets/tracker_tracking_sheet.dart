import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/theming/app_layout.dart';
import 'package:sumizuri/core/widgets/cards/app_list_row.dart';
import 'package:sumizuri/core/widgets/content/cover_image.dart';
import 'package:sumizuri/core/widgets/overlays/app_sheet.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/data/tracker_client_config.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/providers/tracker_actions.dart';
import 'package:sumizuri/features/trackers/providers/tracker_providers.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_entry_editor.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_kind_icon.dart';
import 'package:sumizuri/features/trackers/widgets/tracker_problem_text.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The trackers a title can be tracked on. MyAnimeList only when the build has its key.
List<TrackerKind> get _availableTrackers => [
  TrackerKind.anilist,
  if (malConfigured) TrackerKind.mal,
];

/// Opens the sheet that links a library entry to a title on a tracker.
Future<void> showTrackingSheet(
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
  late TrackerKind _kind = _availableTrackers.first;
  TrackerLink? _link;
  var _loaded = false;
  var _searching = false;
  var _choosing = false;
  var _queued = false;
  var _busy = false;
  String? _error;
  String? _notice;
  List<TrackerSearchResult>? _results;
  TrackerRemoteState? _remote;
  var _remoteKnown = false;

  TrackerMedia get _media => widget.mediaType == MediaType.anime
      ? TrackerMedia.anime
      : TrackerMedia.manga;

  @override
  void initState() {
    super.initState();
    unawaited(_open());
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  /// Starts on the tracker this entry is already linked to, if any.
  Future<void> _open() async {
    final kinds = _availableTrackers;
    final stores = [
      for (final kind in kinds) ref.read(trackerStoreForProvider(kind)),
    ];
    final entryId = widget.libraryEntryId;
    var start = kinds.first;
    for (var i = 0; i < kinds.length; i++) {
      if (await stores[i].linkFor(entryId) != null) {
        start = kinds[i];
        break;
      }
    }
    if (!mounted) return;
    _kind = start;
    await _load();
  }

  /// Nothing from [ref] is used after an `await` here: the sheet may be closed by then.
  Future<void> _load() async {
    final kind = _kind;
    final store = ref.read(trackerStoreForProvider(kind));
    final backend = ref.read(trackerBackendProvider(kind));
    final profileId = ref.read(currentProfileIdProvider);
    final link = await store.linkFor(widget.libraryEntryId);
    final queued = link != null && await store.isQueued(widget.libraryEntryId);
    if (!mounted || kind != _kind) return;
    setState(() {
      _link = link;
      _queued = queued;
      _loaded = true;
      _choosing = link == null;
    });
    if (link == null) return;
    TrackerRemoteState? remote;
    try {
      remote = await backend.remote(profileId, _media, link.mediaId);
    } on TrackerException {
      // Only the "On the tracker" line is lost.
    }
    if (!mounted || kind != _kind) return;
    setState(() {
      _remote = remote;
      _remoteKnown = remote != null;
    });
  }

  void _switchTo(TrackerKind kind) {
    if (kind == _kind) return;
    setState(() {
      _kind = kind;
      _loaded = false;
      _link = null;
      _remote = null;
      _remoteKnown = false;
      _results = null;
      _error = null;
      _notice = null;
    });
    unawaited(_load());
  }

  Future<void> _search() async {
    final text = _query.text.trim();
    if (text.isEmpty) return;
    final kind = _kind;
    final l10n = AppLocalizations.of(context)!;
    final backend = ref.read(trackerBackendProvider(kind));
    final profileId = ref.read(currentProfileIdProvider);
    setState(() {
      _searching = true;
      _error = null;
    });
    List<TrackerSearchResult>? results;
    String? error;
    try {
      results = await backend.search(
        profileId,
        text,
        media: _media,
        novel: widget.mediaType == MediaType.novel,
      );
    } on TrackerException catch (failure) {
      error = trackerReason(l10n, kind, failure);
    }
    if (!mounted || kind != _kind) return;
    setState(() {
      _searching = false;
      _results = results;
      _error = error;
    });
  }

  Future<void> _choose(TrackerSearchResult found) async {
    final store = ref.read(trackerStoreForProvider(_kind));
    await store.link(
      libraryEntryId: widget.libraryEntryId,
      mediaId: found.mediaId,
      title: found.title,
      chapters: found.total,
    );
    if (!mounted) return;
    _remote = null;
    _remoteKnown = false;
    _results = null;
    await _load();
  }

  Future<void> _stop() async {
    final store = ref.read(trackerStoreForProvider(_kind));
    await store.unlink(widget.libraryEntryId);
    if (!mounted) return;
    _remote = null;
    _remoteKnown = false;
    _notice = null;
    await _load();
  }

  Future<void> _sendNow() async {
    final kind = _kind;
    final actions = ref.read(trackerActionsProvider(kind));
    setState(() {
      _busy = true;
      _notice = null;
    });
    TrackerFlushResult? result;
    try {
      result = await actions.sendNow();
    } on TrackerException catch (failure) {
      if (mounted) {
        setState(
          () => _error = trackerReason(
            AppLocalizations.of(context)!,
            kind,
            failure,
          ),
        );
      }
    }
    if (!mounted) return;
    final l10n = AppLocalizations.of(context)!;
    setState(() {
      _busy = false;
      if (result != null) _notice = l10n.trackingSent(kind.label);
    });
    await _load();
    if (!mounted || result == null) return;
    if (result.failed > 0) {
      setState(
        () => _error = l10n.trackingFailedCount(result!.failed, kind.label),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final cs = Theme.of(context).colorScheme;
    final accountState = ref.watch(trackerAccountProvider(_kind));
    final account = accountState.value;
    final kinds = _availableTrackers;

    Widget body;
    // Not "connect first" while it is still being found out who is connected.
    if (!_loaded || accountState.isLoading) {
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
        child: Text(l10n.trackingConnectFirst(_kind.label)),
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
              if (kinds.length > 1)
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    context.layout.gutter,
                    0,
                    context.layout.gutter,
                    12,
                  ),
                  child: SegmentedButton<TrackerKind>(
                    showSelectedIcon: false,
                    segments: [
                      for (final kind in kinds)
                        ButtonSegment(value: kind, label: Text(kind.label)),
                    ],
                    selected: {_kind},
                    onSelectionChanged: (picked) => _switchTo(picked.first),
                  ),
                ),
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
              hintText: l10n.trackingSearchHint(_kind.label),
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
            child: Text(l10n.trackingNoResults(_kind.label)),
          ),
        if (results != null)
          for (final found in results)
            InkWell(
              onTap: () => _choose(found),
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
                        child: CoverImage(url: found.coverUrl, iconSize: 18),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            found.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            found.subtitle,
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
              child: Text(l10n.trackingSearchHint(_kind.label)),
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildLinked(AppLocalizations l10n, ColorScheme cs) {
    final link = _link!;
    final entry = _remote?.entry;
    final remoteLine = !_remoteKnown
        ? null
        : entry == null
        ? l10n.trackingNotOnList(_kind.label)
        : l10n.trackingRemote(
            _kind.label,
            trackerStatusLabel(
              l10n,
              entry.status,
              anime: _media == TrackerMedia.anime,
            ),
            entry.progress,
          );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppListRow(
          icon: trackerKindIcon(_kind),
          title: l10n.trackingLinkedTo(_kind.label, link.title),
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
            _queued ? l10n.trackingQueued(_kind.label) : l10n.trackingUpToDate,
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
