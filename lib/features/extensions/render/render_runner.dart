import 'dart:async';
import 'dart:convert';

import 'package:sumizuri/features/extensions/render/render_request.dart';

abstract class RenderPage {
  /// Opens url and returns when the page finished loading, or throws if it could not.
  Future<void> load(String url);

  Future<String> eval(String script);

  Future<void> close();
}

const _pollInterval = Duration(milliseconds: 250);

Future<RenderResult> renderWith(
  RenderPage page,
  RenderRequest request, {
  Future<void> Function(Duration) delay = _realDelay,
}) async {
  final clock = Stopwatch()..start();
  await page
      .load(request.url)
      .timeout(
        request.timeout,
        onTimeout: () => throw TimeoutException(
          'The page did not finish loading',
          request.timeout,
        ),
      );

  final waitPattern = request.waitForResource == null
      ? null
      : RegExp(request.waitForResource!);

  var timedOut = false;
  while (true) {
    final state = await _probe(page, request.waitFor);
    final selectorReady = request.waitFor == null || state.hasSelector;
    final resourceReady =
        waitPattern == null || state.resources.any(waitPattern.hasMatch);
    if (state.complete && selectorReady && resourceReady) break;
    if (clock.elapsed >= request.timeout) {
      timedOut = true;
      break;
    }
    await delay(_pollInterval);
  }

  if (!timedOut) await delay(request.settle);
  return _read(page, request, timedOut);
}

Future<void> _realDelay(Duration d) => Future<void>.delayed(d);

class _State {
  const _State(this.complete, this.hasSelector, this.resources);

  final bool complete;
  final bool hasSelector;
  final List<String> resources;
}

Future<_State> _probe(RenderPage page, String? selector) async {
  final script =
      '''
(function () {
  var found = false;
  try { found = ${selector == null ? 'true' : '!!document.querySelector(${jsonEncode(selector)})'}; } catch (e) { found = false; }
  var payload = JSON.stringify({
    complete: document.readyState === 'complete',
    hasSelector: found,
    resources: performance.getEntriesByType('resource').map(function (e) { return e.name; })
  });
  return btoa(unescape(encodeURIComponent(payload)));
})()
''';
  final json = _decode(await page.eval(script));
  return _State(json['complete'] == true, json['hasSelector'] == true, [
    ...(json['resources'] as List? ?? const []).cast<String>(),
  ]);
}

Future<RenderResult> _read(
  RenderPage page,
  RenderRequest request,
  bool timedOut,
) async {
  final user = request.script;
  final script =
      '''
(function () {
  var result = null;
  ${user == null ? '' : '''
  try {
    var value = (0, eval)(${jsonEncode(user)});
    result = value === undefined || value === null ? null : String(value);
  } catch (e) { result = 'ERROR: ' + e.message; }
  '''}
  var payload = JSON.stringify({
    html: document.documentElement.outerHTML,
    url: location.href,
    resources: performance.getEntriesByType('resource').map(function (e) { return e.name; }),
    result: result
  });
  return btoa(unescape(encodeURIComponent(payload)));
})()
''';
  final json = _decode(await page.eval(script));
  final capture = request.capture == null ? null : RegExp(request.capture!);
  final seen = <String>{};
  return RenderResult(
    html: json['html'] as String? ?? '',
    url: json['url'] as String? ?? request.url,
    resources: [
      if (capture != null)
        for (final name
            in (json['resources'] as List? ?? const []).cast<String>())
          if (capture.hasMatch(name) && seen.add(name)) name,
    ],
    result: json['result'] as String?,
    timedOut: timedOut,
  );
}

/// Executes request inside [page] to utilize browser cookies directly.
Future<BrowserFetchResult> fetchWith(
  RenderPage page,
  BrowserFetchRequest request, {
  Future<void> Function(Duration) delay = _realDelay,
}) async {
  // Navigates to origin first to bypass CORS restrictions.
  final uri = Uri.parse(request.url);
  final origin = '${uri.scheme}://${uri.authority}/';
  await page
      .load(origin)
      .timeout(
        request.timeout,
        onTimeout: () => throw TimeoutException(
          'The site did not finish loading',
          request.timeout,
        ),
      );

  // Starts fetch script and polls for completion across platforms.
  await page.eval(_startFetchScript(request));

  final clock = Stopwatch()..start();
  while (true) {
    final json = _decode(await page.eval(_pollFetchScript));
    if (json['done'] == true) {
      final error = json['error'] as String?;
      if (error != null) throw StateError(error);
      return BrowserFetchResult.fromJson(json);
    }
    if (clock.elapsed >= request.timeout) {
      throw TimeoutException(
        'The page did not answer the request',
        request.timeout,
      );
    }
    await delay(_pollInterval);
  }
}

String _startFetchScript(BrowserFetchRequest request) {
  final options = <String, Object?>{
    'method': request.method,
    'credentials': 'include',
    if (request.headers != null && request.headers!.isNotEmpty)
      'headers': request.headers,
    if (request.body != null) 'body': request.body,
  };
  return '''
(function () {
  window.__sumizuriFetch = { done: false };
  fetch(${jsonEncode(request.url)}, ${jsonEncode(options)})
    .then(function (res) {
      return res.text().then(function (text) {
        var headers = {};
        res.headers.forEach(function (v, k) { headers[k] = v; });
        window.__sumizuriFetch = {
          done: true,
          statusCode: res.status,
          url: res.url,
          body: text,
          headers: headers
        };
      });
    })
    .catch(function (e) {
      window.__sumizuriFetch = { done: true, error: String((e && e.message) || e) };
    });
  return 'started';
})()
''';
}

const _pollFetchScript = '''
(function () {
  var s = window.__sumizuriFetch;
  var payload = JSON.stringify(s && s.done ? s : { done: false });
  return btoa(unescape(encodeURIComponent(payload)));
})()
''';

Map<String, dynamic> _decode(String raw) {
  final clean = raw.replaceAll('"', '').replaceAll(RegExp(r'\s'), '');
  if (clean.isEmpty || clean == 'null') {
    throw StateError('The page gave no answer (it may have been closed)');
  }
  try {
    return jsonDecode(utf8.decode(base64.decode(base64.normalize(clean))))
        as Map<String, dynamic>;
  } on FormatException catch (e) {
    throw StateError(
      'The page gave an answer that could not be read: ${e.message}',
    );
  }
}
