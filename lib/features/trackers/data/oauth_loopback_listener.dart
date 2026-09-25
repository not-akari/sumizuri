// A short-lived local HTTP server that catches a tracker's OAuth redirect.
import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// The words on the page the browser lands on. They come from the app's
/// translations, so this file holds none of its own.
class OAuthPageText {
  const OAuthPageText({
    required this.connected,
    required this.refused,
    required this.closeHint,
  });

  final String connected;
  final String refused;
  final String closeHint;

  String html({required bool accepted}) {
    const escape = HtmlEscape();
    return '<!DOCTYPE html><html><head><meta charset="utf-8">'
        '<title>Sumizuri</title></head>'
        '<body style="font-family: sans-serif; text-align: center; padding-top: 80px;">'
        '<h2>${escape.convert(accepted ? connected : refused)}</h2>'
        '<p>${escape.convert(closeHint)}</p>'
        '</body></html>';
  }
}

/// Waits on the redirect a tracker sends the browser to.
class OAuthLoopbackListener {
  OAuthLoopbackListener({
    required this.port,
    required this.path,
    required this.page,
  });

  final int port;

  /// The path the tracker redirects to, such as `/mal-callback`. Other requests are ignored.
  final String path;
  final OAuthPageText page;
  HttpServer? _server;

  /// The authorization code from the redirect. Null on timeout, on cancel, when
  /// the person refused, when the port is taken, or when [state] is given and
  /// does not match the one that came back.
  Future<String?> waitForCode({
    String? state,
    Duration timeout = const Duration(minutes: 3),
  }) async {
    final HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
    } on SocketException {
      return null;
    }
    _server = server;
    final completer = Completer<String?>();
    final subscription = server.listen(
      (request) async {
        if (request.uri.path != path || completer.isCompleted) {
          request.response.statusCode = 404;
          await request.response.close();
          return;
        }
        final query = request.uri.queryParameters;
        final code = query['code'];
        final accepted =
            code != null && (state == null || query['state'] == state);
        request.response
          ..statusCode = 200
          ..headers.contentType = ContentType.html
          ..write(page.html(accepted: accepted));
        await request.response.close();
        completer.complete(accepted ? code : null);
      },
      onDone: () {
        // Closed by [cancel], so nobody is waiting any more.
        if (!completer.isCompleted) completer.complete(null);
      },
    );
    try {
      return await completer.future.timeout(timeout, onTimeout: () => null);
    } finally {
      await subscription.cancel();
      await server.close(force: true);
      _server = null;
    }
  }

  Future<void> cancel() async {
    await _server?.close(force: true);
    _server = null;
  }
}
