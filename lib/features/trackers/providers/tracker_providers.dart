import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_backend.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_backend.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_repository.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_sync_service.dart';
import 'package:sumizuri/features/trackers/data/tracker_backend.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';

final malRepositoryProvider = Provider<MalRepository>(
  (ref) => MalRepository(ref.watch(appLoggerProvider)),
);

/// The links and outbox of one tracker.
final trackerStoreForProvider = Provider.family<TrackerStore, TrackerKind>(
  (ref, kind) => kind == TrackerKind.anilist
      ? ref.watch(trackerStoreProvider)
      : TrackerStore(ref.watch(appDatabaseProvider), tracker: kind.id),
);

/// Everything the tracker pages ask of a tracker, behind one door.
final trackerBackendProvider = Provider.family<TrackerBackend, TrackerKind>(
  (ref, kind) => switch (kind) {
    TrackerKind.anilist => AniListBackend(ref),
    TrackerKind.mal => MalBackend(
      repository: ref.watch(malRepositoryProvider),
      sync: MalSyncService(
        store: ref.watch(trackerStoreForProvider(TrackerKind.mal)),
        repository: ref.watch(malRepositoryProvider),
        logger: ref.watch(appLoggerProvider),
      ),
    ),
  },
);

/// Who is connected on the tracker, or null.
final trackerAccountProvider = FutureProvider.autoDispose
    .family<TrackerAccountInfo?, TrackerKind>((ref, kind) async {
      final profileId = ref.watch(currentProfileIdProvider);
      // AniList's login lives in a notifier that also feeds other screens.
      if (kind == TrackerKind.anilist) {
        await ref.watch(aniListAccountProvider.future);
      }
      return ref.watch(trackerBackendProvider(kind)).account(profileId);
    });

/// The whole list of one kind, as the tracker has it.
final trackerEntriesProvider = FutureProvider.autoDispose
    .family<List<TrackerEntry>, (TrackerKind, TrackerMedia)>((ref, key) {
      final profileId = ref.watch(currentProfileIdProvider);
      return ref
          .watch(trackerBackendProvider(key.$1))
          .entries(profileId, key.$2);
    });

final trackerStatsProvider = FutureProvider.autoDispose
    .family<TrackerStats, TrackerKind>((ref, kind) {
      final profileId = ref.watch(currentProfileIdProvider);
      return ref
          .watch(trackerBackendProvider(kind))
          .stats(
            profileId,
            (media) => ref.watch(trackerEntriesProvider((kind, media)).future),
          );
    });

/// What is waiting to be sent to the tracker.
final trackerQueueProvider = FutureProvider.autoDispose
    .family<List<QueuedTitle>, TrackerKind>((ref, kind) {
      final profileId = ref.watch(currentProfileIdProvider);
      return ref.watch(trackerStoreForProvider(kind)).queue(profileId);
    });

/// The titles already linked to a library entry, by list and id.
final trackerLinkedProvider = FutureProvider.autoDispose
    .family<Set<TrackerTitleKey>, TrackerKind>((ref, kind) async {
      final profileId = ref.watch(currentProfileIdProvider);
      return (await ref
              .watch(trackerStoreForProvider(kind))
              .linkedTitles(profileId))
          .keys
          .toSet();
    });
