import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/trackers/models/anilist_account.dart';
import 'package:sumizuri/features/trackers/data/anilist_repository.dart';
import 'package:sumizuri/features/trackers/data/tracker_secure_store.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_api_client.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_graphql.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/features/trackers/models/anilist_stats.dart';

const _tag = 'anilist';
const aniListTokenField = 'access_token';
const _fieldToken = aniListTokenField;
const _fieldId = 'id';
const _fieldName = 'name';
const _fieldAvatar = 'avatar_url';
const _fields = [_fieldToken, _fieldId, _fieldName, _fieldAvatar];

class AniListRepositoryImpl implements AniListRepository {
  AniListRepositoryImpl(
    this._logger, {
    AniListApiClient? apiClient,
    TrackerSecureStore? store,
  }) : _api = apiClient ?? AniListApiClient(),
       _store = store ?? TrackerSecureStore('anilist');

  final AppLogger _logger;
  final AniListApiClient _api;
  final TrackerSecureStore _store;

  @override
  String buildAuthorizeUrl() => _api.buildAuthorizeUrl();

  @override
  Future<AniListAccount?> currentAccount(int profileId) async {
    final id = await _store.read(profileId, _fieldId);
    final name = await _store.read(profileId, _fieldName);
    if (id == null || name == null) return null;
    final avatarUrl = await _store.read(profileId, _fieldAvatar);
    return AniListAccount(id: int.parse(id), name: name, avatarUrl: avatarUrl);
  }

  @override
  Future<Result<AniListAccount, AppFailure>> completeLogin(
    int profileId, {
    required String code,
  }) async {
    try {
      final token = await _api.exchangeCode(code);
      final info = await _api.fetchViewer(token);
      await _store.write(profileId, _fieldToken, token);
      await _store.write(profileId, _fieldId, info.id.toString());
      await _store.write(profileId, _fieldName, info.name);
      final avatarUrl = info.avatarUrl;
      if (avatarUrl != null) {
        await _store.write(profileId, _fieldAvatar, avatarUrl);
      }
      return Ok(
        AniListAccount(id: info.id, name: info.name, avatarUrl: avatarUrl),
      );
    } on AniListException catch (error) {
      _logger.error(error.message, tag: _tag, error: error);
      return Err(_failureFor(error));
    } on AniListAuthException catch (error) {
      _logger.error(error.message, tag: _tag, error: error);
      return Err(SecurityFailure(error.message));
    } catch (error, stackTrace) {
      _logger.error(
        'AniList login failed',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      return const Err(
        NetworkFailure('Could not reach AniList. Check your connection.'),
      );
    }
  }

  @override
  Future<void> logout(int profileId) async {
    _api.cancelPending();
    await _store.clearAll(profileId, _fields);
  }

  // Runs a call against AniList and maps what can go wrong to the app's failures.
  Future<Result<T, AppFailure>> _call<T>(Future<T> Function() action) async {
    try {
      return Ok(await action());
    } on AniListException catch (error) {
      _logger.warning(error.message, tag: _tag);
      return Err(_failureFor(error));
    } catch (error, stackTrace) {
      _logger.error(
        'AniList request failed',
        tag: _tag,
        error: error,
        stackTrace: stackTrace,
      );
      return const Err(
        UnknownFailure('Something went wrong talking to AniList.'),
      );
    }
  }

  AppFailure _failureFor(AniListException error) => switch (error) {
    AniListTokenException() => SecurityFailure(error.message, cause: error),
    AniListNotFoundException() => NotFoundFailure(error.message, cause: error),
    AniListRateLimitException() ||
    AniListNetworkException() => NetworkFailure(error.message, cause: error),
    AniListRequestException() => UnknownFailure(error.message, cause: error),
  };

  Future<String> _requireToken(int profileId) async {
    final token = await _store.read(profileId, _fieldToken);
    if (token == null) throw AniListTokenException('Log in to AniList first.');
    return token;
  }

  @override
  Future<Result<AniListSearchPage, AppFailure>> search(
    int profileId,
    String query, {
    required AniListMediaType type,
    bool novel = false,
    int page = 1,
  }) => _call(
    () async => _api.searchMedia(
      query.trim(),
      type: type,
      novel: novel,
      page: page,
      token: await _store.read(profileId, _fieldToken),
    ),
  );

  @override
  Future<Result<AniListMedia, AppFailure>> media(int profileId, int mediaId) =>
      _call(
        () async =>
            _api.mediaWithEntry(mediaId, await _requireToken(profileId)),
      );

  @override
  Future<Result<AniListStats, AppFailure>> stats(int profileId) =>
      _call(() async => _api.fetchStats(await _requireToken(profileId)));

  @override
  Future<Result<AniListListPage, AppFailure>> list(
    int profileId,
    AniListMediaType type, {
    int chunk = 1,
  }) => _call(() async {
    final token = await _requireToken(profileId);
    final id = await _store.read(profileId, _fieldId);
    if (id == null) throw AniListTokenException('Log in to AniList first.');
    return _api.userList(int.parse(id), type, token, chunk: chunk);
  });

  @override
  Future<Result<AniListListEntry, AppFailure>> saveEntry(
    int profileId,
    AniListEntryUpdate update,
  ) =>
      _call(() async => _api.saveEntry(update, await _requireToken(profileId)));

  @override
  Future<Result<void, AppFailure>> deleteEntry(int profileId, int entryId) =>
      _call(
        () async => _api.deleteEntry(entryId, await _requireToken(profileId)),
      );
}
