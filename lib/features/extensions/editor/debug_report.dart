import 'dart:convert';

typedef TraceEntry = Map<String, Object?>;

const _reportBodyLength = 1500;

/// Plain findings about a test run, most important first. Empty when all looks fine.
List<String> diagnose(List<TraceEntry> trace) {
  final findings = <String>[];

  for (final entry in trace) {
    switch (entry['kind']) {
      case 'fetch':
        final url = entry['url'];
        final error = entry['error'];
        final status = entry['status'];
        if (error != null) {
          findings.add('The request to $url failed: $error');
        } else if (status is int && status >= 400) {
          findings.add(
            'The site answered $status to $url. '
            '${_statusAdvice(status)}',
          );
        } else if (entry['bodyLength'] == 0) {
          findings.add(
            '$url answered with an empty page. Some sites do that when a '
            'header (Referer, User-Agent, an API key) is missing.',
          );
        }
      case 'query':
        if (entry['matches'] == 0) {
          final what = entry['selector'] ?? entry['xpath'];
          findings.add(
            'The selector $what matched nothing. Check it against the '
            'page in the Requests tab, or open the page in the HTML inspector.',
          );
        }
      case 'section':
        final items = entry['items'];
        final where = entry['itemSelector'] ?? entry['itemsPath'];
        if (items == 0) {
          findings.add(
            'The list at ${entry['url']} came back with no items'
            '${where == null ? '' : ' ("$where" found nothing)'}.',
          );
        } else if (items is int) {
          final sameUrl = entry['sameUrl'];
          final sameTitle = entry['sameTitle'];
          if (sameUrl is int && sameUrl > 0) {
            findings.add(
              '$sameUrl item(s) in the list at ${entry['url']} have the same '
              'address as an earlier one. The selector may match the same list '
              'twice.',
            );
          } else if (sameTitle is int && sameTitle > 0) {
            findings.add(
              '$sameTitle item(s) in the list at ${entry['url']} share a title '
              'with another, but have different addresses: sub and dub (or two '
              'servers) listed together, or a selector matching two lists.',
            );
          }
        }
        if (items is int && entry['empty'] is Map) {
          final empty = (entry['empty']! as Map).cast<String, Object?>();
          for (final field in empty.entries) {
            final info = (field.value! as Map).cast<String, Object?>();
            final count = info['count'];
            if (count == items) {
              findings.add(
                'The field "${field.key}" is empty in all $items items. '
                'It is declared as ${jsonEncode(info['declared'])}.',
              );
            }
          }
        }
      case 'log':
        if (entry['level'] == 'error') {
          findings.add('The source logged an error: ${entry['text']}');
        }
      case 'crypto':
        if (entry['error'] != null) {
          findings.add('Decryption failed: ${entry['error']}');
        }
    }
  }
  return findings;
}

String _statusAdvice(int status) => switch (status) {
  401 || 403 =>
    'That usually means it needs a header (Referer, a token) or it blocks '
        'requests that do not look like a browser.',
  404 => 'The address is probably wrong or has changed.',
  429 => 'Too many requests: raise rateLimitMs.',
  >= 500 => 'The site itself is failing; try again later.',
  _ => '',
};

String buildDebugReport({
  required String sourceName,
  required String method,
  required String arguments,
  required Duration took,
  required String output,
  required List<TraceEntry> trace,
  String? sourceCode,
}) {
  final out = StringBuffer()
    ..writeln('# Source test: $sourceName')
    ..writeln()
    ..writeln('- Method: `$method`')
    ..writeln('- Arguments: $arguments')
    ..writeln('- Took: ${(took.inMilliseconds / 1000).toStringAsFixed(1)} s');

  final findings = diagnose(trace);
  if (findings.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## Problems found');
    for (final finding in findings) {
      out.writeln('- $finding');
    }
  }

  out
    ..writeln()
    ..writeln('## Result')
    ..writeln('```')
    ..writeln(output.trim().isEmpty ? '(nothing)' : output.trim())
    ..writeln('```');

  final fetches = trace.where((e) => e['kind'] == 'fetch').toList();
  if (fetches.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## Requests (${fetches.length})');
    for (var i = 0; i < fetches.length; i++) {
      final f = fetches[i];
      out.writeln();
      out.writeln(
        '${i + 1}. `${f['method']} ${f['url']}` -> '
        '${f['error'] != null ? 'FAILED: ${f['error']}' : f['status']} '
        '(${f['took']} ms${f['bodyLength'] == null ? '' : ', ${f['bodyLength']} chars'})',
      );
      if (f['finalUrl'] != null) {
        out.writeln('   - redirected to ${f['finalUrl']}');
      }
      _headers(out, 'sent', f['requestHeaders']);
      if (f['requestBody'] != null) {
        out.writeln('   - body sent: `${f['requestBody']}`');
      }
      _headers(out, 'received', f['responseHeaders'], only: _interesting);
      final body = f['body'] as String?;
      if (body != null && body.isNotEmpty) {
        final shown = body.length <= _reportBodyLength
            ? body
            : '${body.substring(0, _reportBodyLength)}…';
        out
          ..writeln('   ```')
          ..writeln(shown)
          ..writeln('   ```');
      }
    }
  }

  final queries = trace.where((e) => e['kind'] == 'query').toList();
  if (queries.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## Searches in pages');
    for (final q in queries) {
      out.writeln(
        '- `${q['selector'] ?? q['xpath']}` -> ${q['matches']} match(es)',
      );
    }
  }

  final sections = trace.where((e) => e['kind'] == 'section').toList();
  if (sections.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## JSON engine sections');
    for (final s in sections) {
      out.writeln(
        '- `${s['url']}`: ${s['items']} item(s)'
        '${s['itemSelector'] == null ? '' : ' via `${s['itemSelector']}`'}'
        '${s['itemsPath'] == null ? '' : ' via path `${s['itemsPath']}`'}',
      );
      final empty = (s['empty'] as Map?)?.cast<String, Object?>() ?? const {};
      for (final field in empty.entries) {
        final info = (field.value! as Map).cast<String, Object?>();
        out.writeln(
          '  - `${field.key}` empty in ${info['count']}: '
          '${jsonEncode(info['declared'])}',
        );
      }
    }
  }

  final logs = trace.where((e) => e['kind'] == 'log').toList();
  if (logs.isNotEmpty) {
    out
      ..writeln()
      ..writeln('## Console');
    for (final l in logs) {
      out.writeln('- [${l['level']}] ${l['text']}');
    }
  }

  if (sourceCode != null && sourceCode.trim().isNotEmpty) {
    out
      ..writeln()
      ..writeln('## Source')
      ..writeln('```')
      ..writeln(sourceCode.trim())
      ..writeln('```');
  }
  return out.toString();
}

const _interesting = {
  'content-type',
  'content-length',
  'location',
  'server',
  'cf-ray',
  'cache-control',
};

void _headers(
  StringBuffer out,
  String label,
  Object? headers, {
  Set<String>? only,
}) {
  if (headers is! Map || headers.isEmpty) return;
  final shown = [
    for (final h in headers.entries)
      if (only == null || only.contains('${h.key}'.toLowerCase()))
        '${h.key}: ${h.value}',
  ];
  if (shown.isNotEmpty) out.writeln('   - headers $label: ${shown.join('; ')}');
}
