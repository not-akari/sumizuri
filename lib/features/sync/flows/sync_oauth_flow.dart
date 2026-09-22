import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:sumizuri/features/sync/data/sync_api_client.dart';

typedef UrlLauncher = Future<bool> Function(Uri url);

Future<bool> _launchExternal(Uri url) =>
    launchUrl(url, mode: LaunchMode.externalApplication);

const _doneHtml = r'''
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>Sumizuri</title>
    <style>
      /* Always the ink palette, since a white flash between the browser and the app is glaring. */
      :root {
        color-scheme: dark;
        --paper: #17130f; --ink: #e9dfc6; --ash: #8d8272; --seal: #c33a1e;
        --card: #221d17; --line: #3a3226;
      }
      * { box-sizing: border-box; }
      html, body { height: 100%; margin: 0; }
      body {
        display: flex; align-items: center; justify-content: center; padding: 24px;
        color: var(--ink); background-color: var(--paper);
        background-image:
          radial-gradient(circle 60vmin at 7.5% 2.5%, color-mix(in srgb, var(--seal) 15%, transparent), transparent),
          radial-gradient(circle 52vmin at 95% 77.5%, color-mix(in srgb, var(--ink) 6%, transparent), transparent),
          radial-gradient(circle 34vmin at 22.5% 95%, color-mix(in srgb, var(--seal) 10%, transparent), transparent);
        font-family: "Work Sans", "Segoe UI", system-ui, sans-serif;
      }
      main {
        width: 100%; max-width: 420px; padding: 36px 32px 32px;
        background: var(--card); border: 1px solid var(--line);
        border-radius: 14px 4px 14px 4px; text-align: left;
      }
      .seal {
        display: grid; place-items: center; width: 44px; height: 44px; margin-bottom: 22px;
        color: #fff7f3; background: var(--seal); border-radius: 4px 12px 4px 12px;
        font: 600 22px "Shippori Mincho", "Yu Mincho", "Hiragino Mincho ProN", serif;
      }
      h1 {
        margin: 0; font: 700 30px/1.15 "Shippori Mincho", "Yu Mincho", "Hiragino Mincho ProN", Georgia, serif;
        letter-spacing: -0.01em;
      }
      svg { display: block; width: 128px; height: 8px; margin: 10px 0 14px; color: var(--seal); }
      p { margin: 0; font-size: 14.5px; line-height: 1.55; color: var(--ash); }
    </style>
  </head>
  <body>
    <main>
      <div class="seal" aria-hidden="true">墨</div>
      <h1>You're signed in.</h1>
      <svg viewBox="0 0 100 8" preserveAspectRatio="none" aria-hidden="true">
        <path d="M0 6 C20 1 40 9 60 4 C75 0.5 85 7 100 3" fill="none" stroke="currentColor"
              stroke-width="1.6" stroke-linecap="round" vector-effect="non-scaling-stroke"/>
      </svg>
      <p>You can close this tab and go back to Sumizuri.</p>
    </main>
  </body>
</html>
''';

class SyncOAuthSession {
  const SyncOAuthSession({
    required this.server,
    required this.username,
    required this.token,
  });

  final String server;
  final String username;
  final String token;
}

class SyncOAuthFlow {
  SyncOAuthFlow({
    required this._api,
    this._launcher = _launchExternal,
    this._timeout = const Duration(minutes: 5),
  });

  final SyncApiClient _api;
  final UrlLauncher _launcher;
  final Duration _timeout;

  HttpServer? _server;
  Completer<String>? _code;

  Future<SyncOAuthSession> authorize(String server) async {
    final base = SyncApiClient.normalizeServer(server);
    await _api.checkVersion(base);

    final listener = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server = listener;
    final code = _code = Completer<String>();

    final verifier = _randomToken();
    final state = _randomToken();
    final redirectUri = 'http://127.0.0.1:${listener.port}/callback';
    final authorizeUrl = Uri.parse('$base/api/oauth/authorize').replace(
      queryParameters: {
        'redirect_uri': redirectUri,
        'code_challenge': _challenge(verifier),
        'code_challenge_method': 'S256',
        'state': state,
      },
    );

    unawaited(_listen(listener, state, code));
    try {
      if (!await _launcher(authorizeUrl)) {
        throw const SyncApiException('Could not open the browser.');
      }
      final granted = await code.future.timeout(
        _timeout,
        onTimeout: () => throw const SyncApiException('Sign-in timed out.'),
      );
      final token = await _api.exchangeToken(
        base,
        code: granted,
        verifier: verifier,
        redirectUri: redirectUri,
      );
      return SyncOAuthSession(
        server: base,
        username: token.username,
        token: token.accessToken,
      );
    } finally {
      await cancel();
    }
  }

  Future<void> cancel() async {
    final pending = _code;
    if (pending != null && !pending.isCompleted) {
      pending.completeError(const SyncApiException('Sign-in cancelled.'));
    }
    _code = null;
    final server = _server;
    _server = null;
    await server?.close(force: true);
  }

  Future<void> _listen(
    HttpServer server,
    String state,
    Completer<String> code,
  ) async {
    await for (final request in server) {
      if (request.uri.path != '/callback') {
        request.response.statusCode = 404;
        await request.response.close();
        continue;
      }
      final params = request.uri.queryParameters;
      final granted = params['code'];
      // The state must be the one this sign-in started with, or the redirect is not its answer.
      final ok = granted != null && params['state'] == state;
      request.response
        ..statusCode = ok ? 200 : 400
        ..headers.contentType = ContentType.html
        ..write(
          ok ? _doneHtml : 'Sign-in failed. Go back to Sumizuri and try again.',
        );
      await request.response.close();
      if (!code.isCompleted) {
        if (ok) {
          code.complete(granted);
        } else {
          code.completeError(
            const SyncApiException('The sign-in answer did not match.'),
          );
        }
      }
      return;
    }
  }

  static String _randomToken() {
    final random = Random.secure();
    return base64Url
        .encode(List<int>.generate(32, (_) => random.nextInt(256)))
        .replaceAll('=', '');
  }

  // S256: SHA-256 of the verifier, base64url, unpadded. Must match the server.
  static String _challenge(String verifier) => base64Url
      .encode(sha256.convert(utf8.encode(verifier)).bytes)
      .replaceAll('=', '');
}
