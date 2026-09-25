/// A repo address in one canonical form, so the same repo typed or pasted
/// slightly differently (spaces, `HTTPS://Host`, a `#fragment`) is still
/// recognised as the same repo when adding it and when matching installed
/// sources back to it.
String normalizeRepoUrl(String url) {
  final trimmed = url.trim();
  final uri = Uri.tryParse(trimmed);
  if (uri == null || !uri.hasScheme || uri.host.isEmpty) return trimmed;
  return uri
      .removeFragment()
      .replace(scheme: uri.scheme.toLowerCase(), host: uri.host.toLowerCase())
      .toString();
}
