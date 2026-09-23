// Runs inside the extension isolate, executing JavaScript and answering host bridge calls.
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:flutter/services.dart';
import 'package:flutter_js/flutter_js.dart';
import 'package:http/http.dart' as http;

import 'package:sumizuri/features/extensions/data/engines/js/bridge/browser_fetch_flag.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/cloudflare_detector.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/crypto_bridge.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/extension_cookie_jar.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/extension_storage.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/html_bridge.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/http_bridge.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/trace_log.dart';
import 'package:sumizuri/features/extensions/data/engines/js/js_prelude.dart';
import 'package:sumizuri/features/extensions/render/render_request.dart';

void jsIsolateEntryPoint(
  (
    SendPort,
    RootIsolateToken,
    String,
    String,
    int,
    String?,
    bool,
    SendPort?,
    String,
  )
  args,
) {
  final (
    mainSendPort,
    rootIsolateToken,
    cookieDirPath,
    storageDirPath,
    timeoutSeconds,
    userAgent,
    isTesting,
    renderPort,
    stdlib,
  ) = args;
  BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);

  final commandPort = ReceivePort();
  mainSendPort.send(commandPort.sendPort);

  final storage = ExtensionStorage(storageDirPath);
  // Only a Source Editor test keeps a trace, since a real run would pay for unread bodies.
  final trace = isTesting ? TraceLog() : null;
  JavascriptRuntime? runtime;

  final httpClient = http.Client();

  var inFlight = 0;

  commandPort.listen((message) async {
    final (String method, String argsJson, SendPort replyPort) =
        message as (String, String, SendPort);

    if (method == 'dispose') {
      final deadline = DateTime.now().add(const Duration(seconds: 2));
      while (inFlight > 0 && DateTime.now().isBefore(deadline)) {
        await Future<void>.delayed(const Duration(milliseconds: 40));
      }
      // Still busy after that: the runtime is left for the isolate's end.
      if (inFlight == 0) runtime?.dispose();
      httpClient.close();
      commandPort.close();
      replyPort.send((true, ''));
      return;
    }

    inFlight++;
    try {
      if (method == 'takeTrace') {
        replyPort.send((true, jsonEncode(trace?.take() ?? const [])));
        return;
      }

      if (method == 'getPreferences') {
        replyPort.send((true, jsonEncode(storage.allPreferences())));
        return;
      }

      if (method == 'setPreferences') {
        final map = (jsonDecode(argsJson) as Map).cast<String, dynamic>();
        storage.setPreferences(map);
        replyPort.send((true, ''));
        return;
      }

      if (method == 'setPreference') {
        final map = (jsonDecode(argsJson) as Map).cast<String, dynamic>();
        storage.setPreference(map['key'] as String, map['value']);
        replyPort.send((true, ''));
        return;
      }

      try {
        if (method == 'init') {
          final extensionSource = jsonDecode(argsJson) as String;
          runtime = await _initRuntime(
            extensionSource,
            stdlib,
            createCookieJar(cookieDirPath),
            httpClient,
            Duration(seconds: timeoutSeconds),
            userAgent,
            storage,
            isTesting,
            trace,
            renderPort,
            await sourceUsesBrowserFetch(cookieDirPath),
          );
          replyPort.send((true, ''));
          return;
        }

        final rt = runtime;
        if (rt == null) {
          replyPort.send((false, 'Extension not initialized'));
          return;
        }
        final result = method == 'metadata'
            ? _readMetadata(rt)
            : await _callExtensionMethod(rt, method, argsJson);
        replyPort.send((true, result));
      } catch (error) {
        replyPort.send((false, error.toString()));
      }
    } finally {
      inFlight--;
    }
  });
}

