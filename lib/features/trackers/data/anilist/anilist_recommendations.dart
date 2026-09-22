// Finds suggestions from AniList for an entry.
import 'package:sumizuri/features/library/migration/match_scoring.dart';
import 'package:sumizuri/features/library/models/library_types.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_api_client.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';

/// Finds recommendations for [title], preferring existing linked tracker.
Future<List<AniListMedia>> findAniListRecommendations({
  required AniListApiClient api,
  required String title,
  required MediaType mediaType,
  TrackerStore? trackerStore,
  int? libraryEntryId,
}) async {
  final mediaId = await _resolveMediaId(
    api: api,
    trackerStore: trackerStore,
    title: title,
    mediaType: mediaType,
    libraryEntryId: libraryEntryId,
  );
  if (mediaId == null) return const [];
  try {
    return await api.mediaRecommendations(mediaId);
  } on Object {
    return const [];
  }
}

Future<int?> _resolveMediaId({
  required AniListApiClient api,
  required TrackerStore? trackerStore,
  required String title,
  required MediaType mediaType,
  int? libraryEntryId,
}) async {
  if (libraryEntryId != null && trackerStore != null) {
    final link = await trackerStore.linkFor(libraryEntryId);
    if (link != null) return link.mediaId;
  }

  try {
    final page = await api.searchMedia(
      title,
      type: mediaType == MediaType.anime
          ? AniListMediaType.anime
          : AniListMediaType.manga,
      novel: mediaType == MediaType.novel,
      perPage: 5,
    );
    AniListMedia? best;
    var bestScore = 0.0;
    for (final candidate in page.results) {
      final score = titleSimilarity(title, candidate.title.display);
      if (score > bestScore) {
        bestScore = score;
        best = candidate;
      }
    }
    return bestScore >= reviewThreshold ? best?.id : null;
  } on Object {
    return null;
  }
}
