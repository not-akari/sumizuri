// Sends one GraphQL operation to AniList and turns every way it can go wrong into a typed exception.
import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import 'package:sumizuri/features/trackers/data/anilist/anilist_request_queue.dart';

const _graphqlUrl = 'https://graphql.anilist.co';
const _timeout = Duration(seconds: 20);

/// Anything AniList (or the network) did instead of answering.
sealed class AniListException implements Exception {
  AniListException(this.message);

  final String message;

  @override
  String toString() => message;
}

class AniListTokenException extends AniListException {
  AniListTokenException([
    super.message = 'Your AniList login has expired. Log in again.',
  ]);
}

class AniListRateLimitException extends AniListException {
  AniListRateLimitException(this.retryAfter)
    : super(
        'AniList is busy. Try again in ${retryAfter.inSeconds.clamp(1, 600)} seconds.',
      );

  final Duration retryAfter;
}

class AniListNotFoundException extends AniListException {
  AniListNotFoundException([super.message = 'Not found on AniList.']);
}

class AniListRequestException extends AniListException {
  AniListRequestException(super.message, {this.status});

  final int? status;
}

class AniListNetworkException extends AniListException {
  AniListNetworkException([
    super.message = 'Could not reach AniList. Check your connection.',
  ]);
}

class AniListGraphQl {
  AniListGraphQl({http.Client? client, AniListRequestQueue? queue})
    : _client = client ?? http.Client(),
      queue = queue ?? AniListRequestQueue();

  final http.Client _client;

  final AniListRequestQueue queue;

  Future<Map<String, dynamic>> execute(
    String operation, {
    Map<String, dynamic> variables = const {},
    String? token,
    AniListPriority priority = AniListPriority.interactive,
  }) => queue.run(
    () => send(operation, variables: variables, token: token),
    priority: priority,
  );

  Future<Map<String, dynamic>> send(
    String operation, {
    Map<String, dynamic> variables = const {},
    String? token,
  }) async {
    final response = await _post(operation, variables, token);
    final body = _parse(response);
    final errors = body['errors'];
    if (errors is List && errors.isNotEmpty) throw _fromErrors(errors, token);
    return _dataOf(body, response);
  }

  Future<({Map<String, dynamic> data, Map<String, String> failures})> sendBatch(
    String operation, {
    required Map<String, dynamic> variables,
    required String token,
  }) async {
    final response = await _post(operation, variables, token);
    final body = _parse(response);
    final failures = <String, String>{};
    final errors = body['errors'];
    if (errors is List) {
      for (final error in errors) {
        final map = error is Map<String, dynamic> ? error : null;
        final exception = _fromErrors([error], token);
        // A dead token, or an error that cannot be pinned on one alias, is about the whole request.
        final alias = exception is AniListTokenException
            ? null
            : _aliasOf(map, operation);
        if (alias == null) throw exception;
        failures[alias] = exception.message;
      }
    }
    final data = body['data'];
    return (
      data: data is Map<String, dynamic> ? data : const <String, dynamic>{},
      failures: failures,
    );
  }

  String? _aliasOf(Map<String, dynamic>? error, String operation) {
    final path = error?['path'];
    if (path is List && path.isNotEmpty && path.first is String) {
      return path.first as String;
    }
    final locations = error?['locations'];
    if (locations is! List || locations.isEmpty) return null;
    final line = (locations.first as Map?)?['line'];
    final lines = operation.split('\n');
    if (line is! int || line < 1 || line > lines.length) return null;
    return RegExp(r'^\s*(\w+)\s*:').firstMatch(lines[line - 1])?.group(1);
  }

  Future<http.Response> _post(
    String operation,
    Map<String, dynamic> variables,
    String? token,
  ) async {
    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse(_graphqlUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              if (token != null) 'Authorization': 'Bearer $token',
            },
            body: jsonEncode({'query': operation, 'variables': variables}),
          )
          .timeout(_timeout);
    } on TimeoutException {
      throw AniListNetworkException();
    } on http.ClientException {
      throw AniListNetworkException();
    }
    _observeLimit(response);
    if (response.statusCode == 429) {
      final seconds = int.tryParse(response.headers['retry-after'] ?? '');
      throw AniListRateLimitException(Duration(seconds: seconds ?? 60));
    }
    return response;
  }

  Map<String, dynamic> _parse(http.Response response) {
    final Object? body;
    try {
      body = jsonDecode(response.body);
    } on FormatException {
      throw AniListRequestException(
        'AniList had a problem (${response.statusCode}). Try again later.',
        status: response.statusCode,
      );
    }
    if (body is! Map<String, dynamic>) {
      throw AniListRequestException(
        'AniList sent an unexpected answer.',
        status: response.statusCode,
      );
    }
    return body;
  }

  Map<String, dynamic> _dataOf(
    Map<String, dynamic> body,
    http.Response response,
  ) {
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw AniListRequestException(
        'AniList sent an answer without data.',
        status: response.statusCode,
      );
    }
    return data;
  }

  void _observeLimit(http.Response response) {
    final remaining = int.tryParse(
      response.headers['x-ratelimit-remaining'] ?? '',
    );
    final reset = int.tryParse(response.headers['x-ratelimit-reset'] ?? '');
    queue.observeLimit(
      remaining: remaining,
      resetAt: reset == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(reset * 1000),
    );
  }

  AniListException _fromErrors(List errors, String? token) {
    final first = errors.first is Map<String, dynamic>
        ? errors.first as Map<String, dynamic>
        : const <String, dynamic>{};
    var message =
        (first['message'] as String?) ?? 'AniList refused the request.';
    final validation = first['validation'];
    if (validation is Map) {
      final reasons = [
        for (final list in validation.values)
          if (list is List) ...list.whereType<String>(),
      ];
      if (reasons.isNotEmpty) message = reasons.join(' ');
    }
    final status = first['status'] as int?;
    if (status == 401 ||
        (token != null && message.toLowerCase().contains('invalid token'))) {
      return AniListTokenException();
    }
    if (status == 404) return AniListNotFoundException();
    return AniListRequestException(message, status: status);
  }

  void close() => _client.close();
}
