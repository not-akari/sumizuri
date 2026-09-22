/// The file path inside a cover address, or null when the address is on the web.
String? localFilePathOf(String? url) {
  if (url == null || url.isEmpty) return null;
  if (url.startsWith('file://')) return Uri.parse(url).toFilePath();
  if (url.startsWith('/') || RegExp(r'^[A-Za-z]:[\\/]').hasMatch(url)) {
    return url;
  }
  return null;
}
