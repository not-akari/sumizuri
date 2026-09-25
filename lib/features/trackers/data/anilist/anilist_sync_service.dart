import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_api_client.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_tracking_policy.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';

const _tag = 'anilist';

const aniListSendDelay = Duration(minutes: 15);

enum AniListFlushOutcome {
  nothingToSend,

  notDueYet,

  noAccount,

  loginExpired,

  postponed,

  sent,
}

class AniListFlushResult {
  const AniListFlushResult(this.outcome, {this.sent = 0, this.failed = 0});

  final AniListFlushOutcome outcome;

  final int sent;

  final int failed;
}

class AniListSyncService {
  AniListSyncService({
    required this._store,
    required this._api,
    required this._tokenFor,
    required this._logger,
    this._delay = aniListSendDelay,
    this._now = DateTime.now,
  });

  final TrackerStore _store;
  final AniListApiClient _api;
  final Future<String?> Function(int profileId) _tokenFor;
  final AppLogger _logger;
  final Duration _delay;
  final DateTime Function() _now;

  final _running = <int>{};

  Future<void> flushAll({bool force = false}) async {
    for (final profileId in await _store.profilesWithPending()) {
      await flush(profileId, force: force);
    }
  }

  Future<AniListFlushResult> flush(int profileId, {bool force = false}) async {
    if (!_running.add(profileId)) {
      return const AniListFlushResult(AniListFlushOutcome.postponed);
    }
    try {
      return await _flush(profileId, force);
    } finally {
      _running.remove(profileId);
    }
  }

  Future<AniListFlushResult> _flush(int profileId, bool force) async {
    final waiting = await _store.pending(profileId);
    if (waiting.isEmpty) {
      return const AniListFlushResult(AniListFlushOutcome.nothingToSend);
    }
    final dueBefore = _now().subtract(_delay).millisecondsSinceEpoch;
    if (!force && waiting.first.firstQueuedAt > dueBefore) {
      return const AniListFlushResult(AniListFlushOutcome.notDueYet);
    }
    final token = await _tokenFor(profileId);
    if (token == null) {
      return const AniListFlushResult(AniListFlushOutcome.noAccount);
    }

    try {
      final remote = await _api.remoteStates([
        for (final title in waiting) title.mediaId,
      ], token);

      final updates = <AniListEntryUpdate>[];
      final byMedia = <int, PendingTitle>{};
      for (final title in waiting) {
        final state = remote[title.mediaId];
        if (state == null) {
          // The title is gone from AniList (merged or deleted). Retrying would never help.
          await _store.markFailed(
            title.linkId,
            maxSendAttempts,
            TrackerProblem.titleGone.name,
          );
          continue;
        }
        await _store.updateChapters(title.linkId, state.chapters);
        final update = planAniListUpdate(
          mediaId: title.mediaId,
          localProgress: await _store.localProgress(title.libraryEntryId),
          remote: state,
          today: _now(),
        );
        if (update == null) {
          await _store.markSent(title.linkId, title.version);
        } else {
          updates.add(update);
          byMedia[title.mediaId] = title;
        }
      }

      var sent = 0;
      var failed = 0;
      if (updates.isNotEmpty) {
        final result = await _api.saveEntries(updates, token);
        for (final mediaId in result.saved.keys) {
          final title = byMedia[mediaId]!;
          await _store.markSent(title.linkId, title.version);
          sent += 1;
        }
        for (final failure in result.failed.entries) {
          final title = byMedia[failure.key]!;
          await _store.markFailed(title.linkId, title.attempts, failure.value);
          failed += 1;
          _logger.warning(
            'AniList refused title ${failure.key}: ${failure.value}',
            tag: _tag,
          );
        }
      }
      _logger.info('AniList batch: $sent sent, $failed refused.', tag: _tag);
      return AniListFlushResult(
        AniListFlushOutcome.sent,
        sent: sent,
        failed: failed,
      );
    } on AniListTokenException {
      return const AniListFlushResult(AniListFlushOutcome.loginExpired);
    } on AniListRateLimitException catch (error) {
      await _store.deferAll(profileId, _now().add(error.retryAfter));
      return const AniListFlushResult(AniListFlushOutcome.postponed);
    } on AniListException catch (error) {
      _logger.warning('AniList batch postponed: ${error.message}', tag: _tag);
      await _store.deferAll(profileId, _now().add(const Duration(minutes: 5)));
      return const AniListFlushResult(AniListFlushOutcome.postponed);
    }
  }
}
