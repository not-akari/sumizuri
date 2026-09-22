import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/features/trackers/models/anilist_stats.dart';

/// The most chunks of a list read in one go, so a broken answer cannot loop forever.
const _maxChunks = 40;

final aniListStatsProvider = FutureProvider.autoDispose<AniListStats>((
  ref,
) async {
  final profileId = ref.watch(currentProfileIdProvider);
  final result = await ref.watch(aniListRepositoryProvider).stats(profileId);
  return switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw error,
  };
});

/// The whole list of one kind, as AniList has it, every chunk read.
final aniListEntriesProvider = FutureProvider.autoDispose
    .family<List<AniListListEntry>, AniListMediaType>((ref, type) async {
      final profileId = ref.watch(currentProfileIdProvider);
      final repository = ref.watch(aniListRepositoryProvider);
      final all = <AniListListEntry>[];
      for (var chunk = 1; chunk <= _maxChunks; chunk++) {
        final result = await repository.list(profileId, type, chunk: chunk);
        switch (result) {
          case Ok(:final value):
            all.addAll(value.entries);
            if (!value.hasNextChunk) return all;
          case Err(:final error):
            throw error;
        }
      }
      return all;
    });

/// What is waiting to be sent to AniList.
final aniListQueueProvider = FutureProvider.autoDispose<List<QueuedTitle>>((
  ref,
) {
  final profileId = ref.watch(currentProfileIdProvider);
  return ref.watch(trackerStoreProvider).queue(profileId);
});

/// Media ids of the titles already linked to a library entry.
final aniListLinkedProvider = FutureProvider.autoDispose<Set<int>>((ref) async {
  final profileId = ref.watch(currentProfileIdProvider);
  return (await ref.watch(trackerStoreProvider).linkedTitles(profileId)).keys
      .toSet();
});
