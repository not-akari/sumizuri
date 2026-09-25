// Default headers for a same-origin static asset (an icon, a favicon) that
// its site protects with a basic Referer/User-Agent hotlink check, without
// needing the full per-source headers a JS/JSON extension declares for its
// own content (which aren't available before an extension is installed, and
// aren't worth threading through every icon widget for their own sake).

const _defaultUserAgent =
    'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 '
    '(KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36';

/// Headers to send when fetching [url] as if a browser had navigated to its
/// own origin first: most hotlink checks only look at same-origin Referer.
Map<String, String> originHeaders(String url) {
  final origin = Uri.tryParse(url)?.origin;
  return {
    if (origin != null && origin.isNotEmpty) 'Referer': '$origin/',
    'User-Agent': _defaultUserAgent,
  };
}
