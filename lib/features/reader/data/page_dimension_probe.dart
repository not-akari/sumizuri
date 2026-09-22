import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;

import 'package:sumizuri/features/extensions/models/m_page.dart';

/// Finds a page's aspect from the start of its file, so pages get a height before loading.
class PageDimensionProbe {
  PageDimensionProbe({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  // The size sits in the first bytes, but a large embedded profile can push it further.
  static const _readLimit = 64 * 1024;

  /// Height divided by width, or null when the start of the file does not tell.
  Future<double?> aspectOf(MPage page, {Map<String, String>? headers}) async {
    final url = page.imageUrl;
    if (url == null || url.isEmpty) return null;
    try {
      final bytes = page.isLocalFile
          ? await _readLocal(url)
          : await _readRemote(url, headers);
      if (bytes == null || bytes.isEmpty) return null;
      final info = img.findDecoderForData(bytes)?.startDecode(bytes);
      if (info == null || info.width <= 0 || info.height <= 0) return null;
      return info.height / info.width;
    } on Object {
      return null;
    }
  }

  Future<Uint8List?> _readLocal(String path) async {
    final builder = BytesBuilder(copy: false);
    await for (final chunk in File(path).openRead(0, _readLimit)) {
      builder.add(chunk);
    }
    return builder.takeBytes();
  }

  Future<Uint8List?> _readRemote(
    String url,
    Map<String, String>? headers,
  ) async {
    final request = http.Request('GET', Uri.parse(url))
      ..headers.addAll({...?headers, 'Range': 'bytes=0-${_readLimit - 1}'});
    final response = await _client
        .send(request)
        .timeout(const Duration(seconds: 12));
    if (response.statusCode != 200 && response.statusCode != 206) return null;
    final builder = BytesBuilder(copy: false);
    // Leaving the loop closes the connection, so a server that ignores the range sends less.
    await for (final chunk in response.stream.timeout(
      const Duration(seconds: 12),
    )) {
      builder.add(chunk);
      if (builder.length >= _readLimit) break;
    }
    return builder.takeBytes();
  }

  void close() => _client.close();
}
