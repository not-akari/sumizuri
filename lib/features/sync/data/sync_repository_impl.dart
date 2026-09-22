import 'package:drift/drift.dart';

import 'package:sumizuri/bootstrap/database/app_database.dart'
    show SyncProfileStateCompanion, SyncProfileStateData;
import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/guard_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/sync/data/sync_api_client.dart';
import 'package:sumizuri/features/sync/data/sync_credential_store.dart';
import 'package:sumizuri/features/sync/data/sync_local_store.dart';
import 'package:sumizuri/features/sync/flows/sync_oauth_flow.dart';
import 'package:sumizuri/features/sync/data/sync_page_applier.dart';
import 'package:sumizuri/features/sync/models/sync_models.dart';
import 'package:sumizuri/features/sync/data/sync_repository.dart';

const syncMaxRowsPerEntity = 5000;

const _localOverlapMs = 5000;

class SyncRepositoryImpl implements SyncRepository {
  SyncRepositoryImpl({
    required this._api,
    required this._oauth,
    required this._credentials,
    required this._local,
    required this._applier,
    required this._logger,
    this._now = DateTime.now,
  });

  final SyncApiClient _api;
  final SyncOAuthFlow _oauth;
  final SyncCredentialStore _credentials;
  final SyncLocalStore _local;
  final SyncPageApplier _applier;
  final AppLogger _logger;
  final DateTime Function() _now;

  static const _tag = 'sync';

  // Share of the interval that must have passed before a background wake syncs.
  static const _backgroundDueFraction = 0.9;

  @override
  Future<SyncAccount?> currentAccount() async {
    final account = await _credentials.readAccount();
    if (account == null) return null;
    if (await _credentials.readInstallId() != await _local.installId()) {
      await _credentials.clear();
      return null;
    }
    return account;
  }

  @override
  Future<SyncServerProfile?> linkedProfile() async {
    final state = await _local.readState(await _local.activeProfileId());
    final id = state.serverProfileId;
    if (id == null) return null;
    return SyncServerProfile(id: id, name: state.serverProfileName ?? '');
  }

  @override
  Future<int> lastSyncedAt() async =>
      (await _local.readState(await _local.activeProfileId())).lastSyncAt;

  @override
  Future<SyncPreferences> preferences() async {
    final state = await _local.readState(await _local.activeProfileId());
    return SyncPreferences(
      intervalMinutes: state.autoSyncIntervalMinutes,
      syncOnLaunch: state.syncOnLaunch,
      backgroundSync: state.backgroundSync,
    );
  }

  @override
  Future<List<int>> dueBackgroundProfiles() async {
    if (await currentAccount() == null) return const [];
    final now = _now().millisecondsSinceEpoch;
    return [
      for (final state in await _local.allStates())
        if (_opted(state) &&
            // The OS wakes the app on its own schedule, so a wake just before the interval counts.
            now - state.lastSyncAt >=
                state.autoSyncIntervalMinutes *
                    Duration.millisecondsPerMinute *
                    _backgroundDueFraction)
          state.profileId,
    ];
  }

  @override
  Future<int?> backgroundIntervalMinutes() async {
    if (await currentAccount() == null) return null;
    int? smallest;
    for (final state in await _local.allStates()) {
      if (!_opted(state)) continue;
      final minutes = state.autoSyncIntervalMinutes;
      if (smallest == null || minutes < smallest) smallest = minutes;
    }
    return smallest;
  }

  bool _opted(SyncProfileStateData state) =>
      state.serverProfileId != null &&
      state.backgroundSync &&
      state.autoSyncIntervalMinutes > 0;

  @override
  Future<void> setPreferences(SyncPreferences preferences) async {
    await _local.writeState(
      await _local.activeProfileId(),
      SyncProfileStateCompanion(
        autoSyncIntervalMinutes: Value(preferences.intervalMinutes),
        syncOnLaunch: Value(preferences.syncOnLaunch),
        backgroundSync: Value(preferences.backgroundSync),
      ),
    );
  }

  @override
  Future<Result<SyncAccount, AppFailure>> signIn(String server) =>
      _guard(() async {
        final session = await _oauth.authorize(server);
        return _saveSession(session.server, session.username, session.token);
      });

