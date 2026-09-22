/// A chapter's chapterUrl as a full web address, or null when it cannot be worked out.
Uri? chapterWebAddress(String chapterUrl, String? baseUrl) {
  final raw = chapterUrl.trim();
  if (raw.isEmpty) return null;
  final direct = Uri.tryParse(raw);
  if (direct != null && (direct.scheme == 'http' || direct.scheme == 'https')) {
    return direct.host.isEmpty ? null : direct;
  }
  final base = baseUrl == null ? null : Uri.tryParse(baseUrl.trim());
  if (base == null || base.host.isEmpty) return null;
  if (base.scheme != 'http' && base.scheme != 'https') return null;
  // Not parsed: something like "javascript:" or "data:" must never be opened.
  if (direct != null && direct.hasScheme) return null;
  final resolved = base.resolve(raw);
  return resolved.host.isEmpty ? null : resolved;
}
