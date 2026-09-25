import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;

import 'package:sumizuri/features/trackers/data/mal/mal_exceptions.dart';
import 'package:sumizuri/features/trackers/data/mal/mal_mapping.dart';
import 'package:sumizuri/features/trackers/data/tracker_client_config.dart';
import 'package:sumizuri/features/trackers/models/tracker_models.dart';

const _authorizeUrl = 'https://myanimelist.net/v1/oauth2/authorize';
const _tokenUrl = 'https://myanimelist.net/v1/oauth2/token';
const _apiBase = 'https://api.myanimelist.net/v2';

// MyAnimeList matches the redirect exactly, so the port and path are fixed.
// One above AniList's loopback port, so the two never collide.
const malLoopbackPort = 48766;
const malLoopbackPath = '/mal-callback';
const malRedirectUri = 'http://localhost:$malLoopbackPort$malLoopbackPath';

/// The most a page of a list can hold.
const _pageSize = 500;

/// A gap between requests. MyAnimeList does not publish its limit and answers
/// a burst with an error, so requests go one at a time.
const _requestGap = Duration(milliseconds: 350);

class MalTokens {
  const MalTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
  });

  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
}

/// One sign-in in progress: where to send the person, and what proves it was us.
class MalAuthSession {
  const MalAuthSession({
    required this.url,
    required this.verifier,
    required this.state,
  });

  final String url;
  final String verifier;
  final String state;
}

class MalUser {
  const MalUser({required this.id, required this.name, this.pictureUrl});

  final int id;
  final String name;
  final String? pictureUrl;
}

/// What MyAnimeList says about the anime list of the account.
class MalAnimeStats {
  const MalAnimeStats({
    this.count = 0,
    this.episodes = 0,
    this.days = 0,
    this.meanScore = 0,
  });

  final int count;
  final int episodes;
  final double days;
  final double meanScore;
}

class MalApiClient {
  MalApiClient({http.Client? client, Random? random})
    : _client = client ?? http.Client(),
      _random = random ?? Random.secure();

  final http.Client _client;
  final Random _random;

  var _last = DateTime.fromMillisecondsSinceEpoch(0);
  Future<void> _turn = Future.value();

  String _randomString(int length) {
    const alphabet =
        'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~';
    return List.generate(
      length,
      (_) => alphabet[_random.nextInt(alphabet.length)],
    ).join();
  }