  Future<SyncAccount> _saveSession(
    String server,
    String username,
    String token,
  ) async {
    final account = SyncAccount(server: server, username: username);
    final previous = await currentAccount();
    if (previous?.server != account.server ||
        previous?.username != account.username) {
      await _local.clearAll();
    }
    await _credentials.save(
      account,
      token,
      installId: await _local.installId(),
    );
    return account;
  }

  @override
  Future<void> cancelSignIn() => _oauth.cancel();

  @override
  Future<void> signOut() async {
    await _credentials.clear();
    await _local.clearAll();
  }

  @override
  Future<Result<List<SyncServerProfile>, AppFailure>> listServerProfiles() =>
      _guard(() async {
        final (account, token) = await _requireSession();
        return _api.listProfiles(account.server, token);
      });

  @override
  Future<Result<void, AppFailure>> linkProfile(SyncServerProfile profile) =>
      _guard(() async {
        await _link(profile);
      });

  @override
  Future<Result<SyncServerProfile, AppFailure>> createAndLinkProfile(
    String name,
  ) => _guard(() async {
    final (account, token) = await _requireSession();
    final created = await _api.createProfile(account.server, token, name);
    await _link(created);
    return created;
  });

  @override
  Future<void> unlinkProfile() async {
    await _local.clearProfile(await _local.activeProfileId());
  }

  Future<void> _link(SyncServerProfile profile) async {
    await _local.writeState(
      await _local.activeProfileId(),
      SyncProfileStateCompanion(
        serverProfileId: Value(profile.id),
        serverProfileName: Value(profile.name),
        since: const Value(0),
        localSince: const Value(0),
        lastSyncAt: const Value(0),
      ),
    );
  }

  Future<(SyncAccount, String)> _requireSession() async {
    final account = await currentAccount();
    final token = await _credentials.readToken();
    if (account == null || token == null) {
      throw const SyncApiException('Sign in to a sync server first.');
    }
    return (account, token);
  }

  @override
  Future<void> forgetProfile(int profileId) async {
    await _local.clearProfile(profileId);
  }

  @override
  Future<Result<void, AppFailure>> sync(
    SyncMode mode, {
    void Function(SyncProgress progress)? onProgress,
    int? profileId,
  }) => _guard(() async {
    // Captured once: switching profiles mid-sync must not change whose data this is.
    final target = profileId ?? await _local.activeProfileId();
    final serverProfileId = (await _local.readState(target)).serverProfileId;
    if (serverProfileId == null) {
      throw const SyncApiException('This profile is not set up to sync.');
    }
    final (account, token) = await _requireSession();
    await _api.checkVersion(account.server);
    await _run(target, serverProfileId, account, token, mode, onProgress);
  });

  Future<void> _run(
    int profileId,
    int serverProfileId,
    SyncAccount account,
    String token,
    SyncMode mode,
    void Function(SyncProgress progress)? onProgress,
  ) async {
    final started = _now().millisecondsSinceEpoch;
    final state = await _local.readState(profileId);

    final since = mode == SyncMode.downloadOnly ? 0 : state.since;
    final upload = switch (mode) {
      SyncMode.downloadOnly => null,
      SyncMode.uploadOnly => await _local.collect(
        profileId: profileId,
        since: 0,
        forceUpdatedAt: started,
      ),
      SyncMode.incremental => await _local.collect(
        profileId: profileId,
        since: state.localSince,
      ),
    };
    final chunks = upload == null ? [<String, dynamic>{}] : _chunk(upload);

    var done = 0;
    var total = chunks.length;
    void report() => onProgress?.call(SyncProgress(done: done, total: total));

    final pending = SyncPending();
    if (upload != null) {
      for (final entry in upload.rows.entries) {
        pending.uploaded[entry.key] = {
          for (final row in entry.value) row['clientId'] as int,
        };
      }
    }
    Map<String, dynamic>? cursors;
    String? sessionToken;
    var next = 0;

    while (true) {
      final body = <String, dynamic>{
        'profileId': serverProfileId,
        'since': since,
        'sessionToken': ?sessionToken,
        'cursors': ?cursors,
        if (next < chunks.length) ...chunks[next],
      };
      if (next < chunks.length) next += 1;

      final response = await _api.sync(account.server, token, body);
      done += _countPulled(response);
      total += _countTotals(response);
      report();

      await _applier.apply(response, pending, profileId);
      sessionToken = response['sessionToken'] as String?;
      cursors = (response['cursors'] as Map?)?.cast<String, dynamic>();

      final hasMore = response['hasMore'] == true;
      if (next >= chunks.length && !hasMore) {
        final syncedAt = response['syncedAt'] as int?;
        if (syncedAt != null) {
          await _applier.finish(pending, profileId);
          await _finish(profileId, mode, syncedAt, started, upload);
        }
        if (pending.orphans.isNotEmpty) {
          _logger.warning(
            '${pending.orphans.length} synced rows pointed at rows the server does not have',
            tag: _tag,
          );
        }
        return;
      }
    }
  }

