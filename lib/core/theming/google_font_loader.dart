import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/storage/app_paths.dart';

/// Fetches a font from Google Fonts once, keeps it on disk and makes it
/// available under its own name. The app offers a short list of families, so
/// this asks for exactly those instead of carrying a table of every family
/// (which is what the google_fonts package does, at some 7 MB).
class GoogleFontLoader {
  GoogleFontLoader._();

  static const _stylesheet = 'https://fonts.googleapis.com/css2';

  // An old browser is asked for, since Google answers it with one plain
  // TrueType file for the family, not a set of slices for a newer engine.
  static const _oldBrowser =
      'Mozilla/5.0 (Linux; U; Android 4.0.3; ko-kr; LG-L160L Build/IML74K) '
      'AppleWebkit/534.30 (KHTML, like Gecko) Version/4.0 Mobile Safari/534.30';

  static final _started = <String>{};

  /// Starts loading [family] if that has not been done. Text set in it uses the
  /// default font until the font is in, then the engine asks for it to be laid
  /// out again.
  static void ensureLoaded(String family) {
    if (family.isEmpty || !_started.add(family)) return;
    unawaited(_load(family));
  }

  static Future<void> _load(String family) async {
    try {
      final file = File(
        p.join(
          (await googleFontsDirectory()).path,
          '${family.replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}.ttf',
        ),
      );
      final Uint8List bytes;
      if (await file.exists()) {
        bytes = await file.readAsBytes();
      } else {
        bytes = await download(family);
        // Written to the side and moved, so a stopped app never leaves half a font.
        final partial = File('${file.path}.part');
        await partial.writeAsBytes(bytes, flush: true);
        await partial.rename(file.path);
      }
      final loader = FontLoader(family)
        ..addFont(Future.value(ByteData.sublistView(bytes)));
      await loader.load();
    } catch (_) {
      // Offline, or Google Fonts did not answer: try again the next time it is asked for.
      _started.remove(family);
    }
  }

  /// The font file for [family], from Google Fonts.
  static Future<Uint8List> download(String family) async {
    final sheet = await http.get(
      Uri.parse(_stylesheet).replace(queryParameters: {'family': family}),
      headers: {'User-Agent': _oldBrowser},
    );
    final url = RegExp(r'url\((https://[^)]+\.ttf)\)').firstMatch(sheet.body);
    if (sheet.statusCode != 200 || url == null) {
      throw HttpException('No font file for $family');
    }
    final font = await http.get(Uri.parse(url.group(1)!));
    if (font.statusCode != 200) throw HttpException('Font download failed');
    return font.bodyBytes;
  }
}
