import 'dart:async';

import 'package:sumizuri/features/trackers/data/login_support.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_api_client.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_exceptions.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_repository.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_sync_service.dart';
import 'package:sumizuri/features/trackers/data/oauth_loopback_listener.dart';
import 'package:sumizuri/features/trackers/data/tracker_backend.dart';
import 'package:sumizuri/features/trackers/data/tracker_client_config.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';

TrackerException malProblem(Object error) {
  if (error is! MalException) {
    return TrackerException(
      TrackerProblem.unknown,
      TrackerKind.mal,
      cause: error,
    );
  }
  final problem = switch (error) {
    MalTokenException() => TrackerProblem.loginExpired,
    MalNotFoundException() => TrackerProblem.notFound,
    MalRateLimitException() => TrackerProblem.busy,
    MalNetworkException() => TrackerProblem.network,
    MalSearchTooShortException() => TrackerProblem.searchTooShort,
    MalRequestException() => TrackerProblem.refused,
  };
  return TrackerException(
    problem,
    TrackerKind.mal,
    status: error is MalRequestException ? error.status : null,
    cause: error,
  );
}

class MalBackend implements TrackerBackend {
  MalBackend({required this.repository, required this.sync});

  final MalRepository repository;
  final MalSyncService sync;

  OAuthLoopbackListener? _listener;

  @override
  TrackerKind get kind => TrackerKind.mal;

  @override
  bool get configured => malConfigured;

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on MalException catch (error) {
      throw malProblem(error);
    }
  }

  @override
  Future<TrackerAccountInfo?> account(int profileId) =>
      repository.currentAccount(profileId);

  @override
  Future<TrackerStats> stats(
    int profileId,
    Future<List<TrackerEntry>> Function(TrackerMedia media) entries,
  ) => _guard(() async {
    final anime = await repository.animeStats(profileId);
    // MyAnimeList has no numbers for the manga list, so they come from the list.
    final manga = await entries(TrackerMedia.manga);
    final scored = [
      for (final entry in manga)
        if (entry.score > 0) entry.score,
    ];
    return TrackerStats(
      anime: anime,
      manga: TrackerKindStats(
        count: manga.length,
        unitsDone: manga.fold(0, (sum, entry) => sum + entry.progress),
        meanScore: scored.isEmpty
            ? 0
            : scored.reduce((a, b) => a + b) / scored.length / 10,
      ),
    );
  });

  @override
  Future<List<TrackerEntry>> entries(int profileId, TrackerMedia media) =>
      _guard(() => repository.list(profileId, media));

  @override
  Future<List<TrackerSearchResult>> search(
    int profileId,
    String query, {
    required TrackerMedia media,
    bool novel = false,
  }) => _guard(() => repository.search(profileId, media, query, novel: novel));

  @override
  Future<TrackerRemoteState?> remote(
    int profileId,
    TrackerMedia media,
    int mediaId,
  ) => _guard(() => repository.remoteState(profileId, media, mediaId));

  @override
  Future<void> save(int profileId, TrackerEntryUpdate update) =>
      _guard(() => repository.save(profileId, update));

  @override
  Future<void> remove(int profileId, TrackerEntry entry) =>
      _guard(() => repository.delete(profileId, entry.media, entry.mediaId));

  @override
  Future<TrackerAccountInfo?> login(
    int profileId, {
    required OAuthPageText page,
  }) async {
    if (!configured) {
      throw const TrackerException(
        TrackerProblem.notConfigured,
        TrackerKind.mal,
      );
    }
    final listener = OAuthLoopbackListener(
      port: malLoopbackPort,
      path: malLoopbackPath,
      page: page,
    );
    _listener = listener;
    try {
      final url = repository.beginLogin();
      return await runLoopbackLogin(
        listener: listener,
        authorizeUrl: url,
        state: repository.expectedState,
        complete: (code) =>
            _guard(() => repository.completeLogin(profileId, code)),
      );
    } finally {
      _listener = null;
    }
  }

  @override
  void cancelLogin() {
    repository.cancelLogin();
    unawaited(_listener?.cancel());
  }

  @override
  Future<void> logout(int profileId) => repository.logout(profileId);

  @override
  Future<TrackerFlushResult> flush(int profileId, {bool force = false}) =>
      sync.flush(profileId, force: force);

  @override
  Future<void> flushAll({bool force = false}) => sync.flushAll(force: force);
}
