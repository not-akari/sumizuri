import 'dart:convert';

import 'package:gql/ast.dart';
import 'package:gql/language.dart';
import 'package:http/http.dart' as http;

import 'package:sumizuri/features/trackers/data/anilist/anilist_graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_batch_operations.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/delete_entry.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/media_recommendations.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/media_with_entry.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/save_entry.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/schema.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/search_media.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/user_list.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/viewer.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/graphql/viewer_stats.graphql.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_request_queue.dart';
import 'package:sumizuri/features/trackers/data/tracker_client_config.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/features/trackers/models/anilist_stats.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';

const _authorizeUrl = 'https://anilist.co/api/v2/oauth/authorize';
const _tokenUrl = 'https://anilist.co/api/v2/oauth/token';

// AniList rejects the Implicit Grant, so this uses the Authorization Code Grant.
const aniListLoopbackPort = 48765;
const aniListRedirectUri =
    'http://localhost:$aniListLoopbackPort/anilist-callback';

class AniListAuthException implements Exception {
  AniListAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AniListAccountInfo {
  const AniListAccountInfo({
    required this.id,
    required this.name,
    this.avatarUrl,
  });

  final int id;
  final String name;
  final String? avatarUrl;
}

// The generated queries are syntax trees, so the text sent is made from each once.
final _printed = <DocumentNode, String>{};
String _text(DocumentNode document) =>
    _printed[document] ??= printNode(document);

Input$FuzzyDateInput? _date(AniListFuzzyDate? date) => date == null
    ? null
    : Input$FuzzyDateInput(year: date.year, month: date.month, day: date.day);

class AniListApiClient {
  AniListApiClient({AniListGraphQl? graphQl})
    : _graphQl = graphQl ?? AniListGraphQl();

  final AniListGraphQl _graphQl;

  String buildAuthorizeUrl() {
    final query = {
      'client_id': aniListClientId,
      'redirect_uri': aniListRedirectUri,
      'response_type': 'code',
    };
    return Uri.parse(_authorizeUrl).replace(queryParameters: query).toString();
  }

  Future<String> exchangeCode(String code) async {
    final response = await http.post(
      Uri.parse(_tokenUrl),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'grant_type': 'authorization_code',
        'client_id': aniListClientId,
        'client_secret': aniListClientSecret,
        'redirect_uri': aniListRedirectUri,
        'code': code,
      }),
    );
    if (response.statusCode != 200) {
      throw AniListAuthException(
        'AniList login failed (${response.statusCode}).',
      );
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return json['access_token'] as String;
  }

  void cancelPending() => _graphQl.queue.cancelAll(AniListTokenException());

  Future<AniListAccountInfo> fetchViewer(String accessToken) async {
    final data = await _graphQl.execute(
      _text(documentNodeQueryViewer),
      token: accessToken,
    );
    final viewer = data['Viewer'] as Map<String, dynamic>?;
    if (viewer == null) throw AniListTokenException();
    final avatar = viewer['avatar'] as Map<String, dynamic>?;
    return AniListAccountInfo(
      id: viewer['id'] as int,
      name: viewer['name'] as String,
      avatarUrl: avatar?['medium'] as String?,
    );
  }

  /// The counts and mean scores AniList shows on the profile.
  Future<AniListStats> fetchStats(String token) async {
    final data = await _graphQl.execute(
      _text(documentNodeQueryViewerStats),
      token: token,
    );
    final viewer = data['Viewer'] as Map<String, dynamic>?;
    if (viewer == null) throw AniListTokenException();
    return AniListStats.fromJson(viewer);
  }

  Future<AniListSearchPage> searchMedia(
    String query, {
    required AniListMediaType type,
    bool novel = false,
    int page = 1,
    int perPage = 20,
    String? token,
  }) async {
    final data = await _graphQl.execute(
      _text(documentNodeQuerySearchMedia),
      token: token,
      variables: Variables$Query$SearchMedia(
        search: query,
        type: fromJson$Enum$MediaType(type.wire),
        format: type == AniListMediaType.manga && novel
            ? Enum$MediaFormat.NOVEL
            : null,
        formatNot: type == AniListMediaType.manga && !novel
            ? Enum$MediaFormat.NOVEL
            : null,
        page: page,
        perPage: perPage,
      ).toJson(),
    );
    final result = data['Page'] as Map<String, dynamic>;
    return AniListSearchPage(
      results: [
        for (final json in (result['media'] as List? ?? const []))
          AniListMedia.fromJson(json as Map<String, dynamic>),
      ],
      hasNextPage:
          (result['pageInfo'] as Map<String, dynamic>?)?['hasNextPage']
              as bool? ??
          false,
    );
  }

  /// One title with the user's entry for it. Throws AniListNotFoundException if missing.
  Future<AniListMedia> mediaWithEntry(int mediaId, String token) async {
    final data = await _graphQl.execute(
      _text(documentNodeQueryMediaWithEntry),
      token: token,
      variables: Variables$Query$MediaWithEntry(id: mediaId).toJson(),
    );
    final media = data['Media'] as Map<String, dynamic>?;
    if (media == null) throw AniListNotFoundException();
    return AniListMedia.fromJson(media);
  }

  /// Titles AniList users recommend alongside [mediaId].
  Future<List<AniListMedia>> mediaRecommendations(
    int mediaId, {
    int perPage = 12,
  }) async {
    final data = await _graphQl.execute(
      _text(documentNodeQueryMediaRecommendations),
      variables: Variables$Query$MediaRecommendations(
        id: mediaId,
        perPage: perPage,
      ).toJson(),
    );
    final media = data['Media'] as Map<String, dynamic>?;
    final nodes =
        (media?['recommendations'] as Map<String, dynamic>?)?['nodes']
            as List? ??
        const [];
    return [
      for (final node in nodes)
        if ((node as Map<String, dynamic>)['mediaRecommendation'] != null)
          AniListMedia.fromJson(
            node['mediaRecommendation'] as Map<String, dynamic>,
          ),
    ];
  }

