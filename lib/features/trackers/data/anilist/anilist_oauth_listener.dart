// Runs a short lived local HTTP server to catch AniList's OAuth redirect.
import 'dart:async';
import 'dart:io';

import 'package:sumizuri/features/trackers/data/anilist/anilist_api_client.dart';

const _successHtml = '''
<!DOCTYPE html>
<html>
  <head><title>Sumizuri</title></head>
  <body style="font-family: sans-serif; text-align: center; padding-top: 80px;">
    <h2>You're connected.</h2>
    <p>You can close this tab and go back to Sumizuri.</p>
  </body>
</html>
''';

class AniListOAuthListener {
  HttpServer? _server;

  // Returns the authorization code from the redirect, or null on timeout or cancel.
  Future<String?> waitForCode({
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final server = await HttpServer.bind(
      InternetAddress.loopbackIPv4,
      aniListLoopbackPort,
    );
    _server = server;
    try {
      final request = await server.first.timeout(timeout);
      final code = request.uri.queryParameters['code'];
      request.response
        ..statusCode = 200
        ..headers.contentType = ContentType.html
        ..write(_successHtml);
      await request.response.close();
      return code;
    } catch (_) {
      return null;
    } finally {
      await server.close(force: true);
      _server = null;
    }
  }

  Future<void> cancel() async {
    await _server?.close(force: true);
    _server = null;
  }
}
