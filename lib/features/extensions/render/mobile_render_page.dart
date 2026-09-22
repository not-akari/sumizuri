// A hidden system web view page for rendering on Android, iOS and macOS.
import 'dart:async';

import 'package:webview_flutter/webview_flutter.dart';

import 'package:sumizuri/features/extensions/render/render_runner.dart';

class MobileRenderPage implements RenderPage {
  MobileRenderPage._(this._controller);

  final WebViewController _controller;
  Completer<void>? _loading;

  static Future<MobileRenderPage> open(String? userAgent) async {
    final controller = WebViewController();
    final page = MobileRenderPage._(controller);
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    if (userAgent != null) await controller.setUserAgent(userAgent);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        onPageFinished: (_) {
          final loading = page._loading;
          if (loading != null && !loading.isCompleted) loading.complete();
        },
        onWebResourceError: (error) {
          if (error.isForMainFrame ?? true) {
            final loading = page._loading;
            if (loading != null && !loading.isCompleted) {
              loading.completeError(
                StateError(
                  'The page could not be loaded (${error.description})',
                ),
              );
            }
          }
        },
      ),
    );
    return page;
  }

  static Future<void> clearData() async {
    await WebViewCookieManager().clearCookies();
    final controller = WebViewController();
    await controller.clearCache();
    await controller.clearLocalStorage();
  }

  @override
  Future<void> load(String url) async {
    final loading = Completer<void>();
    _loading = loading;
    await _controller.loadRequest(Uri.parse(url));
    await loading.future;
  }

  @override
  Future<String> eval(String script) async {
    final result = await _controller.runJavaScriptReturningResult(script);
    return result.toString();
  }

  @override
  Future<void> close() async {
    // The controller has no dispose. Loading a blank page frees what the page held.
    await _controller.loadRequest(Uri.parse('about:blank'));
  }
}
