import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_api_client.dart';
import 'package:sumizuri/features/trackers/data/anilist/anilist_repository_impl.dart'
    show AniListRepositoryImpl, aniListTokenField;
import 'package:sumizuri/features/trackers/data/anilist/anilist_sync_service.dart';
import 'package:sumizuri/features/trackers/data/tracker_secure_store.dart';
import 'package:sumizuri/features/trackers/data/tracker_store.dart';
import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/trackers/models/anilist_account.dart';
import 'package:sumizuri/features/trackers/data/anilist_repository.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';

part 'anilist_providers.g.dart';

@Riverpod(keepAlive: true)
AniListApiClient aniListApiClient(Ref ref) => AniListApiClient();

@Riverpod(keepAlive: true)
AniListRepository aniListRepository(Ref ref) {
  final logger = ref.watch(appLoggerProvider);
  return AniListRepositoryImpl(
    logger,
    apiClient: ref.watch(aniListApiClientProvider),
  );
}

@Riverpod(keepAlive: true)
TrackerStore trackerStore(Ref ref) =>
    TrackerStore(ref.watch(appDatabaseProvider));

@Riverpod(keepAlive: true)
AniListSyncService aniListSyncService(Ref ref) {
  final tokens = TrackerSecureStore('anilist');
  return AniListSyncService(
    store: ref.watch(trackerStoreProvider),
    api: ref.watch(aniListApiClientProvider),
    tokenFor: (profileId) => tokens.read(profileId, aniListTokenField),
    logger: ref.watch(appLoggerProvider),
  );
}

@riverpod
class AniListAccountNotifier extends _$AniListAccountNotifier {
  @override
  Future<AniListAccount?> build() {
    final profileId = ref.watch(currentProfileIdProvider);
    final repository = ref.watch(aniListRepositoryProvider);
    return repository.currentAccount(profileId);
  }

  String buildAuthorizeUrl() =>
      ref.read(aniListRepositoryProvider).buildAuthorizeUrl();

  Future<Result<AniListAccount, AppFailure>> completeLogin(String code) async {
    final profileId = ref.read(currentProfileIdProvider);
    final repository = ref.read(aniListRepositoryProvider);
    final result = await repository.completeLogin(profileId, code: code);
    result.when(ok: (account) => state = AsyncData(account), err: (_) {});
    return result;
  }

  Future<void> logout() async {
    final profileId = ref.read(currentProfileIdProvider);
    final repository = ref.read(aniListRepositoryProvider);
    await repository.logout(profileId);
    state = const AsyncData(null);
  }
}