  Future<AniListListPage> userList(
    int userId,
    AniListMediaType type,
    String token, {
    int chunk = 1,
    int perChunk = 100,
  }) async {
    final data = await _graphQl.execute(
      _text(documentNodeQueryUserList),
      token: token,
      priority: AniListPriority.background,
      variables: Variables$Query$UserList(
        userId: userId,
        type: fromJson$Enum$MediaType(type.wire),
        chunk: chunk,
        perChunk: perChunk,
      ).toJson(),
    );
    final collection = data['MediaListCollection'] as Map<String, dynamic>?;
    final seen = <int>{};
    final entries = <AniListListEntry>[];
    for (final list in (collection?['lists'] as List? ?? const [])) {
      for (final json in ((list as Map)['entries'] as List? ?? const [])) {
        final entry = AniListListEntry.fromJson(json as Map<String, dynamic>);
        if (seen.add(entry.id)) entries.add(entry);
      }
    }
    return AniListListPage(
      entries: entries,
      hasNextChunk: collection?['hasNextChunk'] as bool? ?? false,
    );
  }

  Future<AniListListEntry> saveEntry(AniListEntryUpdate update, String token) =>
      _graphQl.queue.runCoalesced<AniListEntryUpdate, AniListListEntry>(
        // Per account and title, so two profiles never share a write.
        key: 'save:${token.hashCode}:${update.mediaId}',
        payload: update,
        merge: (older, newer) => older.mergedWith(newer),
        run: (merged) async {
          final data = await _graphQl.send(
            _text(documentNodeMutationSaveEntry),
            token: token,
            variables: Variables$Mutation$SaveEntry(
              mediaId: merged.mediaId,
              status: merged.status == null
                  ? null
                  : fromJson$Enum$MediaListStatus(merged.status!.wire),
              progress: merged.progress,
              progressVolumes: merged.progressVolumes,
              scoreRaw: merged.score,
              repeat: merged.repeat,
              startedAt: _date(merged.startedAt),
              completedAt: _date(merged.completedAt),
            ).toJson(),
          );
          return AniListListEntry.fromJson(
            data['SaveMediaListEntry'] as Map<String, dynamic>,
          );
        },
      );

  Future<Map<int, AniListRemoteState>> remoteStates(
    List<int> mediaIds,
    String token,
  ) async {
    final result = <int, AniListRemoteState>{};
    for (var at = 0; at < mediaIds.length; at += batchSize) {
      final ids = mediaIds.skip(at).take(batchSize).toList();
      final data = await _graphQl.queue.run(() async {
        final batch = await _graphQl.sendBatch(
          entriesOperation(ids.length),
          token: token,
          variables: {for (var i = 0; i < ids.length; i++) 'm$i': ids[i]},
        );
        return batch.data;
      }, priority: AniListPriority.background);
      for (var i = 0; i < ids.length; i++) {
        final media = data['m$i'];
        if (media is! Map<String, dynamic>) continue;
        final entry = media['mediaListEntry'];
        result[ids[i]] = AniListRemoteState(
          mediaId: ids[i],
          chapters: media['chapters'] as int?,
          entry: entry is Map<String, dynamic>
              ? AniListListEntry.fromJson(entry)
              : null,
        );
      }
    }
    return result;
  }

  Future<AniListBatchSave> saveEntries(
    List<AniListEntryUpdate> updates,
    String token,
  ) async {
    final saved = <int, AniListListEntry>{};
    final failed = <int, String>{};
    for (var at = 0; at < updates.length; at += batchSize) {
      final chunk = updates.skip(at).take(batchSize).toList();
      final built = saveEntriesOperation([for (final u in chunk) _fieldsOf(u)]);
      final batch = await _graphQl.queue.run(
        () => _graphQl.sendBatch(
          built.operation,
          token: token,
          variables: built.variables,
        ),
        priority: AniListPriority.background,
      );
      for (var i = 0; i < chunk.length; i++) {
        final json = batch.data['e$i'];
        if (json is Map<String, dynamic>) {
          saved[chunk[i].mediaId] = AniListListEntry.fromJson(json);
        } else {
          failed[chunk[i].mediaId] =
              batch.failures['e$i'] ?? TrackerProblem.refused.name;
        }
      }
    }
    return AniListBatchSave(saved: saved, failed: failed);
  }

  Map<String, dynamic> _fieldsOf(AniListEntryUpdate u) => {
    'mediaId': u.mediaId,
    if (u.status != null) 'status': u.status!.wire,
    if (u.progress != null) 'progress': u.progress,
    if (u.progressVolumes != null) 'progressVolumes': u.progressVolumes,
    if (u.score != null) 'scoreRaw': u.score,
    if (u.repeat != null) 'repeat': u.repeat,
    if (u.startedAt != null) 'startedAt': u.startedAt!.toJson(),
    if (u.completedAt != null) 'completedAt': u.completedAt!.toJson(),
  };

  Future<void> deleteEntry(int entryId, String token) async {
    await _graphQl.execute(
      _text(documentNodeMutationDeleteEntry),
      token: token,
      priority: AniListPriority.background,
      variables: Variables$Mutation$DeleteEntry(id: entryId).toJson(),
    );
  }
}
