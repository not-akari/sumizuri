import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:workmanager/workmanager.dart';

import 'package:sumizuri/core/utils/files/delete_if_exists.dart';
import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/library/background/background_library_update.dart';
import 'package:sumizuri/features/sync/models/sync_models.dart';
import 'package:sumizuri/features/sync/providers/sync_providers.dart';
import 'package:sumizuri/features/sync/data/sync_repository.dart';

const _tag = 'sync';

const backgroundSyncUniqueName = 'dev.sumizuri.background-sync';
const _taskName = backgroundSyncUniqueName;

/// Android WorkManager will not run a periodic job more often than this.
const minBackgroundSyncMinutes = 15;

bool get backgroundSyncSupported =>
    !kIsWeb &&
    Platform.environment['FLUTTER_TEST'] != 'true' &&
    (Platform.isAndroid || Platform.isIOS);

/// Entry point the platform scheduler starts in a fresh isolate.
@pragma('vm:entry-point')
void backgroundSyncDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task == backgroundLibraryUpdateName) {
      // The open app and a background run would otherwise write to the same database at once.
      if (await foregroundRecentlyActive()) return true;
      return runBackgroundLibraryUpdate();
    }
    return runBackgroundSync();
  });
}

Future<void> initializeBackgroundSync() async {
  if (!backgroundSyncSupported) return;
  await Workmanager().initialize(backgroundSyncDispatcher);
}

Future<void> reconcileBackgroundSync(SyncRepository repository) async {
  if (!backgroundSyncSupported) return;
  final minutes = await repository.backgroundIntervalMinutes();
  if (minutes == null) {
    await Workmanager().cancelByUniqueName(backgroundSyncUniqueName);
    return;
  }
  await Workmanager().registerPeriodicTask(
    backgroundSyncUniqueName,
    _taskName,
    frequency: Duration(
      minutes: minutes < minBackgroundSyncMinutes
          ? minBackgroundSyncMinutes
          : minutes,
    ),
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

Future<bool> runBackgroundSync({ProviderContainer? container}) async {
  if (await foregroundRecentlyActive()) return true;
  final own = container == null;
  final scope = container ?? ProviderContainer();
  try {
    final repository = scope.read(syncRepositoryProvider);
    for (final profileId in await repository.dueBackgroundProfiles()) {
      if (await foregroundRecentlyActive()) break;
      final result = await repository.sync(
        SyncMode.incremental,
        profileId: profileId,
      );
      final failure = result.errorOrNull;
      if (failure != null) {
        scope
            .read(appLoggerProvider)
            .warning(
              'Background sync of profile $profileId failed: ${failure.displayMessage}',
              tag: _tag,
            );
      }
    }
    return true;
  } catch (error, stackTrace) {
    scope
        .read(appLoggerProvider)
        .error(
          'Background sync crashed',
          tag: _tag,
          error: error,
          stackTrace: stackTrace,
        );
    return false;
  } finally {
    if (own) scope.dispose();
  }
}

// The open app and a background run would otherwise write to the same SQLite file at once.
const _foregroundWindow = Duration(minutes: 2);

Future<File> _heartbeatFile() async =>
    File(p.join((await appDataDirectory()).path, 'app_in_foreground'));

Future<void> markForegroundActive() async {
  try {
    await (await _heartbeatFile()).writeAsString(
      '${DateTime.now().millisecondsSinceEpoch}',
      flush: true,
    );
  } on FileSystemException {
    // No stamp only lets a background run go ahead.
  }
}

Future<void> markForegroundInactive() async {
  try {
    final file = await _heartbeatFile();
    await deleteIfExists(file);
  } on FileSystemException {
    // Same as above.
  }
}

Future<bool> foregroundRecentlyActive() async {
  try {
    final file = await _heartbeatFile();
    if (!await file.exists()) return false;
    final stamp = int.tryParse(await file.readAsString());
    if (stamp == null) return false;
    return DateTime.now().millisecondsSinceEpoch - stamp <
        _foregroundWindow.inMilliseconds;
  } on FileSystemException {
    return false;
  }
}
