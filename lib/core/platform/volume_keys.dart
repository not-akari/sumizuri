// The phone's volume buttons as page-turn input on Android.
import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class VolumeKeys {
  VolumeKeys._();

  static final instance = VolumeKeys._();

  static const _channel = MethodChannel('sumizuri/volume_keys');

  final _controller = StreamController<bool>.broadcast();
  bool _wired = false;

  static bool get supported => !kIsWeb && Platform.isAndroid;

  Stream<bool> get presses => _controller.stream;

  void _wire() {
    if (_wired) return;
    _wired = true;
    _channel.setMethodCallHandler((call) async {
      if (call.method == 'key') {
        final args = call.arguments;
        if (args is Map) _controller.add(args['up'] == true);
      }
    });
  }

  Future<void> setIntercept(bool on) async {
    if (!supported) return;
    _wire();
    try {
      await _channel.invokeMethod<void>('intercept', on);
    } on PlatformException {
      // The volume keys keep their normal job.
    } on MissingPluginException {
      // Not running inside the Android host (a test), so there is nothing to claim.
    }
  }
}
