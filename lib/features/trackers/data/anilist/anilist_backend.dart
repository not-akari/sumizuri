import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_api_client.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_sync_service.dart';
import 'package:sumizuri/features/trackers/data/login_support.dart';
import 'package:sumizuri/features/trackers/data/oauth_loopback_listener.dart';
import 'package:sumizuri/features/trackers/data/tracker_backend.dart';
import 'package:sumizuri/features/trackers/data/tracker_client_config.dart';
import 'package:sumizuri/features/trackers/models/anilist_account.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/features/trackers/models/anilist_stats.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';
import 'package:sumizuri/features/trackers/providers/anilist_providers.dart';

/// The most chunks of a list read in one go, so a broken answer cannot loop forever.
const _maxChunks = 40;

TrackerDate? _date(AniListFuzzyDate? date) => date == null
    ? null
    : TrackerDate(year: date.year, month: date.month, day: date.day);

AniListFuzzyDate? _fuzzy(TrackerDate? date) => date == null
    ? null
    : AniListFuzzyDate(year: date.year, month: date.month, day: date.day);

TrackerKindStats _kindStats(AniListKindStats stats) => TrackerKindStats(
  count: stats.count,
  // AniList scores the mean out of 100.
  meanScore: stats.meanScore / 10,
  unitsDone: stats.unitsDone,
  days: stats.daysWatched,
);

/// A list entry of AniList as the neutral entry every tracker page shows.
TrackerEntry aniListToTracker(AniListListEntry entry) {
  final media = entry.media;
  final anime = media?.type == AniListMediaType.anime;
  final total = anime ? media?.episodes : media?.chapters;
  return TrackerEntry(
    tracker: TrackerKind.anilist,
    mediaId: entry.mediaId,
    entryId: entry.id,
    media: anime ? TrackerMedia.anime : TrackerMedia.manga,
    isNovel: media?.isNovel ?? false,
    title: media?.title.display ?? '#${entry.mediaId}',
    coverUrl: media?.coverUrl,
    status: entry.status == null
        ? null
        : TrackerStatus.values.byName(entry.status!.name),
    progress: entry.progress,
    total: total != null && total > 0 ? total : null,
    score: entry.score,
    startedAt: _date(entry.startedAt),
    completedAt: _date(entry.completedAt),
    siteUrl:
        media?.siteUrl ??
        'https://anilist.co/${anime ? 'anime' : 'manga'}/${entry.mediaId}',
    synonyms: [
      media?.title.romaji,
      media?.title.native,
      ...?media?.synonyms,
    ].whereType<String>().toList(),
  );
}

class AniListBackend implements TrackerBackend {
  AniListBackend(this._ref);

  final Ref _ref;
  OAuthLoopbackListener? _listener;

  @override
  TrackerKind get kind => TrackerKind.anilist;

  @override
  bool get configured => aniListConfigured;

  T _unwrap<T>(Result<T, AppFailure> result) => switch (result) {
    Ok(:final value) => value,
    Err(:final error) => throw _problem(error),
  };

  /// What AniList's repository reported, as a problem the page can put in words.
  TrackerException _problem(AppFailure failure) {
    final cause = failure.cause;
    final problem = switch (cause) {
      AniListTokenException() => TrackerProblem.loginExpired,
      AniListNotFoundException() => TrackerProblem.notFound,
      AniListRateLimitException() => TrackerProblem.busy,
      AniListNetworkException() => TrackerProblem.network,
      AniListRequestException() => TrackerProblem.refused,
      _ => switch (failure) {
        NetworkFailure() => TrackerProblem.network,
        SecurityFailure() => TrackerProblem.loginFailed,
        NotFoundFailure() => TrackerProblem.notFound,
        _ => TrackerProblem.unknown,
      },
    };
    return TrackerException(
      problem,
      TrackerKind.anilist,
      status: cause is AniListRequestException ? cause.status : null,
      cause: failure,
    );
  }

  @override
  Future<TrackerAccountInfo?> account(int profileId) async {
    final AniListAccount? account = await _ref.read(
      aniListAccountProvider.future,
    );
    return account == null ? null : _info(account);
  }

  TrackerAccountInfo _info(AniListAccount account) => TrackerAccountInfo(
    name: account.name,
    avatarUrl: account.avatarUrl,
    profileUrl: 'https://anilist.co/user/${account.name}',
  );

  @override
  Future<TrackerStats> stats(
    int profileId,
    Future<List<TrackerEntry>> Function(TrackerMedia media) entries,
  ) async {
    final AniListStats stats = _unwrap(
      await _ref.read(aniListRepositoryProvider).stats(profileId),
    );
    return TrackerStats(
      anime: _kindStats(stats.anime),
      manga: _kindStats(stats.manga),
    );
  }

