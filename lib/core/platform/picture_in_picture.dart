import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// A small window that keeps a video playing over other apps. Only Android has it for now.
class PictureInPicture {
  PictureInPicture._() {
    if (supported) _channel.setMethodCallHandler(_onCall);
  }

  static final instance = PictureInPicture._();

  static const _channel = MethodChannel('sumizuri/pip');

  bool get supported => !kIsWeb && Platform.isAndroid;

  /// True while the window is small, so the controls can get out of the way.
  final active = ValueNotifier<bool>(false);

  Future<void> _onCall(MethodCall call) async {
    if (call.method == 'changed') active.value = call.arguments == true;
  }

  Future<bool> enter() async {
    if (!supported) return false;
    try {
      return await _channel.invokeMethod<bool>('enter') ?? false;
    } on PlatformException {
      return false;
    } on MissingPluginException {
      return false;
    }
  }

  /// Goes to the small window by itself when the person leaves the app.
  Future<void> setAutoEnter(bool on) async {
    if (!supported) return;
    try {
      await _channel.invokeMethod<void>('autoEnter', on);
    } on PlatformException {
      // The phone cannot do it, so leaving the app just pauses as before.
    } on MissingPluginException {
      // Not running inside the Android app, such as in a test.
    }
  }
}
