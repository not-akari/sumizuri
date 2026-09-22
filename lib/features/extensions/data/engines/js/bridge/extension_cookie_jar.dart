import 'package:cookie_jar/cookie_jar.dart';

CookieJar createCookieJar(String directoryPath) =>
    PersistCookieJar(storage: FileStorage(directoryPath));

List<Cookie> parseSetCookieHeader(String? header) {
  if (header == null || header.isEmpty) return const [];
  final parts = header.split(RegExp(r',(?=\s*[^;=\s]+=)'));
  final cookies = <Cookie>[];
  for (final part in parts) {
    try {
      cookies.add(Cookie.fromSetCookieValue(part.trim()));
    } catch (_) {}
  }
  return cookies;
}

List<Cookie> parseDocumentCookieString(String documentCookie) {
  if (documentCookie.isEmpty) return const [];
  final cookies = <Cookie>[];
  for (final part in documentCookie.split(';')) {
    final trimmed = part.trim();
    if (trimmed.isEmpty) continue;
    final eq = trimmed.indexOf('=');
    if (eq == -1) continue;
    final name = trimmed.substring(0, eq).trim();
    final value = trimmed.substring(eq + 1).trim();
    if (name.isEmpty) continue;
    try {
      cookies.add(Cookie(name, value));
    } catch (_) {}
  }
  return cookies;
}
