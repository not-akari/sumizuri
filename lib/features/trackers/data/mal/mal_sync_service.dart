import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_exceptions.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_repository.dart';
import 'package:sumizuri/features/trackers/data/tracker_progress_sync.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';

const _tag = 'mal';

/// How long a change waits before it is sent, so a run of chapters goes as one.
const malSendDelay = Duration(minutes: 15);

/// Sends the progress made on this device to MyAnimeList.
class MalSyncService {
  MalSyncService({
    required this._store,
    required this._repository,
    required this._logger,
    this._delay = malSendDelay,
    this._now = DateTime.now,
  });

  final TrackerStore _store;
  final MalRepository _repository;
  final AppLogger _logger;
  final Duration _delay;
  final DateTime Function() _now;

  final _running = <int>{};

  Future<void> flushAll({bool force = false}) async {
    for (final profileId in await _store.profilesWithPending()) {
      await flush(profileId, force: force);
    }
  }

  Future<TrackerFlushResult> flush(int profileId, {bool force = false}) async {
    if (!_running.add(profileId)) {
      return const TrackerFlushResult(TrackerFlushOutcome.postponed);
    }
    try {
      return await _flush(profileId, force);
    } finally {
      _running.remove(profileId);
    }
  }

  Future<TrackerFlushResult> _flush(int profileId, bool force) async {
    final waiting = await _store.pending(profileId);
    if (waiting.isEmpty) {
      return const TrackerFlushResult(TrackerFlushOutcome.nothingToSend);
    }
    final dueBefore = _now().subtract(_delay).millisecondsSinceEpoch;
    if (!force && waiting.first.firstQueuedAt > dueBefore) {
      return const TrackerFlushResult(TrackerFlushOutcome.notDueYet);
    }
    if (await _repository.tokenOrNull(profileId) == null) {
      return const TrackerFlushResult(TrackerFlushOutcome.noAccount);
    }

    var sent = 0;
    var failed = 0;
    try {
      for (final title in waiting) {
        final state = await _repository.remoteState(
          profileId,
          title.media,
          title.mediaId,
        );
        if (state == null) {
          // The title is gone from MyAnimeList. Retrying would never help.
          await _store.markFailed(
            title.linkId,
            maxSendAttempts,
            TrackerProblem.titleGone.name,
          );
          continue;
        }
        await _store.updateChapters(title.linkId, state.total);
        final update = planTrackerUpdate(
          media: title.media,
          mediaId: title.mediaId,
          localProgress: await _store.localProgress(title.libraryEntryId),
          remote: state,
          today: _now(),
        );
        if (update == null) {
          await _store.markSent(title.linkId, title.version);
          continue;
        }
        try {
          await _repository.save(profileId, update);
          await _store.markSent(title.linkId, title.version);
          sent++;
        } on MalRequestException catch (error) {
          await _store.markFailed(
            title.linkId,
            title.attempts,
            TrackerProblem.refused.name,
          );
          failed++;
          _logger.warning(
            'MyAnimeList refused title ${title.mediaId}: ${error.message}',
            tag: _tag,
          );
        }
      }
      _logger.info('MyAnimeList: $sent sent, $failed refused.', tag: _tag);
      return TrackerFlushResult(
        TrackerFlushOutcome.sent,
        sent: sent,
        failed: failed,
      );
    } on MalTokenException {
      return const TrackerFlushResult(TrackerFlushOutcome.loginExpired);
    } on MalRateLimitException {
      await _store.deferAll(profileId, _now().add(const Duration(minutes: 10)));
      return const TrackerFlushResult(TrackerFlushOutcome.postponed);
    } on MalException catch (error) {
      _logger.warning(
        'MyAnimeList batch postponed: ${error.message}',
        tag: _tag,
      );
      await _store.deferAll(profileId, _now().add(const Duration(minutes: 5)));
      return const TrackerFlushResult(TrackerFlushOutcome.postponed);
    }
  }
}
