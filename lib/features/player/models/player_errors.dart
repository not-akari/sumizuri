// Tells a dropped connection from a broken video and decides how often to retry quietly.

bool isNetworkError(String message) {
  final text = message.toLowerCase();
  const signs = [
    'tcp:',
    'ffurl_read',
    'ffurl_',
    'timed out',
    'timeout',
    'connection',
    'network',
    'server returned',
    'http error',
    'tls:',
    'ssl',
    'reset by peer',
    'end of file',
    'i/o error',
    'error in the pull function',
  ];
  return signs.any(text.contains);
}

bool isHarmlessEngineNoise(String message) {
  final text = message.toLowerCase();
  const signs = [
    'property not found',
    'failed to create file cache',
    'could not create file cache',
    // The fast decoding path was not available, so the slower one is used.
    'failed to create egl surface',
  ];
  return signs.any(text.contains);
}

/// True when the engine's message is a damaged piece of the stream, such as a bad packet.
bool isDecodeGlitch(String message) {
  final text = message.toLowerCase();
  const signs = [
    'error decoding audio',
    'error decoding video',
    'error while decoding',
    'decoding error',
    'packet corrupt',
    'corrupt',
    'invalid band type',
    'pes packet size mismatch',
    'invalid data found',
    'non-monotonous',
  ];
  return signs.any(text.contains);
}

class RetryBudget {
  RetryBudget({this.max = 3, this.resetAfter = const Duration(seconds: 30)});

  final int max;
  final Duration resetAfter;

  var _used = 0;
  var _lastAt = Duration.zero;

  /// Asks for one retry at position. False when the budget is spent.
  bool take(Duration position) {
    if (_used > 0 && (position - _lastAt >= resetAfter || position < _lastAt)) {
      _used = 0;
    }
    if (_used >= max) return false;
    _used++;
    _lastAt = position;
    return true;
  }

  void reset() {
    _used = 0;
    _lastAt = Duration.zero;
  }
}