Future<JavascriptRuntime> _initRuntime(
  String extensionSource,
  String stdlib,
  CookieJar cookieJar,
  http.Client httpClient,
  Duration timeout,
  String? userAgent,
  ExtensionStorage storage,
  bool isTesting,
  TraceLog? trace,
  SendPort? renderPort,
  bool useBrowserFetch,
) async {
  final runtime = getJavascriptRuntime(xhr: false);

  runtime.onMessage('fetchUrl', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    final options = (map['options'] as Map?)?.cast<String, dynamic>() ?? {};
    final method = (options['method'] as String?) ?? 'GET';
    final watch = Stopwatch()..start();
    try {
      final result = useBrowserFetch
          ? (await _fetchUrlViaBrowser(
              renderPort: renderPort,
              url: map['url'] as String,
              method: method,
              headers: (options['headers'] as Map?)?.cast<String, String>(),
              body: options['body'] as String?,
              timeout: timeout,
              userAgent: userAgent,
            ))
          : await fetchUrl(
              url: map['url'] as String,
              method: method,
              headers: (options['headers'] as Map?)?.cast<String, String>(),
              body: options['body'] as String?,
              client: httpClient,
              cookieJar: cookieJar,
              timeout: timeout,
              defaultUserAgent: userAgent,
            );
      trace?.addFetch(
        method: method,
        url: map['url'] as String,
        requestHeaders: (options['headers'] as Map?)?.cast<String, dynamic>(),
        requestBody: options['body'] as String?,
        elapsedMs: watch.elapsedMilliseconds,
        result: result,
      );
      return jsonEncode(result);
    } on ChallengeDetectedException catch (error) {
      trace?.addFetch(
        method: method,
        url: map['url'] as String,
        requestHeaders: (options['headers'] as Map?)?.cast<String, dynamic>(),
        requestBody: options['body'] as String?,
        elapsedMs: watch.elapsedMilliseconds,
        error:
            'A bot check (Cloudflare or similar) answered instead of the page',
      );
      return jsonEncode({'error': '__CHALLENGE__:${error.url}'});
    } catch (error) {
      trace?.addFetch(
        method: method,
        url: map['url'] as String,
        requestHeaders: (options['headers'] as Map?)?.cast<String, dynamic>(),
        requestBody: options['body'] as String?,
        elapsedMs: watch.elapsedMilliseconds,
        error: error.toString(),
      );
      return jsonEncode({'error': error.toString()});
    }
  });

  void answer(String name, Object? Function(Map<String, dynamic> args) work) {
    runtime.onMessage(name, (dynamic args) async {
      try {
        return jsonEncode(work((args as Map).cast<String, dynamic>()));
      } catch (error) {
        return jsonEncode({'error': _cryptoMessage(error)});
      }
    });
  }

  answer('queryHtml', (map) {
    final watch = Stopwatch()..start();
    final found = queryHtml(map['html'] as String, map['selector'] as String);
    trace?.add('query', {
      'selector': map['selector'],
      'matches': found.length,
      'took': watch.elapsedMilliseconds,
      'pageLength': (map['html'] as String).length,
    });
    return found;
  });
  answer(
    'parseHtml',
    (map) => {'id': sharedHtmlPages.parse(map['html'] as String)},
  );
  answer('selectHtml', (map) {
    final watch = Stopwatch()..start();
    final result = sharedHtmlPages.select(
      map['page'] as int,
      from: map['from'] as int?,
      css: map['css'] as String?,
      xpath: map['xpath'] as String?,
      withHtml: map['html'] as bool? ?? true,
      limit: map['limit'] as int?,
    );
    trace?.add('query', {
      if (map['css'] != null) 'selector': map['css'] else 'xpath': map['xpath'],
      'matches': ((result['items'] ?? result['values']) as List).length,
      'took': watch.elapsedMilliseconds,
    });
    return result;
  });

  answer('log', (map) {
    trace?.add('log', {'level': map['level'], 'text': map['text']});
    return {'ok': true};
  });
  answer('trace', (map) {
    trace?.add(map['kind'] as String, {
      ...?(map['data'] as Map?)?.cast<String, Object?>(),
    });
    return {'ok': true};
  });

  runtime.onMessage('render', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    final watch = Stopwatch()..start();
    final url = '${map['url']}';
    void record({RenderResult? result, String? error}) {
      trace?.addFetch(
        method: 'RENDER',
        url: url,
        requestHeaders: null,
        requestBody: [
          for (final key in const [
            'waitFor',
            'waitForResource',
            'capture',
            'script',
          ])
            if (map[key] != null) '$key=${map[key]}',
        ].join('  '),
        elapsedMs: watch.elapsedMilliseconds,
        result: result == null
            ? null
            : {
                'statusCode': 200,
                'url': result.url,
                'body': result.html,
                'headers': const {},
              },
        error: error,
      );
    }

    try {
      final port = renderPort;
      if (port == null) {
        throw StateError('Rendering pages is not available in this app.');
      }
      final request = RenderRequest.fromJson(map);
      final reply = ReceivePort();
      port.send((request.toJson(), reply.sendPort));
      final (bool ok, Object? payload) = await reply.first.timeout(
        request.timeout + const Duration(seconds: 30),
      ) as (bool, Object?);
      reply.close();
      if (!ok) throw StateError(payload as String);
      final result = RenderResult.fromJson(
        (payload as Map).cast<String, dynamic>(),
      );
      record(
        result: result,
        error: result.timedOut
            ? 'Timed out waiting for the page (the page as it was is returned)'
            : null,
      );
      return jsonEncode(result.toJson());
    } catch (error) {
      record(error: _cryptoMessage(error));
      return jsonEncode({'error': _cryptoMessage(error)});
    }
  });

  runtime.onMessage('hash', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    try {
      final hash = hashInput(
        map['algorithm'] as String,
        map['input'] as String,
      );
      return jsonEncode({'hash': hash});
    } catch (error) {
      return jsonEncode({'error': error.toString()});
    }
  });

  runtime.onMessage('aes', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    try {
      trace?.add('crypto', {
        'op': (map['encrypt'] as bool) ? 'aes encrypt' : 'aes decrypt',
        'mode': map['mode'] ?? 'cbc',
      });
      final value = aesTransform(
        encrypt: map['encrypt'] as bool,
        data: map['data'] as String,
        mode: (map['mode'] as String?) ?? 'cbc',
        key: map['key'] as String?,
        iv: map['iv'] as String?,
        passphrase: map['passphrase'] as String?,
        keyEncoding: map['keyEncoding'] as String?,
        ivEncoding: map['ivEncoding'] as String?,
        dataEncoding: map['dataEncoding'] as String?,
        output: map['output'] as String?,
        padding: (map['padding'] as String?) ?? 'pkcs7',
      );
      return jsonEncode({'value': value});
    } catch (error) {
      trace?.add('crypto', {'op': 'aes', 'error': _cryptoMessage(error)});
      return jsonEncode({'error': _cryptoMessage(error)});
    }
  });

  runtime.onMessage('hmac', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    try {
      final value = hmacInput(
        algorithm: map['algorithm'] as String,
        key: map['key'] as String,
        input: map['input'] as String,
        keyEncoding: map['keyEncoding'] as String?,
        output: map['output'] as String?,
      );
      return jsonEncode({'value': value});
    } catch (error) {
      return jsonEncode({'error': _cryptoMessage(error)});
    }
  });

  runtime.onMessage('storageGet', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    final val = storage.get(map['key'] as String);
    return jsonEncode({'value': val});
  });

  runtime.onMessage('storageSet', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    storage.set(map['key'] as String, map['value']);
    return jsonEncode({'ok': true});
  });

  runtime.onMessage('storageDelete', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    storage.delete(map['key'] as String);
    return jsonEncode({'ok': true});
  });

  runtime.onMessage('storageClear', (dynamic args) async {
    storage.clear();
    return jsonEncode({'ok': true});
  });

  runtime.onMessage('storageAll', (dynamic args) async {
    return jsonEncode({'values': storage.all()});
  });

  runtime.onMessage('preferenceGet', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    final val = storage.getPreference(map['key'] as String);
    return jsonEncode({'value': val});
  });

  runtime.onMessage('preferenceSet', (dynamic args) async {
    final map = (args as Map).cast<String, dynamic>();
    storage.setPreference(map['key'] as String, map['value']);
    return jsonEncode({'ok': true});
  });

  runtime.onMessage('preferenceAll', (dynamic args) async {
    return jsonEncode({'values': storage.allPreferences()});
  });

  runtime.evaluate(jsPrelude);
  // A source that needs no newer helper must still work if the library cannot load.
  final stdlibResult = runtime.evaluate(stdlib);
  if (stdlibResult.isError) {
    runtime.evaluate(
      'globalThis.host.stdlibError = ${jsonEncode(stdlibResult.stringResult)};',
    );
  }
  runtime.evaluate(
    'globalThis.host.isTesting = ${isTesting ? "true" : "false"};',
  );
  runtime.evaluate(extensionSource);
  _validateContract(runtime);
  return runtime;
}