  /// Starts a sign-in. MyAnimeList takes only the `plain` PKCE method, so the
  /// challenge is the verifier itself.
  MalAuthSession beginAuth() {
    final verifier = _randomString(96);
    final state = _randomString(24);
    final url = Uri.parse(_authorizeUrl).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': malClientId,
        'code_challenge': verifier,
        'code_challenge_method': 'plain',
        'state': state,
        'redirect_uri': malRedirectUri,
      },
    );
    return MalAuthSession(
      url: url.toString(),
      verifier: verifier,
      state: state,
    );
  }

  Future<MalTokens> exchangeCode(String code, String verifier) => _token({
    'grant_type': 'authorization_code',
    'code': code,
    'code_verifier': verifier,
    'redirect_uri': malRedirectUri,
  });

  Future<MalTokens> refresh(String refreshToken) =>
      _token({'grant_type': 'refresh_token', 'refresh_token': refreshToken});

  Future<MalTokens> _token(Map<String, String> fields) async {
    final http.Response response;
    try {
      response = await _client.post(
        Uri.parse(_tokenUrl),
        headers: {'Accept': 'application/json'},
        body: {
          'client_id': malClientId,
          if (malSendsSecret) 'client_secret': malClientSecret,
          ...fields,
        },
      );
    } on Exception {
      throw MalNetworkException();
    }
    if (response.statusCode == 400 || response.statusCode == 401) {
      throw MalTokenException();
    }
    if (response.statusCode != 200) {
      throw MalRequestException(
        'MyAnimeList login failed (${response.statusCode}).',
        status: response.statusCode,
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final seconds = (json['expires_in'] as num?)?.toInt() ?? 0;
    return MalTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: seconds)),
    );
  }

  /// Runs [send] after the gap since the last request, one at a time.
  Future<http.Response> _paced(Future<http.Response> Function() send) {
    final turn = _turn.then((_) async {
      final wait = _requestGap - DateTime.now().difference(_last);
      if (!wait.isNegative) await Future<void>.delayed(wait);
      try {
        return await send();
      } finally {
        _last = DateTime.now();
      }
    });
    _turn = turn.then((_) {}, onError: (_) {});
    return turn;
  }

  /// One call, retried a couple of times when MyAnimeList is busy.
  Future<Map<String, dynamic>> _call(
    String method,
    Uri uri,
    String token, {
    Map<String, String>? form,
  }) async {
    for (var attempt = 0; ; attempt++) {
      final http.Response response;
      try {
        response = await _paced(() async {
          final request = http.Request(method, uri)
            ..headers['Authorization'] = 'Bearer $token'
            ..headers['Accept'] = 'application/json';
          if (form != null) request.bodyFields = form;
          return http.Response.fromStream(await _client.send(request));
        });
      } on Exception {
        throw MalNetworkException();
      }
      final status = response.statusCode;
      if (status >= 200 && status < 300) {
        if (response.body.isEmpty) return const {};
        final decoded = jsonDecode(response.body);
        return decoded is Map<String, dynamic> ? decoded : const {};
      }
      if (status == 401) throw MalTokenException();
      if (status == 404) throw MalNotFoundException();
      final busy =
          status == 429 || status == 502 || status == 503 || status == 504;
      if (busy && attempt < 2) {
        await Future<void>.delayed(Duration(seconds: 2 << attempt));
        continue;
      }
      if (busy) throw MalRateLimitException();
      throw MalRequestException(
        'MyAnimeList refused the request ($status).',
        status: status,
      );
    }
  }

  Future<MalUser> fetchUser(String token) async {
    final json = await _call('GET', Uri.parse('$_apiBase/users/@me'), token);
    return MalUser(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      pictureUrl: json['picture'] as String?,
    );
  }

  Future<MalAnimeStats> fetchAnimeStats(String token) async {
    final json = await _call(
      'GET',
      Uri.parse('$_apiBase/users/@me')
          .replace(queryParameters: {'fields': 'anime_statistics'}),
      token,
    );
    final stats = json['anime_statistics'] as Map<String, dynamic>?;
    if (stats == null) return const MalAnimeStats();
    return MalAnimeStats(
      count: (stats['num_items'] as num?)?.toInt() ?? 0,
      episodes: (stats['num_episodes'] as num?)?.toInt() ?? 0,
      days: (stats['num_days'] as num?)?.toDouble() ?? 0,
      meanScore: (stats['mean_score'] as num?)?.toDouble() ?? 0,
    );
  }

  static const _listFields = {
    TrackerMedia.anime:
        'list_status,num_episodes,alternative_titles,media_type',
    TrackerMedia.manga:
        'list_status,num_chapters,alternative_titles,media_type',
  };

  /// The whole list of one kind, every page read.
  Future<List<TrackerEntry>> fetchList(String token, TrackerMedia media) async {
    final entries = <TrackerEntry>[];
    Uri? next = Uri.parse('$_apiBase/users/@me/${media.name}list').replace(
      queryParameters: {
        'fields': _listFields[media]!,
        'limit': '$_pageSize',
        'nsfw': 'true',
      },
    );
    // A broken answer that keeps pointing on must not loop forever.
    for (var page = 0; next != null && page < 100; page++) {
      final json = await _call('GET', next, token);
      for (final item in (json['data'] as List?) ?? const []) {
        if (item is! Map<String, dynamic>) continue;
        final node = item['node'];
        if (node is! Map<String, dynamic>) continue;
        entries.add(
          malEntryFrom(
            node,
            item['list_status'] as Map<String, dynamic>?,
            media: media,
          ),
        );
      }
      final url = (json['paging'] as Map<String, dynamic>?)?['next'];
      next = url is String ? Uri.tryParse(url) : null;
    }
    return entries;
  }

  /// Titles matching [query], for linking a library entry. MyAnimeList wants at least three letters.
  Future<List<TrackerSearchResult>> search(
    String token,
    TrackerMedia media,
    String query, {
    bool novel = false,
  }) async {
    final text = query.trim();
    if (text.length < 3) {
      throw MalSearchTooShortException();
    }
    final anime = media == TrackerMedia.anime;
    final json = await _call(
      'GET',
      Uri.parse('$_apiBase/${media.name}').replace(
        queryParameters: {
          'q': text,
          'limit': '25',
          'nsfw': 'true',
          'fields':
              'media_type,start_date,alternative_titles,${anime ? 'num_episodes' : 'num_chapters'}',
        },
      ),
      token,
    );
    final found = <TrackerSearchResult>[];
    for (final item in (json['data'] as List?) ?? const []) {
      final node = item is Map<String, dynamic> ? item['node'] : null;
      if (node is! Map<String, dynamic>) continue;
      final entry = malEntryFrom(node, null, media: media);
      // The manga list holds novels too; the library keeps them apart.
      if (!anime && entry.isNovel != novel) continue;
      final type = (node['media_type'] as String?)?.replaceAll('_', ' ');
      final year = (node['start_date'] as String?)?.split('-').first;
      found.add(
        TrackerSearchResult(
          mediaId: entry.mediaId,
          title: entry.title,
          coverUrl:
              (node['main_picture'] as Map<String, dynamic>?)?['medium']
                  as String?,
          subtitle: [
            if (type != null && type.isNotEmpty) type,
            if (year != null && year.isNotEmpty) year,
          ].join(' · '),
          total: entry.total,
        ),
      );
    }
    return found;
  }

  /// A title's length and the account's entry for it, for sending progress.
  Future<TrackerRemoteState?> remoteState(
    String token,
    TrackerMedia media,
    int mediaId,
  ) async {
    final anime = media == TrackerMedia.anime;
    final Map<String, dynamic> json;
    try {
      json = await _call(
        'GET',
        Uri.parse('$_apiBase/${media.name}/$mediaId').replace(
          queryParameters: {
            'fields':
                'my_list_status,${anime ? 'num_episodes' : 'num_chapters'},media_type',
          },
        ),
        token,
      );
    } on MalNotFoundException {
      return null;
    }
    final mine = json['my_list_status'] as Map<String, dynamic>?;
    final entry = mine == null ? null : malEntryFrom(json, mine, media: media);
    final total = (json[anime ? 'num_episodes' : 'num_chapters'] as num?)
        ?.toInt();
    return TrackerRemoteState(
      total: total != null && total > 0 ? total : null,
      entry: entry,
    );
  }

  Future<void> saveEntry(String token, TrackerEntryUpdate update) => _call(
    'PATCH',
    Uri.parse(
      '$_apiBase/${update.media.name}/${update.mediaId}/my_list_status',
    ),
    token,
    form: malUpdateFields(update),
  );

  Future<void> deleteEntry(
    String token,
    TrackerMedia media,
    int mediaId,
  ) async {
    try {
      await _call(
        'DELETE',
        Uri.parse('$_apiBase/${media.name}/$mediaId/my_list_status'),
        token,
      );
    } on MalNotFoundException {
      // Already gone from the list.
    }
  }
}
