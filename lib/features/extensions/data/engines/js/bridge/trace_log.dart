const _maxEntries = 400;
const _bodyPreviewLength = 4000;
const _hiddenHeaders = {
  'cookie',
  'set-cookie',
  'authorization',
  'proxy-authorization',
};

class TraceLog {
  final _entries = <Map<String, Object?>>[];
  final _clock = Stopwatch()..start();
  var _dropped = 0;

  void add(String kind, Map<String, Object?> data) {
    if (_entries.length >= _maxEntries) {
      _dropped++;
      return;
    }
    _entries.add({'kind': kind, 'ms': _clock.elapsedMilliseconds, ...data});
  }

  void addFetch({
    required String method,
    required String url,
    required Map<String, dynamic>? requestHeaders,
    required String? requestBody,
    required int elapsedMs,
    Map<String, Object?>? result,
    String? error,
  }) {
    final body = result?['body'] as String?;
    add('fetch', {
      'method': method,
      'url': url,
      'took': elapsedMs,
      'status': result?['statusCode'],
      'finalUrl': result != null && result['url'] != url ? result['url'] : null,
      'requestHeaders': _hide(requestHeaders),
      'requestBody': requestBody == null ? null : _preview(requestBody),
      'responseHeaders': _hide(result?['headers'] as Map?),
      'bodyLength': body?.length,
      'body': body == null ? null : _preview(body),
      'error': error,
    });
  }

  List<Map<String, Object?>> take() {
    final out = [..._entries];
    if (_dropped > 0) {
      out.add({
        'kind': 'note',
        'ms': _clock.elapsedMilliseconds,
        'text': '$_dropped more entries were not kept (only $_maxEntries are).',
      });
    }
    _entries.clear();
    _dropped = 0;
    _clock.reset();
    return out;
  }

  static String _preview(String text) => text.length <= _bodyPreviewLength
      ? text
      : '${text.substring(0, _bodyPreviewLength)}…';

  static Map<String, Object?> _hide(Map? headers) => {
    for (final entry in (headers ?? const {}).entries)
      '${entry.key}': _hiddenHeaders.contains('${entry.key}'.toLowerCase())
          ? '(hidden)'
          : '${entry.value}',
  };
}
