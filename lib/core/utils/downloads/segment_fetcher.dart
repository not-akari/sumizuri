import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import 'package:sumizuri/core/utils/downloads/byte_range.dart';
import 'package:sumizuri/core/utils/downloads/download_stopped.dart';

const _attempts = 5;
const _pieceTimeout = Duration(seconds: 30);

Future<void> defaultPause(Duration duration) => Future<void>.delayed(duration);

/// Fetches the pieces of a stream, with the pauses and retries a busy server needs. Shared by the HLS and DASH downloaders.
class SegmentFetcher {
  SegmentFetcher(this.client, this.headers, this.pause, this.shouldStop);

  final http.Client client;
  final Map<String, String> headers;
  final Future<void> Function(Duration) pause;
  final bool Function()? shouldStop;

  // A stopped download must not be retried, so this is checked wherever a retry could start.
  void _checkStop() {
    if (shouldStop?.call() ?? false) throw const DownloadStopped();
  }

  final _cache = <Uri, Future<Uint8List>>{};

  Future<String> text(Uri uri) async => (await _get(uri)).body;

  Future<Uint8List> bytes(Uri uri, {ByteRange? range}) async {
    final response = await _get(uri, range: range);
    final body = response.bodyBytes;
    if (range == null || response.statusCode == 206) return body;
    // The server ignored the range and sent the whole file.
    final end = range.offset + range.length;
    if (body.length < end) {
      throw HttpException('The file is shorter than its range', uri: uri);
    }
    return Uint8List.sublistView(body, range.offset, end);
  }

  /// Fetches once and reuses the result for the same address, such as a key several pieces share.
  Future<Uint8List> cached(Uri uri) =>
      _cache.putIfAbsent(uri, () => bytes(uri));

  Future<http.Response> _get(Uri uri, {ByteRange? range}) async {
    final sent = range == null
        ? headers
        : {...headers, 'Range': 'bytes=${range.offset}-${range.last}'};
    for (var attempt = 0; ; attempt++) {
      _checkStop();
      http.Response? response;
      Object? error;
      try {
        response = await client.get(uri, headers: sent).timeout(_pieceTimeout);
      } catch (e) {
        // A client closed to stop the download fails its request, which is not a network problem.
        _checkStop();
        if (!_isTransient(e)) rethrow;
        error = e;
      }
      if (response != null) {
        if (response.statusCode == 200 ||
            (range != null && response.statusCode == 206)) {
          return response;
        }
        final retryable =
            response.statusCode == 429 || response.statusCode >= 500;
        if (!retryable) {
          throw HttpException('HTTP ${response.statusCode}', uri: uri);
        }
      }
      if (attempt >= _attempts - 1) {
        if (error != null) throw error;
        throw HttpException('HTTP ${response!.statusCode}', uri: uri);
      }
      await pause(_waitBefore(response, attempt));
      _checkStop();
    }
  }

  bool _isTransient(Object error) =>
      error is TimeoutException ||
      error is SocketException ||
      error is http.ClientException;

  // What the server asks for when it sends a Retry-After, else 1, 2, 4, 8 seconds.
  Duration _waitBefore(http.Response? response, int attempt) {
    final asked = int.tryParse(response?.headers['retry-after'] ?? '');
    if (asked != null && asked >= 0) {
      return Duration(seconds: asked.clamp(0, 30));
    }
    return Duration(seconds: 1 << attempt);
  }
}
