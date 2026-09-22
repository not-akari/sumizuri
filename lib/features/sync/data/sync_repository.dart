import 'package:sumizuri/core/errors/app_failure.dart';
import 'package:sumizuri/core/errors/result.dart';
import 'package:sumizuri/features/sync/models/sync_models.dart';

abstract interface class SyncRepository {
  Future<SyncAccount?> currentAccount();

  Future<SyncServerProfile?> linkedProfile();

  /// Device-clock time the active profile last finished a sync, 0 if never.
  Future<int> lastSyncedAt();

  Future<SyncPreferences> preferences();

  Future<void> setPreferences(SyncPreferences preferences);

  Future<Result<SyncAccount, AppFailure>> signIn(String server);

  Future<void> cancelSignIn();

  Future<void> signOut();

  Future<Result<List<SyncServerProfile>, AppFailure>> listServerProfiles();

  Future<Result<void, AppFailure>> linkProfile(SyncServerProfile profile);

  Future<Result<SyncServerProfile, AppFailure>> createAndLinkProfile(
    String name,
  );

  Future<void> unlinkProfile();

  Future<void> forgetProfile(int profileId);

  Future<Result<void, AppFailure>> sync(
    SyncMode mode, {
    void Function(SyncProgress progress)? onProgress,
    int? profileId,
  });

  Future<List<int>> dueBackgroundProfiles();

  Future<int?> backgroundIntervalMinutes();
}
