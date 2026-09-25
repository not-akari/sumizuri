import 'package:sumizuri/bootstrap/logging/app_logger.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_api_client.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_exceptions.dart';
import 'package:sumizuri/features/trackers/data/tracker_secure_store.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';

const _tag = 'mal';

const _fieldAccess = 'access_token';
const _fieldRefresh = 'refresh_token';
const _fieldExpires = 'expires_at';
const _fieldId = 'id';
const _fieldName = 'name';
const _fieldAvatar = 'avatar_url';
const _fields = [
  _fieldAccess,
  _fieldRefresh,
  _fieldExpires,
  _fieldId,
  _fieldName,
  _fieldAvatar,
];

/// Renew a login this long before it runs out, so a call never goes out with a dead token.
const _renewBefore = Duration(days: 1);

TrackerAccountInfo _account(String name, String? avatar) => TrackerAccountInfo(
  name: name,
  avatarUrl: avatar,
  profileUrl: 'https://myanimelist.net/profile/${Uri.encodeComponent(name)}',
);

/// The MyAnimeList login of each profile and the calls made with it.
class MalRepository {
  MalRepository(this._logger, {MalApiClient? api, TrackerSecureStore? store})
    : _api = api ?? MalApiClient(),
      _store = store ?? TrackerSecureStore('mal');

  final AppLogger _logger;
  final MalApiClient _api;
  final TrackerSecureStore _store;

  MalAuthSession? _session;
  final _renewing = <int, Future<String>>{};

  /// Starts a sign-in and gives the address to open. The `state` to expect back is [expectedState].
  String beginLogin() {
    final session = _api.beginAuth();
    _session = session;
    return session.url;
  }

  String? get expectedState => _session?.state;

  Future<TrackerAccountInfo?> currentAccount(int profileId) async {
    final name = await _store.read(profileId, _fieldName);
    if (name == null || await _store.read(profileId, _fieldAccess) == null) {
      return null;
    }
    return _account(name, await _store.read(profileId, _fieldAvatar));
  }

  Future<TrackerAccountInfo> completeLogin(int profileId, String code) async {
    final session = _session;
    if (session == null) throw MalTokenException('Start the login again.');
    // Kept until the login works, so a request that never arrived can be repeated.
    final tokens = await _api.exchangeCode(code, session.verifier);
    final user = await _api.fetchUser(tokens.accessToken);
    await _saveTokens(profileId, tokens);
    await _store.write(profileId, _fieldId, '${user.id}');
    await _store.write(profileId, _fieldName, user.name);
    final avatar = user.pictureUrl;
    if (avatar != null) await _store.write(profileId, _fieldAvatar, avatar);
    _session = null;
    _logger.info('Connected MyAnimeList as ${user.name}.', tag: _tag);
    return _account(user.name, avatar);
  }

  Future<void> logout(int profileId) => _store.clearAll(profileId, _fields);

  Future<void> _saveTokens(int profileId, MalTokens tokens) async {
    await _store.write(profileId, _fieldAccess, tokens.accessToken);
    await _store.write(profileId, _fieldRefresh, tokens.refreshToken);
    await _store.write(
      profileId,
      _fieldExpires,
      '${tokens.expiresAt.millisecondsSinceEpoch}',
    );
  }

  /// A token that works, renewed first when it is about to run out.
  Future<String> _token(int profileId, {bool forceRenew = false}) async {
    final access = await _store.read(profileId, _fieldAccess);
    if (access == null) throw MalTokenException('Connect MyAnimeList first.');
    final expires = int.tryParse(
      await _store.read(profileId, _fieldExpires) ?? '',
    );
    final due =
        expires != null &&
        DateTime.fromMillisecondsSinceEpoch(expires)
            .subtract(_renewBefore)
            .isBefore(DateTime.now());
    if (!forceRenew && !due) return access;
    // Two calls at once must not both spend the one refresh token.
    return _renewing[profileId] ??= _renew(profileId).whenComplete(() {
      _renewing.remove(profileId);
    });
  }

  Future<String> _renew(int profileId) async {
    final refresh = await _store.read(profileId, _fieldRefresh);
    if (refresh == null) throw MalTokenException();
    try {
      final tokens = await _api.refresh(refresh);
      await _saveTokens(profileId, tokens);
      return tokens.accessToken;
    } on MalTokenException {
      // Refused for good: what is stored no longer works.
      await logout(profileId);
      rethrow;
    }
  }

  /// Runs [call] with a working token, renewing it once when MyAnimeList refuses it.
  Future<T> withToken<T>(
    int profileId,
    Future<T> Function(MalApiClient api, String token) call,
  ) async {
    try {
      return await call(_api, await _token(profileId));
    } on MalTokenException {
      return call(_api, await _token(profileId, forceRenew: true));
    }
  }

  Future<String?> tokenOrNull(int profileId) async {
    try {
      return await _token(profileId);
    } on MalException {
      return null;
    }
  }

  Future<TrackerKindStats> animeStats(int profileId) async {
    final stats = await withToken(
      profileId,
      (api, t) => api.fetchAnimeStats(t),
    );
    return TrackerKindStats(
      count: stats.count,
      unitsDone: stats.episodes,
      days: stats.days,
      meanScore: stats.meanScore,
    );
  }

  Future<List<TrackerEntry>> list(int profileId, TrackerMedia media) =>
      withToken(profileId, (api, t) => api.fetchList(t, media));

  Future<List<TrackerSearchResult>> search(
    int profileId,
    TrackerMedia media,
    String query, {
    bool novel = false,
  }) => withToken(
    profileId,
    (api, t) => api.search(t, media, query, novel: novel),
  );

  Future<void> save(int profileId, TrackerEntryUpdate update) =>
      withToken(profileId, (api, t) => api.saveEntry(t, update));

  Future<void> delete(int profileId, TrackerMedia media, int mediaId) =>
      withToken(profileId, (api, t) => api.deleteEntry(t, media, mediaId));

  Future<TrackerRemoteState?> remoteState(
    int profileId,
    TrackerMedia media,
    int mediaId,
  ) => withToken(profileId, (api, t) => api.remoteState(t, media, mediaId));

  void cancelLogin() => _session = null;
}
