import 'package:sumizuri/features/extensions/data/engines/js/bridge/http_bridge.dart';

const defaultRenderTimeout = Duration(seconds: 20);
const maxRenderTimeout = Duration(seconds: 60);

class RenderRequest {
  const RenderRequest({
    required this.url,
    this.waitFor,
    this.waitForResource,
    this.capture,
    this.script,
    this.userAgent,
    this.timeout = defaultRenderTimeout,
    this.settle = const Duration(milliseconds: 300),
  });

  factory RenderRequest.fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    if (url is! String) {
      throw const FormatException('host.render needs a url');
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasAuthority) {
      throw FormatException('Not a valid absolute URL: "$url"');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw FormatException(
        'Only http/https pages can be rendered, got "${uri.scheme}"',
      );
    }
    if (isBlockedFetchHost(uri.host)) {
      throw StateError(
        'Refusing to render a private/internal address: "${uri.host}"',
      );
    }

    String? text(String key) {
      final value = json[key];
      if (value == null) return null;
      if (value is! String || value.trim().isEmpty) {
        throw FormatException('host.render: "$key" must be a non-empty string');
      }
      return value;
    }

    String? pattern(String key) {
      final value = text(key);
      if (value == null) return null;
      try {
        RegExp(value);
      } on FormatException catch (e) {
        throw FormatException(
          'host.render: "$key" is not a valid pattern: ${e.message}',
        );
      }
      return value;
    }

    final timeoutMs = json['timeout'];
    if (timeoutMs != null && (timeoutMs is! num || timeoutMs <= 0)) {
      throw const FormatException(
        'host.render: "timeout" must be a number of milliseconds',
      );
    }
    final timeout = timeoutMs == null
        ? defaultRenderTimeout
        : Duration(milliseconds: (timeoutMs as num).toInt());

    return RenderRequest(
      url: uri.toString(),
      waitFor: text('waitFor'),
      waitForResource: pattern('waitForResource'),
      capture: pattern('capture'),
      script: text('script'),
      userAgent: text('userAgent'),
      timeout: timeout > maxRenderTimeout ? maxRenderTimeout : timeout,
    );
  }

  final String url;

  final String? waitFor;

  final String? waitForResource;

  final String? capture;

  final String? script;

  final String? userAgent;

  final Duration timeout;

  final Duration settle;

  Map<String, Object?> toJson() => {
    'kind': 'render',
    'url': url,
    'waitFor': waitFor,
    'waitForResource': waitForResource,
    'capture': capture,
    'script': script,
    'userAgent': userAgent,
    'timeout': timeout.inMilliseconds,
    'settle': settle.inMilliseconds,
  };
}

class RenderResult {
  const RenderResult({
    required this.html,
    required this.url,
    this.resources = const [],
    this.result,
    this.timedOut = false,
  });

  factory RenderResult.fromJson(Map<String, dynamic> json) => RenderResult(
    html: json['html'] as String,
    url: json['url'] as String,
    resources: [...?(json['resources'] as List?)?.cast<String>()],
    result: json['result'] as String?,
    timedOut: json['timedOut'] as bool? ?? false,
  );

  final String html;

  final String url;

  final List<String> resources;

  final String? result;

  /// True when what was waited for never appeared. The page is still returned, to see why.
  final bool timedOut;

  Map<String, Object?> toJson() => {
    'html': html,
    'url': url,
    'resources': resources,
    'result': result,
    'timedOut': timedOut,
  };
}

/// HTTP-shaped request executed inside a browser page to preserve HttpOnly cookies.
class BrowserFetchRequest {
  const BrowserFetchRequest({
    required this.url,
    this.method = 'GET',
    this.headers,
    this.body,
    this.userAgent,
    this.timeout = defaultRenderTimeout,
  });

  factory BrowserFetchRequest.fromJson(Map<String, dynamic> json) {
    final url = json['url'];
    if (url is! String) {
      throw const FormatException('browserFetch needs a url');
    }
    final uri = Uri.tryParse(url.trim());
    if (uri == null || !uri.hasAuthority) {
      throw FormatException('Not a valid absolute URL: "$url"');
    }
    if (uri.scheme != 'http' && uri.scheme != 'https') {
      throw FormatException(
        'Only http/https URLs are allowed, got "${uri.scheme}"',
      );
    }
    if (isBlockedFetchHost(uri.host)) {
      throw StateError(
        'Refusing to fetch a private/internal address: "${uri.host}"',
      );
    }
    final timeoutMs = json['timeout'];
    final timeout = timeoutMs == null
        ? defaultRenderTimeout
        : Duration(milliseconds: (timeoutMs as num).toInt());
    return BrowserFetchRequest(
      url: uri.toString(),
      method: (json['method'] as String?) ?? 'GET',
      headers: (json['headers'] as Map?)?.cast<String, String>(),
      body: json['body'] as String?,
      userAgent: json['userAgent'] as String?,
      timeout: timeout > maxRenderTimeout ? maxRenderTimeout : timeout,
    );
  }

  final String url;
  final String method;
  final Map<String, String>? headers;
  final String? body;
  final String? userAgent;
  final Duration timeout;

  Map<String, Object?> toJson() => {
    'kind': 'fetch',
    'url': url,
    'method': method,
    'headers': headers,
    'body': body,
    'userAgent': userAgent,
    'timeout': timeout.inMilliseconds,
  };
}

class BrowserFetchResult {
  const BrowserFetchResult({
    required this.statusCode,
    required this.url,
    required this.body,
    required this.headers,
  });

  factory BrowserFetchResult.fromJson(Map<String, dynamic> json) =>
      BrowserFetchResult(
        statusCode: json['statusCode'] as int? ?? 0,
        url: json['url'] as String? ?? '',
        body: json['body'] as String? ?? '',
        headers: {...?(json['headers'] as Map?)?.cast<String, String>()},
      );

  final int statusCode;
  final String url;
  final String body;
  final Map<String, String> headers;

  Map<String, Object?> toJson() => {
    'statusCode': statusCode,
    'url': url,
    'body': body,
    'headers': headers,
  };
}
