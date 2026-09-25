import 'dart:async';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/features/trackers/data/oauth_loopback_listener.dart';
import 'package:sumizuri/features/trackers/models/tracker_exception.dart';

/// On a phone the sign-in happens in the browser, so the app is in the
/// background when the code comes back, and the system may keep its network
/// shut until it is shown again (the "Failed host lookup" of a login that
/// seemed to work). This waits for that. On a computer nothing is held back.
Future<void> waitUntilForeground({
  Duration timeout = const Duration(minutes: 2),
}) async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  final binding = WidgetsBinding.instance;
  bool shown() =>
      binding.lifecycleState == null ||
      binding.lifecycleState == AppLifecycleState.resumed;
  if (shown()) return;
  final resumed = Completer<void>();
  final listener = AppLifecycleListener(
    onResume: () {
      if (!resumed.isCompleted) resumed.complete();
    },
  );
  try {
    await resumed.future.timeout(timeout, onTimeout: () {});
  } finally {
    listener.dispose();
  }
  // The network comes back a moment after the window does.
  await Future<void>.delayed(const Duration(milliseconds: 600));
}

/// Runs [action], and again after a short wait each time it fails only because
/// the network could not be reached. The authorization code is not used up by a
/// request that never arrived, so trying it again is safe.
Future<T> retryOnNetworkFailure<T>(
  Future<T> Function() action, {
  int attempts = 4,
  Duration firstWait = const Duration(seconds: 1),
}) async {
  var wait = firstWait;
  for (var attempt = 1; ; attempt++) {
    try {
      return await action();
    } on TrackerException catch (error) {
      if (error.problem != TrackerProblem.network || attempt >= attempts) {
        rethrow;
      }
      await Future<void>.delayed(wait);
      wait *= 2;
    }
  }
}

/// The sign-in every tracker shares: open the tracker's page in the browser,
/// wait for the redirect back to [listener], then finish with [complete]. Null
/// when the person never came back or refused.
Future<T?> runLoopbackLogin<T>({
  required OAuthLoopbackListener listener,
  required String authorizeUrl,
  String? state,
  required Future<T> Function(String code) complete,
}) async {
  // Listening first, so a fast redirect is never missed.
  final code = listener.waitForCode(state: state);
  await launchUrl(
    Uri.parse(authorizeUrl),
    mode: LaunchMode.externalApplication,
  );
  final received = await code;
  if (received == null) return null;
  await waitUntilForeground();
  return retryOnNetworkFailure(() => complete(received));
}
