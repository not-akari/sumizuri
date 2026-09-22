import 'dart:convert';
import 'dart:io';

import 'package:cookie_jar/cookie_jar.dart';
import 'package:cp949_codec/cp949_codec.dart';
import 'package:http/http.dart' as http;

import 'package:sumizuri/features/extensions/data/engines/js/bridge/cloudflare_detector.dart';
import 'package:sumizuri/features/extensions/data/engines/js/bridge/extension_cookie_jar.dart';

Future<Map<String, Object?>> fetchUrl({
  required String url,
  String method = 'GET',
  Map<String, String>? headers,
  String? body,
  http.Client? client,
  CookieJar? cookieJar,

  bool detectChallenges = true,
  bool? isAndroid,
  Duration? timeout,

  String? defaultUserAgent,
}) async {
  final trimmedUrl = url.trim();
  final uri = Uri.tryParse(trimmedUrl);
  if (uri == null || !uri.hasAuthority) {
    throw FormatException('Not a valid absolute URL: "$url"');
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw FormatException(
      'Only http/https URLs are allowed, got "${uri.scheme}"',
    );
  }
  if (isBlockedFetchHost(uri.host, isAndroid: isAndroid)) {
    throw StateError(
      'Refusing to fetch a private/internal address: "${uri.host}"',
    );
  }

  final request = http.Request(method, uri);
  if (headers != null) request.headers.addAll(headers);
  if (body != null) request.body = body;
  if (defaultUserAgent != null &&
      !request.headers.keys.any((k) => k.toLowerCase() == 'user-agent')) {
    request.headers['User-Agent'] = defaultUserAgent;
  }

  if (cookieJar != null) {
    final stored = await cookieJar.loadForRequest(uri);
    if (stored.isNotEmpty) {
      request.headers['cookie'] = stored
          .map((c) => '${c.name}=${c.value}')
          .join('; ');
    }
  }

  final ownedClient = client == null ? http.Client() : null;
  final http.Response response;
  try {
    var streamedResponse = (client ?? ownedClient!).send(request);
    if (timeout != null) streamedResponse = streamedResponse.timeout(timeout);
    response = await http.Response.fromStream(await streamedResponse);
  } finally {
    ownedClient?.close();
  }

  if (cookieJar != null) {
    final newCookies = parseSetCookieHeader(response.headers['set-cookie']);
    if (newCookies.isNotEmpty) {
      await cookieJar.saveFromResponse(uri, newCookies);
    }
  }

  final decodedBody = _decodeResponseBody(
    response.bodyBytes,
    response.headers['content-type'],
  );

  if (detectChallenges &&
      looksLikeChallenge(response.statusCode, response.headers, decodedBody)) {
    throw ChallengeDetectedException(trimmedUrl);
  }

  return {
    'statusCode': response.statusCode,
    'url': (response.request?.url ?? uri).toString(),
    'body': decodedBody,
    'headers': response.headers,
  };
}

String _decodeResponseBody(List<int> bytes, String? contentType) {
  final charset = RegExp(
    r'''charset\s*=\s*["']?([^;"'\s]+)''',
    caseSensitive: false,
  ).firstMatch(contentType ?? '')?.group(1)?.toLowerCase();

  switch (charset) {
    case 'euc-kr':
    case 'ks_c_5601-1987':
    case 'ksc5601':
    case 'cp949':
    case 'ms949':
    case 'windows-949':
      return cp949.decode(bytes, allowInvalid: true);
    default:
      return utf8.decode(bytes, allowMalformed: true);
  }
}

bool isBlockedFetchHost(String host, {bool? isAndroid}) {
  final address = InternetAddress.tryParse(host);

  if (address != null) {
    if (address.isLinkLocal || address.isMulticast) return true;
    final bytes = address.rawAddress;
    if (address.type == InternetAddressType.IPv4 && bytes[0] == 0) {
      return true;
    }
  }

  final android = isAndroid ?? Platform.isAndroid;
  if (android) {
    return false;
  }

  final lower = host.toLowerCase();
  if (lower == 'localhost' ||
      lower.endsWith('.localhost') ||
      lower.endsWith('.local')) {
    return true;
  }

  if (address == null) return false;
  if (address.isLoopback) return true;

  final bytes = address.rawAddress;
  if (address.type == InternetAddressType.IPv4) {
    if (bytes[0] == 10) return true;
    if (bytes[0] == 172 && bytes[1] >= 16 && bytes[1] <= 31) {
      return true;
    }
    if (bytes[0] == 192 && bytes[1] == 168) return true;
    if (bytes[0] == 100 && bytes[1] >= 64 && bytes[1] <= 127) {
      return true;
    }
  } else if (address.type == InternetAddressType.IPv6) {
    if (bytes[0] == 0xfc || bytes[0] == 0xfd) {
      return true;
    }
  }
  return false;
}
