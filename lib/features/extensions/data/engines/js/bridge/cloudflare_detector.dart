// Detects whether an HTTP response looks like a Cloudflare challenge page.
bool looksLikeChallenge(
  int statusCode,
  Map<String, String> headers,
  String body,
) {
  final lowerHeaders = headers.map(
    (key, value) => MapEntry(key.toLowerCase(), value),
  );
  if (lowerHeaders.containsKey('cf-mitigated')) return true;

  if (statusCode != 503 && statusCode != 403 && statusCode != 200) return false;
  final lowerBody = body.toLowerCase();
  const markers = [
    'just a moment',
    'cf-chl',
    'enable javascript and cookies to continue',
    'checking your browser before accessing',
    'attention required! | cloudflare',
  ];
  return markers.any(lowerBody.contains);
}

class ChallengeDetectedException implements Exception {
  ChallengeDetectedException(this.url);

  final String url;

  @override
  String toString() => 'ChallengeDetectedException: $url';
}
