import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:workmanager/workmanager.dart';

import 'package:sumizuri/bootstrap/logging/logger_provider.dart';
import 'package:sumizuri/features/extensions/data/engines/json/json_engine_prelude.dart';
import 'package:sumizuri/features/library/flows/library_update_flow.dart';
import 'package:sumizuri/features/settings/data/settings_repository.dart';

const _tag = 'library_update';

const backgroundLibraryUpdateName = 'dev.sumizuri.background-library-update';

/// Android WorkManager will not run a periodic job more often than this.
const _minimumMinutes = 15;

Duration get _budget =>
    Platform.isIOS ? const Duration(seconds: 25) : const Duration(minutes: 8);

bool get backgroundLibraryUpdateSupported =>
    !kIsWeb &&
    Platform.environment['FLUTTER_TEST'] != 'true' &&
    (Platform.isAndroid || Platform.isIOS);

Future<void> reconcileBackgroundLibraryUpdate(
  SettingsRepository settings,
) async {
  if (!backgroundLibraryUpdateSupported) return;
  final hours = await settings.watchAutoLibraryUpdateIntervalHours().first;
  if (hours <= 0) {
    await Workmanager().cancelByUniqueName(backgroundLibraryUpdateName);
    return;
  }
  final wifiOnly = await settings.watchAutoLibraryUpdateWifiOnly().first;
  await Workmanager().registerPeriodicTask(
    backgroundLibraryUpdateName,
    backgroundLibraryUpdateName,
    frequency: Duration(
      minutes: (hours * 60) < _minimumMinutes ? _minimumMinutes : hours * 60,
    ),
    constraints: Constraints(
      networkType: wifiOnly ? NetworkType.unmetered : NetworkType.connected,
    ),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.update,
  );
}

Future<bool> runBackgroundLibraryUpdate({ProviderContainer? container}) async {
  final own = container == null;
  final scope = container ?? ProviderContainer();
  try {
    if (own) {
      WidgetsFlutterBinding.ensureInitialized();
      await loadJsonEnginePrelude();
    }
    await autoUpdateLibraryIfDue(scope, background: true, budget: _budget);
    return true;
  } catch (error, stackTrace) {
    scope
        .read(appLoggerProvider)
        .error(
          'Background library update crashed',
          tag: _tag,
          error: error,
          stackTrace: stackTrace,
        );
    return false;
  } finally {
    if (own) scope.dispose();
  }
}
