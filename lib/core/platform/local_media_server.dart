import 'dart:io';
import 'dart:math' as math;

/// Serves a local file over HTTP with byte-range support for LAN streaming (e.g. Chromecast).
class LocalMediaServer {
  LocalMediaServer._(this._server, this.url);

  final HttpServer _server;
  final Uri url;

  static Future<LocalMediaServer?> serve(
    File file, {
    required String contentType,
  }) async {
    final HttpServer server;
    try {
      server = await HttpServer.bind(InternetAddress.anyIPv4, 0);
    } on Object {
      return null;
    }
    final length = await file.length();
    server.listen((request) => _respond(request, file, length, contentType));

    final host = await _reachableAddress();
    return LocalMediaServer._(
      server,
      Uri(scheme: 'http', host: host, port: server.port, path: '/episode'),
    );
  }

  static Future<void> _respond(
    HttpRequest request,
    File file,
    int length,
    String contentType,
  ) async {
    final response = request.response;
    try {
      if (request.method != 'GET' && request.method != 'HEAD') {
        response.statusCode = HttpStatus.methodNotAllowed;
        await response.close();
        return;
      }
      response.headers
        ..set(HttpHeaders.acceptRangesHeader, 'bytes')
        ..contentType = ContentType.parse(contentType);
      var start = 0;
      var end = length - 1;
      final range = request.headers.value(HttpHeaders.rangeHeader);
      if (range != null && range.startsWith('bytes=')) {
        final parts = range.substring(6).split('-');
        start = int.tryParse(parts[0]) ?? 0;
        if (parts.length > 1 && parts[1].isNotEmpty) {
          end = math.min(int.tryParse(parts[1]) ?? end, length - 1);
        }
        response.statusCode = HttpStatus.partialContent;
        response.headers.set('Content-Range', 'bytes $start-$end/$length');
      }
      response.headers.contentLength = end - start + 1;
      if (request.method == 'HEAD') {
        await response.close();
        return;
      }
      await response.addStream(file.openRead(start, end + 1));
      await response.close();
    } on Object {
      try {
        await response.close();
      } on Object {
        // The connection is already gone; nothing left to close cleanly.
      }
    }
  }

  // The address a device elsewhere on the same network can reach, not just this machine.
  static Future<String> _reachableAddress() async {
    try {
      final interfaces = await NetworkInterface.list(
        type: InternetAddressType.IPv4,
        includeLoopback: false,
      );
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          if (!address.isLoopback) return address.address;
        }
      }
    } on Object {
      // Fall through to loopback, which at least works when nothing else answers.
    }
    return InternetAddress.loopbackIPv4.address;
  }

  Future<void> close() => _server.close(force: true);
}
