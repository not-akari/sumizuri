import 'dart:io';

import 'package:flutter/services.dart';

import 'package:sumizuri/bootstrap/monitoring/run_heartbeat.dart';

/// Only the desktop apps can start themselves again.
bool get canRelaunch =>
    Platform.isWindows || Platform.isLinux || Platform.isMacOS;

/// Ends the app and records a clean close, so the next start is not seen as a crash.
Future<Never> exitCleanly() async {
  await markCleanExit();
  exit(0);
}

Future<void> restartApp() async {
  if (canRelaunch) {
    await Process.start(
      Platform.resolvedExecutable,
      const [],
      mode: ProcessStartMode.detached,
    );
    await exitCleanly();
  }
  // A phone cannot start itself again. Closing is as far as the app can go.
  await SystemNavigator.pop();
}
