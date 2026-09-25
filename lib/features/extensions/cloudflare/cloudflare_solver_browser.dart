import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_windows/webview_windows.dart';

import 'package:sumizuri/features/extensions/cloudflare/ad_block.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

/// The embedded browser behind the solver page. Each platform has its own web view.
abstract class SolverBrowser {
  SolverBrowser();

  factory SolverBrowser.forPlatform() =>
      Platform.isWindows ? _WindowsSolverBrowser() : _MobileSolverBrowser();

  /// Starts the browser and loads [url]. [onLoaded] is called when a page finishes loading.
  Future<void> open(String url, VoidCallback onLoaded);

  /// The cookies of the page as a cookie header string.
  Future<String> readCookies();

  /// The web view to put on screen. Only valid after [open] has finished.
  Widget view();

  /// The text shown when the browser could not start.
  String startFailure(AppLocalizations l10n, String error);

  void dispose() {}
}

class _MobileSolverBrowser extends SolverBrowser {
  late final WebViewController _controller;

  @override
  Future<void> open(String url, VoidCallback onLoaded) async {
    final controller = WebViewController();
    // Both must be set before the page loads, or a challenge page runs without scripts.
    await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
    await controller.setNavigationDelegate(
      NavigationDelegate(
        // Ad frames and ad redirects are refused outright.
        onNavigationRequest: (request) => isAdUrl(request.url)
            ? NavigationDecision.prevent
            : NavigationDecision.navigate,
        // webview_flutter cannot inject before the document exists, so the
        // blocker goes in as soon as the page starts and again once it is
        // done, for anything a redirect replaced.
        onPageStarted: (_) => controller.runJavaScript(adBlockScript()),
        onPageFinished: (_) {
          controller.runJavaScript(adBlockScript());
          onLoaded();
        },
      ),
    );
    await controller.loadRequest(Uri.parse(url));
    _controller = controller;
  }

  @override
  Future<String> readCookies() async {
    final raw = await _controller.runJavaScriptReturningResult(
      'document.cookie',
    );
    var text = raw.toString();
    // The result comes back as a quoted, escaped JavaScript string.
    if (text.length >= 2 && text.startsWith('"') && text.endsWith('"')) {
      text = text
          .substring(1, text.length - 1)
          .replaceAll(r'\"', '"')
          .replaceAll(r'\\', r'\');
    }
    return text;
  }

  @override
  Widget view() => WebViewWidget(controller: _controller);

  @override
  String startFailure(AppLocalizations l10n, String error) =>
      l10n.extensionCouldNotStartTheEmbedded(error);
}

class _WindowsSolverBrowser extends SolverBrowser {
  final _controller = WebviewController();

  @override
  Future<void> open(String url, VoidCallback onLoaded) async {
    await _controller.initialize();
    // Runs in every page before its own scripts do, and no popup windows.
    await _controller.addScriptToExecuteOnDocumentCreated(adBlockScript());
    await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
    await _controller.loadUrl(url);
  }

  @override
  Future<String> readCookies() async {
    final raw = await _controller.executeScript('document.cookie');
    return raw is String ? raw : '';
  }

  @override
  Widget view() => Webview(_controller);

  @override
  String startFailure(AppLocalizations l10n, String error) =>
      l10n.extensionCouldNotStartTheEmbedded2(error);

  @override
  void dispose() => _controller.dispose();
}
