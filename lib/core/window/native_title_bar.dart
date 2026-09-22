import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

bool get isDesktopWindowPlatform =>
    !kIsWeb &&
    Platform.environment['FLUTTER_TEST'] != 'true' &&
    (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

const _windowChannel = MethodChannel('sumizuri/window');

Future<void> setDarkTitleBar(bool dark) async {
  if (!Platform.isWindows) return;
  try {
    await _windowChannel.invokeMethod<void>('setDarkTitleBar', dark);
  } on MissingPluginException {
    // No native window in a test.
  }
}
