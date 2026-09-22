import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Asks an Android phone for its fastest refresh rate. Returns a line for the log, or null.
Future<String?> setHighRefreshRate(bool on) async {
  if (kIsWeb || !Platform.isAndroid) return null;
  try {
    return await const MethodChannel('sumizuri/display')
        .invokeMethod<String>('highRefresh', on);
  } on PlatformException {
    return null;
  } on MissingPluginException {
    return null;
  }
}
