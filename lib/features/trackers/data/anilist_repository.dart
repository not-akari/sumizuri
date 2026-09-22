import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/trackers/models/anilist_account.dart';
import 'package:sumizuri/features/trackers/models/anilist_media.dart';
import 'package:sumizuri/features/trackers/models/anilist_stats.dart';

abstract interface class AniListRepository {
  Future<AniListAccount?> currentAccount(int profileId);

  String buildAuthorizeUrl();

  Future<Result<AniListAccount, AppFailure>> completeLogin(
    int profileId, {
    required String code,
  });

  Future<void> logout(int profileId);

  Future<Result<AniListSearchPage, AppFailure>> search(
    int profileId,
    String query, {
    required AniListMediaType type,
    bool novel = false,
    int page = 1,
  });

  Future<Result<AniListMedia, AppFailure>> media(int profileId, int mediaId);

  Future<Result<AniListStats, AppFailure>> stats(int profileId);

  Future<Result<AniListListPage, AppFailure>> list(
    int profileId,
    AniListMediaType type, {
    int chunk = 1,
  });

  Future<Result<AniListListEntry, AppFailure>> saveEntry(
    int profileId,
    AniListEntryUpdate update,
  );

  Future<Result<void, AppFailure>> deleteEntry(int profileId, int entryId);
}