  @override
  Future<List<TrackerEntry>> entries(int profileId, TrackerMedia media) async {
    final repository = _ref.read(aniListRepositoryProvider);
    final type = media == TrackerMedia.anime
        ? AniListMediaType.anime
        : AniListMediaType.manga;
    final all = <TrackerEntry>[];
    for (var chunk = 1; chunk <= _maxChunks; chunk++) {
      final page = _unwrap(
        await repository.list(profileId, type, chunk: chunk),
      );
      all.addAll(page.entries.map(aniListToTracker));
      if (!page.hasNextChunk) break;
    }
    return all;
  }

  @override
  Future<List<TrackerSearchResult>> search(
    int profileId,
    String query, {
    required TrackerMedia media,
    bool novel = false,
  }) async {
    final page = _unwrap(
      await _ref
          .read(aniListRepositoryProvider)
          .search(
            profileId,
            query,
            type: media == TrackerMedia.anime
                ? AniListMediaType.anime
                : AniListMediaType.manga,
            novel: novel,
          ),
    );
    return [
      for (final found in page.results)
        TrackerSearchResult(
          mediaId: found.id,
          title: found.title.display,
          coverUrl: found.coverUrl,
          subtitle: [
            ?found.format,
            if (found.startYear != null) '${found.startYear}',
          ].join(' · '),
          total: found.chapters ?? found.episodes,
        ),
    ];
  }

  @override
  Future<TrackerRemoteState?> remote(
    int profileId,
    TrackerMedia media,
    int mediaId,
  ) async {
    final Result<AniListMedia, AppFailure> result = await _ref
        .read(aniListRepositoryProvider)
        .media(profileId, mediaId);
    if (result case Err(:final error) when error is NotFoundFailure) {
      return null;
    }
    final found = _unwrap(result);
    final mine = found.entry;
    final total = found.chapters ?? found.episodes;
    return TrackerRemoteState(
      total: total != null && total > 0 ? total : null,
      entry: mine == null
          ? null
          : aniListToTracker(
              AniListListEntry(
                id: mine.id,
                mediaId: mine.mediaId,
                status: mine.status,
                progress: mine.progress,
                score: mine.score,
                startedAt: mine.startedAt,
                completedAt: mine.completedAt,
                media: found,
              ),
            ),
    );
  }

  @override
  Future<void> save(int profileId, TrackerEntryUpdate update) async {
    _unwrap(
      await _ref
          .read(aniListRepositoryProvider)
          .saveEntry(
            profileId,
            AniListEntryUpdate(
              mediaId: update.mediaId,
              status: update.status == null
                  ? null
                  : AniListListStatus.values.byName(update.status!.name),
              progress: update.progress,
              score: update.score,
              startedAt: _fuzzy(update.startedAt),
              completedAt: _fuzzy(update.completedAt),
            ),
          ),
    );
  }

  @override
  Future<void> remove(int profileId, TrackerEntry entry) async {
    final id = entry.entryId;
    if (id == null) return;
    _unwrap(
      await _ref.read(aniListRepositoryProvider).deleteEntry(profileId, id),
    );
  }

  @override
  Future<TrackerAccountInfo?> login(
    int profileId, {
    required OAuthPageText page,
  }) async {
    if (!configured) {
      throw const TrackerException(
        TrackerProblem.notConfigured,
        TrackerKind.anilist,
      );
    }
    final notifier = _ref.read(aniListAccountProvider.notifier);
    final listener = OAuthLoopbackListener(
      port: aniListLoopbackPort,
      path: '/anilist-callback',
      page: page,
    );
    _listener = listener;
    try {
      return await runLoopbackLogin(
        listener: listener,
        authorizeUrl: notifier.buildAuthorizeUrl(),
        complete: (code) async =>
            _info(_unwrap(await notifier.completeLogin(code))),
      );
    } finally {
      _listener = null;
    }
  }

  @override
  void cancelLogin() => unawaited(_listener?.cancel());

  @override
  Future<void> logout(int profileId) =>
      _ref.read(aniListAccountProvider.notifier).logout();

  TrackerFlushResult _flushResult(AniListFlushResult result) =>
      TrackerFlushResult(
        switch (result.outcome) {
          AniListFlushOutcome.nothingToSend =>
            TrackerFlushOutcome.nothingToSend,
          AniListFlushOutcome.notDueYet => TrackerFlushOutcome.notDueYet,
          AniListFlushOutcome.noAccount => TrackerFlushOutcome.noAccount,
          AniListFlushOutcome.loginExpired => TrackerFlushOutcome.loginExpired,
          AniListFlushOutcome.postponed => TrackerFlushOutcome.postponed,
          AniListFlushOutcome.sent => TrackerFlushOutcome.sent,
        },
        sent: result.sent,
        failed: result.failed,
      );

  @override
  Future<TrackerFlushResult> flush(int profileId, {bool force = false}) async =>
      _flushResult(
        await _ref
            .read(aniListSyncServiceProvider)
            .flush(profileId, force: force),
      );

  @override
  Future<void> flushAll({bool force = false}) =>
      _ref.read(aniListSyncServiceProvider).flushAll(force: force);
}
