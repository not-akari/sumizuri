import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:sumizuri/features/extensions/data/engines/js/bridge/http_bridge.dart'
    show isBlockedFetchHost;
import 'package:sumizuri/features/extensions/render/mobile_render_page.dart';
import 'package:sumizuri/features/extensions/render/render_request.dart';
import 'package:sumizuri/features/extensions/render/render_runner.dart';
import 'package:sumizuri/features/extensions/render/windows_render_page.dart';

typedef RenderPageFactory = Future<RenderPage> Function(String? userAgent);

Future<RenderPage> platformRenderPage(String? userAgent) async {
  if (Platform.isWindows) return WindowsRenderPage.open(userAgent);
  if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
    return MobileRenderPage.open(userAgent);
  }
  throw UnsupportedError(
    'Rendering pages is not available on this platform (Windows, Android, iOS and macOS only).',
  );
}

class RenderBroker {
  RenderBroker._();

  static final instance = RenderBroker._();

  ReceivePort? _port;
  RenderPageFactory _factory = platformRenderPage;
  Future<void> _queue = Future.value();

  /// Where a source isolate sends its requests, or null before start.
  SendPort? get sendPort => _port?.sendPort;

  void start({RenderPageFactory? factory}) {
    if (factory != null) _factory = factory;
    if (_port != null) return;
    final port = ReceivePort();
    _port = port;
    port.listen((message) {
      final (Map<String, dynamic> json, SendPort reply) =
          message as (Map<String, dynamic>, SendPort);
      // One page at a time: several web views at once would fight over memory and the network.
      _queue = _queue.then((_) => _answer(json, reply));
    });
  }

  Future<bool> clearBrowserData() async {
    try {
      if (Platform.isWindows) {
        await WindowsRenderPage.clearData();
      } else if (Platform.isAndroid || Platform.isIOS || Platform.isMacOS) {
        await MobileRenderPage.clearData();
      } else {
        return false;
      }
      return true;
    } catch (_) {
      return false;
    }
  }

  void stop() {
    _port?.close();
    _port = null;
  }

  Future<void> _answer(Map<String, dynamic> json, SendPort reply) async {
    try {
      final result = json['kind'] == 'fetch'
          ? (await browserFetch(BrowserFetchRequest.fromJson(json))).toJson()
          : (await render(RenderRequest.fromJson(json))).toJson();
      reply.send((true, result));
    } catch (error) {
      reply.send((false, _message(error)));
    }
  }

  Future<RenderResult> render(RenderRequest request) async {
    RenderPage? page;
    try {
      final result = await () async {
        page = await _factory(request.userAgent);
        return renderWith(page!, request);
      }().timeout(request.timeout + const Duration(seconds: 15));
      // A redirect must not lead somewhere the request itself would have been refused.
      final host = Uri.tryParse(result.url)?.host ?? '';
      if (host.isNotEmpty && isBlockedFetchHost(host)) {
        throw StateError(
          'The page redirected to a private/internal address: "$host"',
        );
      }
      return result;
    } finally {
      try {
        await page?.close();
      } catch (_) {}
    }
  }

  Future<BrowserFetchResult> browserFetch(BrowserFetchRequest request) async {
    RenderPage? page;
    try {
      final result = await () async {
        page = await _factory(request.userAgent);
        return fetchWith(page!, request);
      }().timeout(request.timeout + const Duration(seconds: 15));
      final host = Uri.tryParse(result.url)?.host ?? '';
      if (host.isNotEmpty && isBlockedFetchHost(host)) {
        throw StateError(
          'The request redirected to a private/internal address: "$host"',
        );
      }
      return result;
    } finally {
      try {
        await page?.close();
      } catch (_) {}
    }
  }

  static String _message(Object error) => switch (error) {
    TimeoutException(:final message) =>
      '${message ?? 'The page timed out'} (waited ${(error.duration ?? Duration.zero).inSeconds}s)',
    FormatException(:final message) => message,
    StateError(:final message) => message,
    UnsupportedError(:final message) => '$message',
    _ => error.toString(),
  };
}
