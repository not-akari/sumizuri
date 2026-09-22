import 'dart:async';
import 'dart:convert';
import 'dart:io' show HandshakeException, SocketException;

import 'package:http/http.dart' as http;

import 'package:sumizuri/features/sync/models/sync_models.dart';

const syncProtocolVersion = 's1';

class SyncApiException implements Exception {
  const SyncApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class OAuthToken {
  const OAuthToken({required this.accessToken, required this.username});

  final String accessToken;
  final String username;
}

enum ServerAddressProblem { empty, invalid }

class SyncApiClient {
  SyncApiClient(this._http);

  final http.Client _http;

  static const _timeout = Duration(seconds: 60);

  Uri _uri(String server, String path) =>
      Uri.parse('${normalizeServer(server)}$path');

  static String normalizeServer(String server) {
    var value = server.trim();
    while (value.endsWith('/')) {
      value = value.substring(0, value.length - 1);
    }
    if (value.isEmpty || value.contains('://')) return value;
    final host = value.split('/').first.split(':').first.toLowerCase();
    return '${_isLocalHost(host) ? 'http' : 'https'}://$value';
  }

  /// What is wrong with a server address the user typed, or null when it can be used.
  static ServerAddressProblem? addressProblem(String server) {
    final address = normalizeServer(server);
    if (address.isEmpty) return ServerAddressProblem.empty;
    final uri = Uri.tryParse(address);
    final valid =
        uri != null &&
        uri.host.isNotEmpty &&
        (uri.scheme == 'http' || uri.scheme == 'https');
    return valid ? null : ServerAddressProblem.invalid;
  }

  static bool _isLocalHost(String host) {
    if (host == 'localhost' || host.endsWith('.local')) return true;
    final parts = host.split('.').map(int.tryParse).toList();
    if (parts.length != 4 || parts.any((p) => p == null)) return false;
    final a = parts[0]!;
    final b = parts[1]!;
    return a == 10 ||
        a == 127 ||
        (a == 192 && b == 168) ||
        (a == 172 && b >= 16 && b <= 31);
  }

  Future<void> checkVersion(String server) async {
    const notSumizuri =
        'That address answered, but it is not a Sumizuri sync server.';
    final http.Response response;
    try {
      response = await _get(_uri(server, '/api/version'));
    } on SyncApiException catch (error) {
      if (error.statusCode == 404) throw const SyncApiException(notSumizuri);
      rethrow;
    }
    final Map<String, dynamic> body;
    try {
      body = _decode(response);
    } on Object {
      throw const SyncApiException(notSumizuri);
    }
    final supported = (body['supported'] as List?) ?? const [];
    if (!supported.contains(syncProtocolVersion)) {
      throw const SyncApiException(
        'This server does not speak a sync protocol this app understands.',
      );
    }
  }

  Future<OAuthToken> exchangeToken(
    String server, {
    required String code,
    required String verifier,
    required String redirectUri,
  }) async {
    final response = await _post(_uri(server, '/api/oauth/token'), {
      'code': code,
      'codeVerifier': verifier,
      'redirectUri': redirectUri,
    });
    final body = _decode(response);
    final token = body['access_token'];
    final username = body['username'];
    if (token is! String || username is! String) {
      throw const SyncApiException('The server did not return a session.');
    }
    return OAuthToken(accessToken: token, username: username);
  }

  Future<List<SyncServerProfile>> listProfiles(
    String server,
    String token,
  ) async {
    final response = await _get(
      _uri(server, '/api/sync/profiles'),
      headers: {'Cookie': 'id=$token'},
    );
    final list = (_decode(response)['profiles'] as List?) ?? const [];
    return [for (final p in list.cast<Map<String, dynamic>>()) _profile(p)];
  }

  Future<SyncServerProfile> createProfile(
    String server,
    String token,
    String name,
  ) async {
    final response = await _post(
      _uri(server, '/api/sync/profiles'),
      {'name': name},
      headers: {'Cookie': 'id=$token'},
    );
    return _profile(_decode(response)['profile'] as Map<String, dynamic>);
  }

  SyncServerProfile _profile(Map<String, dynamic> json) =>
      SyncServerProfile(id: json['id'] as int, name: json['name'] as String);

  Future<Map<String, dynamic>> sync(
    String server,
    String token,
    Map<String, dynamic> body,
  ) async {
    final response = await _post(
      _uri(server, '/api/sync/v1'),
      body,
      headers: {'Cookie': 'id=$token'},
    );
    return _decode(response);
  }

  Future<http.Response> _get(
    Uri uri, {
    Map<String, String> headers = const {},
  }) => _send(() => _http.get(uri, headers: headers));

  Future<http.Response> _post(
    Uri uri,
    Map<String, dynamic> body, {
    Map<String, String> headers = const {},
  }) => _send(
    () => _http.post(
      uri,
      headers: {'Content-Type': 'application/json', ...headers},
      body: jsonEncode(body),
    ),
  );

  Future<http.Response> _send(Future<http.Response> Function() request) async {
    final http.Response response;
    try {
      response = await request().timeout(_timeout);
    } on HandshakeException catch (error) {
      if (error.toString().contains('WRONG_VERSION_NUMBER')) {
        throw const SyncApiException(
          'This address starts with https:// but the server does not use HTTPS. Try http:// instead.',
        );
      }
      throw SyncApiException('Could not make a secure connection: $error');
    } on TimeoutException {
      throw const SyncApiException(
        'The server did not answer in time. Check the address and your connection.',
      );
    } on SocketException catch (error) {
      throw SyncApiException(_unreachable(error));
    } on Exception catch (error) {
      throw SyncApiException('Could not reach the server: $error');
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw SyncApiException(
        _errorMessage(response),
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  static String _unreachable(SocketException error) {
    final text = '${error.message} ${error.osError?.message ?? ''}'
        .toLowerCase();
    if (text.contains('failed host lookup') ||
        text.contains('no address associated') ||
        text.contains('nodename nor servname')) {
      return 'Could not find that server. Check the address for typos.';
    }
    if (text.contains('refused')) {
      return 'Nothing answered at that address. Check the port, and that the server is running.';
    }
    if (text.contains('unreachable') || text.contains('no route')) {
      return 'That address cannot be reached from this network. On a home server, use the same Wi-Fi.';
    }
    return 'Could not reach the server: ${error.message}';
  }

  String _errorMessage(http.Response response) {
    try {
      final error = _decode(response)['error'];
      if (error is String && error.isNotEmpty) return error;
    } on Object {
      // Not JSON, so the status line is used.
    }
    return 'The server answered ${response.statusCode}.';
  }

  Map<String, dynamic> _decode(http.Response response) {
    final decoded = jsonDecode(utf8.decode(response.bodyBytes));
    if (decoded is! Map<String, dynamic>) {
      throw const SyncApiException('The server sent an unexpected response.');
    }
    return decoded;
  }
}