  Future<void> _finish(
    int profileId,
    SyncMode mode,
    int syncedAt,
    int started,
    SyncUpload? upload,
  ) async {
    final finished = _now().millisecondsSinceEpoch;
    if (mode == SyncMode.downloadOnly) {
      // Must not move the upload window, or local edits made before it would never be sent.
      await _local.writeState(
        profileId,
        SyncProfileStateCompanion(
          since: Value(syncedAt),
          lastSyncAt: Value(finished),
        ),
      );
      return;
    }
    await _local.writeState(
      profileId,
      SyncProfileStateCompanion(
        since: Value(syncedAt),
        localSince: Value(started - _localOverlapMs),
        lastSyncAt: Value(finished),
      ),
    );
    if (upload != null) await _local.commitUpload(profileId, upload);
  }

  List<Map<String, dynamic>> _chunk(SyncUpload upload) {
    final fileChunks = _fileChunks(upload.rows['files'] ?? const []);
    var count = fileChunks.length;
    for (final entry in upload.rows.entries) {
      if (entry.key == 'files') continue;
      final needed = (entry.value.length / syncMaxRowsPerEntity).ceil();
      if (needed > count) count = needed;
    }
    if (count == 0) count = 1;
    return [
      for (var i = 0; i < count; i++)
        {
          for (final entity in syncEntities)
            if (entity != 'files' && _slice(upload.rows[entity], i).isNotEmpty)
              entity: _slice(upload.rows[entity], i),
          if (i < fileChunks.length) 'files': fileChunks[i],
          if (i == 0 && upload.deleted.isNotEmpty) 'deleted': upload.deleted,
        },
    ];
  }

  List<List<Map<String, dynamic>>> _fileChunks(
    List<Map<String, dynamic>> files,
  ) {
    const budgetChars = 10 * 1024 * 1024;
    final chunks = <List<Map<String, dynamic>>>[];
    var current = <Map<String, dynamic>>[];
    var size = 0;
    for (final file in files) {
      final length = (file['data'] as String).length;
      if (current.isNotEmpty && size + length > budgetChars) {
        chunks.add(current);
        current = [];
        size = 0;
      }
      current.add(file);
      size += length;
    }
    if (current.isNotEmpty) chunks.add(current);
    return chunks;
  }

  List<Map<String, dynamic>> _slice(List<Map<String, dynamic>>? rows, int i) {
    if (rows == null) return const [];
    final start = i * syncMaxRowsPerEntity;
    if (start >= rows.length) return const [];
    final end = start + syncMaxRowsPerEntity;
    return rows.sublist(start, end > rows.length ? rows.length : end);
  }

  int _countPulled(Map<String, dynamic> response) {
    var rows = 0;
    for (final entity in syncEntities) {
      rows += (response[entity] as List?)?.length ?? 0;
    }
    return rows;
  }

  int _countTotals(Map<String, dynamic> response) {
    final totals = response['totalCounts'] as Map?;
    if (totals == null) return 0;
    return totals.values.fold<int>(0, (sum, v) => sum + (v as int));
  }

  Future<Result<T, AppFailure>> _guard<T>(Future<T> Function() action) async {
    final result = await guardFailure(_logger, _tag, action);
    // guardFailure turns every exception into a generic failure.
    final cause = result.errorOrNull?.cause;
    if (cause is SyncApiException) {
      return Err(NetworkFailure(cause.message, cause: cause));
    }
    return result;
  }
}