/// Proxies fetch through a real browser page to preserve HttpOnly cookies.
Future<Map<String, Object?>> _fetchUrlViaBrowser({
  required SendPort? renderPort,
  required String url,
  required String method,
  required Map<String, String>? headers,
  required String? body,
  required Duration timeout,
  required String? userAgent,
}) async {
  final port = renderPort;
  if (port == null) {
    throw StateError(
      'This source needs a real browser to fetch pages, which is not '
      'available on this platform.',
    );
  }
  final request = BrowserFetchRequest(
    url: url,
    method: method,
    headers: headers,
    body: body,
    userAgent: userAgent,
    timeout: timeout,
  );
  final reply = ReceivePort();
  port.send((request.toJson(), reply.sendPort));
  final (bool ok, Object? payload) = await reply.first
          .timeout(request.timeout + const Duration(seconds: 30))
      as (bool, Object?);
  reply.close();
  if (!ok) throw StateError(payload as String);
  final result = BrowserFetchResult.fromJson(
    (payload as Map).cast<String, dynamic>(),
  );
  if (looksLikeChallenge(result.statusCode, result.headers, result.body)) {
    // Challenge expired; throw ChallengeDetectedException to trigger solver UI.
    throw ChallengeDetectedException(url);
  }
  return result.toJson();
}

