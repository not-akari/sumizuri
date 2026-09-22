import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/bootstrap/database/db_provider.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/profile/providers/profile_providers.dart';
import 'package:sumizuri/features/sync/data/sync_api_client.dart';
import 'package:sumizuri/features/sync/data/sync_credential_store.dart';
import 'package:sumizuri/features/sync/data/sync_file_store.dart';
import 'package:sumizuri/features/sync/data/sync_local_store.dart';
import 'package:sumizuri/features/sync/flows/sync_oauth_flow.dart';
import 'package:sumizuri/features/sync/data/sync_page_applier.dart';
import 'package:sumizuri/features/sync/data/sync_repository_impl.dart';
import 'package:sumizuri/features/sync/models/sync_models.dart';
import 'package:sumizuri/features/sync/data/sync_repository.dart';

part 'sync_providers.g.dart';

Future<Directory> _directoryFor(SyncFileKind kind) => switch (kind) {
  SyncFileKind.theme => themesDirectory(),
  SyncFileKind.font => fontsDirectory(),
  SyncFileKind.cover => customCoversDirectory(),
  SyncFileKind.draft => translationDraftsDirectory(),
};

Future<String> _coversPath() async => (await customCoversDirectory()).path;

@Riverpod(keepAlive: true)
SyncRepository syncRepository(Ref ref) {
  final db = ref.watch(appDatabaseProvider);
  final api = SyncApiClient(http.Client());
  final files = SyncFileStore(db, directoryFor: _directoryFor);
  return SyncRepositoryImpl(
    api: api,
    oauth: SyncOAuthFlow(api: api),
    credentials: SyncCredentialStore(),
    local: SyncLocalStore(db, files: files, coversPath: _coversPath),
    applier: SyncPageApplier(db, files: files, coversPath: _coversPath),
    logger: ref.watch(appLoggerProvider),
  );
}

@riverpod
Future<SyncAccount?> syncAccount(Ref ref) =>
    ref.watch(syncRepositoryProvider).currentAccount();

@riverpod
Future<SyncServerProfile?> syncLinkedProfile(Ref ref) {
  ref.watch(currentProfileIdProvider);
  return ref.watch(syncRepositoryProvider).linkedProfile();
}

@riverpod
Future<List<SyncServerProfile>> syncServerProfiles(Ref ref) async {
  final result = await ref.watch(syncRepositoryProvider).listServerProfiles();
  return result.when(
    ok: (profiles) => profiles,
    err: (failure) => throw Exception(failure.displayMessage),
  );
}

/// Device-clock time the active profile last finished a sync, 0 if never.
@riverpod
Future<int> lastSyncedAt(Ref ref) {
  ref.watch(currentProfileIdProvider);
  return ref.watch(syncRepositoryProvider).lastSyncedAt();
}

@riverpod
Future<SyncPreferences> syncPreferences(Ref ref) {
  ref.watch(currentProfileIdProvider);
  return ref.watch(syncRepositoryProvider).preferences();
}

class SyncRunState {
  const SyncRunState({this.running = false, this.progress, this.error});

  final bool running;
  final SyncProgress? progress;
  final String? error;
}

@Riverpod(keepAlive: true)
class SyncGuard extends _$SyncGuard {
  int _holds = 0;

  @override
  bool build() => false;

  void hold() {
    _holds += 1;
    state = true;
  }

  void release() {
    _holds = _holds > 0 ? _holds - 1 : 0;
    state = _holds > 0;
  }
}

@Riverpod(keepAlive: true)
class SyncRunner extends _$SyncRunner {
  @override
  SyncRunState build() => const SyncRunState();

  Future<bool> run(SyncMode mode, {bool auto = false}) async {
    if (state.running) return false;
    if (auto && ref.read(syncGuardProvider)) return false;
    state = const SyncRunState(running: true);
    final result = await ref
        .read(syncRepositoryProvider)
        .sync(
          mode,
          onProgress: (progress) =>
              state = SyncRunState(running: true, progress: progress),
        );
    state = SyncRunState(error: result.errorOrNull?.displayMessage);
    ref.invalidate(lastSyncedAtProvider);
    return true;
  }

  Future<void> runAfterRestore() async {
    final linked = await ref.read(syncRepositoryProvider).linkedProfile();
    if (linked == null) return;
    await run(SyncMode.incremental);
  }
}
