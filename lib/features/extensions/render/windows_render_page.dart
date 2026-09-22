// A hidden WebView2 page for rendering on Windows.
import 'dart:async';

import 'package:webview_windows/webview_windows.dart';

import 'package:sumizuri/features/extensions/render/render_runner.dart';

class WindowsRenderPage implements RenderPage {
  WindowsRenderPage._(this._controller);

  final WebviewController _controller;

  static Future<WindowsRenderPage> open(String? userAgent) async {
    final controller = WebviewController();
    try {
      await controller.initialize();
      if (userAgent != null) await controller.setUserAgent(userAgent);
    } catch (error) {
      await controller.dispose();
      throw StateError(
        'Could not start the embedded browser: $error. '
        'It needs the WebView2 Runtime (included with Windows 11 and current Windows 10).',
      );
    }
    return WindowsRenderPage._(controller);
  }

  static Future<void> clearData() async {
    final controller = WebviewController();
    try {
      await controller.initialize();
      await controller.clearCookies();
      await controller.clearCache();
    } finally {
      await controller.dispose();
    }
  }

  @override
  Future<void> load(String url) async {
    final finished = Completer<void>();
    final done = _controller.loadingState.listen((state) {
      if (state == LoadingState.navigationCompleted && !finished.isCompleted) {
        finished.complete();
      }
    });
    final failed = _controller.onLoadError.listen((status) {
      if (!finished.isCompleted) {
        finished.completeError(
          StateError('The page could not be loaded ($status)'),
        );
      }
    });
    try {
      await _controller.loadUrl(url);
      await finished.future;
    } finally {
      await done.cancel();
      await failed.cancel();
    }
  }

  @override
  Future<String> eval(String script) async {
    final result = await _controller.executeScript(script);
    return result is String ? result : '$result';
  }

  @override
  Future<void> close() => _controller.dispose();
}
