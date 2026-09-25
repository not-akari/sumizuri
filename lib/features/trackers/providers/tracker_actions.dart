import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/features/library/providers/library_providers.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/data/tracker_import.dart';
import 'package:sumizuri/features/trackers/data/tracker_progress_sync.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/providers/tracker_providers.dart';

/// What a person does with a tracker that takes a while: sync, import, send,
/// disconnect. It belongs to a provider and not to a page, so it goes on
/// working, and stays safe to use, when the page that started it is closed
/// half way. A page must not use its own `ref` after an `await`.
class TrackerActions {
  TrackerActions(this._ref, this.kind);

  final Ref _ref;
  final TrackerKind kind;

  int get _profileId => _ref.read(currentProfileIdProvider);

  /// Forgets everything read from the tracker, so the pages load it again.
  void refresh() {
    _ref.invalidate(trackerAccountProvider(kind));
    _ref.invalidate(trackerStatsProvider(kind));
    _ref.invalidate(trackerQueueProvider(kind));
    _ref.invalidate(trackerLinkedProvider(kind));
    for (final media in TrackerMedia.values) {
      _ref.invalidate(trackerEntriesProvider((kind, media)));
    }
  }

  /// A list read while nothing else is watching it, kept until it is in.
  Future<List<TrackerEntry>> _list(
    TrackerMedia media, {
    bool fresh = false,
  }) async {
    final provider = trackerEntriesProvider((kind, media));
    if (fresh) _ref.invalidate(provider);
    final hold = _ref.listen(provider, (_, _) {});
    try {
      return await _ref.read(provider.future);
    } finally {
      hold.close();
    }
  }

  /// Both lists, as the tracker has them.
  Future<({List<TrackerEntry> anime, List<TrackerEntry> manga})> lists({
    bool fresh = false,
  }) async => (
    anime: await _list(TrackerMedia.anime, fresh: fresh),
    manga: await _list(TrackerMedia.manga, fresh: fresh),
  );

  /// Brings the library and the tracker level, both ways.
  Future<ProgressSyncResult> sync() async {
    final all = await lists(fresh: true);
    final result = await syncTrackerProgress(
      library: _ref.read(libraryRepositoryProvider),
      store: _ref.read(trackerStoreForProvider(kind)),
      profileId: _profileId,
      remote: [...all.anime, ...all.manga],
    );
    _ref.invalidate(trackerQueueProvider(kind));
    return result;
  }

  /// Adds [entries] to the library as titles with no source yet.
  Future<ImportResult> import(List<TrackerEntry> entries) async {
    final result = await importTrackerEntries(
      library: _ref.read(libraryRepositoryProvider),
      store: _ref.read(trackerStoreForProvider(kind)),
      profileId: _profileId,
      entries: entries,
    );
    _ref.invalidate(trackerLinkedProvider(kind));
    return result;
  }

  /// Sends everything waiting, at once.
  Future<TrackerFlushResult> sendNow() async {
    final profileId = _profileId;
    await _ref.read(trackerStoreForProvider(kind)).makeAllDue(profileId);
    final result = await _ref
        .read(trackerBackendProvider(kind))
        .flush(profileId, force: true);
    _ref.invalidate(trackerQueueProvider(kind));
    for (final media in TrackerMedia.values) {
      _ref.invalidate(trackerEntriesProvider((kind, media)));
    }
    return result;
  }

  Future<void> discard(int linkId) async {
    await _ref.read(trackerStoreForProvider(kind)).discard(linkId);
    _ref.invalidate(trackerQueueProvider(kind));
  }

  Future<void> disconnect() async {
    await _ref.read(trackerBackendProvider(kind)).logout(_profileId);
    refresh();
  }
}

final trackerActionsProvider = Provider.family<TrackerActions, TrackerKind>(
  (ref, kind) => TrackerActions(ref, kind),
);
