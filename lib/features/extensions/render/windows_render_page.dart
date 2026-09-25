// A hidden WebView2 page for rendering on Windows.
import 'dart:async';

import 'package:webview_windows/webview_windows.dart';

import 'package:sumizuri/features/extensions/render/render_runner.dart';

class WindowsRenderPage implements RenderPage {
  WindowsRenderPage._(this._controller) {
    _done = _controller.loadingState.listen((state) {
      final loading = _loading;
      if (state == LoadingState.navigationCompleted &&
          loading != null &&
          !loading.isCompleted) {
        loading.complete();
      }
    });
    _failed = _controller.onLoadError.listen((status) {
      final loading = _loading;
      if (loading != null && !loading.isCompleted) {
        final url = _currentUrl;
        loading.completeError(
          StateError(
            'The page could not be loaded ($status) at ${url != null ? (Uri.tryParse(url)?.host ?? url) : 'unknown'}',
          ),
        );
      }
    });
  }

  final WebviewController _controller;
  late final StreamSubscription<LoadingState> _done;
  late final StreamSubscription<WebErrorStatus> _failed;
  Completer<void>? _loading;
  String? _currentUrl;

  static Future<WindowsRenderPage> open(String? userAgent) async {
    final controller = WebviewController();
    try {
      await controller.initialize();
      // This page is never shown, so a popup window has no way to be
      // dismissed. Only popups are refused here: rewriting the page's own
      // scripts risks breaking the sites this exists to read.
      await controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
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
    final loading = Completer<void>();
    _loading = loading;
    _currentUrl = url;
    try {
      await _controller.loadUrl(url);
      await loading.future;
    } finally {
      if (identical(_loading, loading)) _loading = null;
    }
  }

  @override
  Future<String> eval(String script) async {
    final result = await _controller.executeScript(script);
    return result is String ? result : '$result';
  }

  @override
  Future<void> close() async {
    await _done.cancel();
    await _failed.cancel();
    await _controller.dispose();
  }
}