// The message from a failed crypto call, without the exception type in front of it.
String _cryptoMessage(Object error) => switch (error) {
  FormatException(:final message) => message,
  StateError(:final message) => message,
  ArgumentError(:final message) => '$message',
  _ => error.toString(),
};

const _requiredMethods = [
  'search',
  'getPopular',
  'getLatest',
  'getChapterList',
];

const _contentMethods = ['getPageList', 'getVideoList'];

void _validateContract(JavascriptRuntime runtime) {
  final check = runtime.evaluate('''
    (function () {
      if (typeof extension !== 'object' || extension === null) {
        return 'no global "extension" object is defined';
      }
      var required = ${jsonEncode(_requiredMethods)};
      var missing = required.filter(function (name) {
        return typeof extension[name] !== 'function';
      });
      if (missing.length) return 'missing required method(s): ' + missing.join(', ');
      var content = ${jsonEncode(_contentMethods)};
      var hasContent = content.some(function (name) {
        return typeof extension[name] === 'function';
      });
      return hasContent ? '' : 'define getPageList (manga, novels) or getVideoList (anime)';
    })()
  ''');
  final message = check.stringResult;
  if (message.isNotEmpty) {
    throw StateError(message);
  }
}

String _readMetadata(JavascriptRuntime runtime) {
  final result = runtime.evaluate('''
    (function () {
      function pick(onExtension, globalName) {
        if (typeof extension[onExtension] === 'string') return extension[onExtension];
        if (typeof globalName !== 'undefined' && typeof globalName === 'string') return globalName;
        return null;
      }
      var headers = (typeof extension.headers === 'object' && extension.headers !== null && !Array.isArray(extension.headers))
        ? extension.headers
        : (typeof HEADERS === 'object' && HEADERS !== null && !Array.isArray(HEADERS))
          ? HEADERS
          : (typeof __sourceConfig === 'object' && __sourceConfig !== null && typeof __sourceConfig.headers === 'object' && !Array.isArray(__sourceConfig.headers))
            ? __sourceConfig.headers
            : null;
      return JSON.stringify({
        name: pick('name', typeof NAME === 'undefined' ? undefined : NAME),
        lang: pick('lang', typeof LANG === 'undefined' ? undefined : LANG),
        iconUrl: pick('iconUrl', typeof ICON_URL === 'undefined' ? undefined : ICON_URL),
        baseUrl: pick('baseUrl', typeof BASE_URL === 'undefined' ? undefined : BASE_URL),
        hasDetails: typeof extension.getDetails === 'function',
        hasComments: typeof extension.getComments === 'function',
        hasChapterComments: typeof extension.getChapterComments === 'function',
        hasFilters: typeof extension.getFilters === 'function',
        hasPreferences: typeof extension.getSourcePreferences === 'function' || typeof getSourcePreferences === 'function',
        rateLimitMs: typeof extension.rateLimitMs === 'number'
            ? extension.rateLimitMs
            : (typeof RATE_LIMIT_MS === 'number' ? RATE_LIMIT_MS : null),
        headers: headers,
      });
    })()
  ''');
  return result.stringResult;
}

Future<String> _callExtensionMethod(
  JavascriptRuntime runtime,
  String method,
  String argsJson,
) async {
  final args = (jsonDecode(argsJson) as List).map(jsonEncode).join(', ');
  final code =
      '''
    (async function () {
      var fn = typeof extension.$method === 'function' ? extension.$method : null;
      if (!fn && '$method' === 'getSourcePreferences' && typeof getSourcePreferences === 'function') {
        fn = getSourcePreferences;
      }
      if (!fn) {
        // A stable marker that js_extension_service.dart matches on to raise a NotImplementedFailure.
        throw new Error('__NOT_IMPLEMENTED__:$method');
      }
      var result = await fn($args);
      return JSON.stringify(result);
    })()
  ''';
  final evalResult = await runtime.evaluateAsync(code);
  runtime.executePendingJob();
  final resolved = await runtime.handlePromise(evalResult);
  if (resolved.isError) {
    throw StateError(resolved.stringResult);
  }
  return resolved.stringResult;
}
