import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:sumizuri/features/extensions/editor/debug_report.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';

class TestDebugView extends StatelessWidget {
  const TestDebugView({
    super.key,
    required this.output,
    required this.trace,
    required this.onCopyReport,
  });

  final String output;
  final List<TraceEntry> trace;

  final VoidCallback? onCopyReport;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final fetches = trace.where((e) => e['kind'] == 'fetch').toList();
    final logs = trace.where((e) => e['kind'] == 'log').toList();
    final findings = diagnose(trace);

    return DefaultTabController(
      length: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: TabBar(
                  isScrollable: true,
                  tabAlignment: TabAlignment.start,
                  dividerColor: Colors.transparent,
                  tabs: [
                    Tab(text: l10n.sourceEditorTabResult),
                    Tab(
                      text:
                          '${l10n.sourceEditorTabRequests}'
                          '${fetches.isEmpty ? '' : ' (${fetches.length})'}',
                    ),
                    Tab(
                      text:
                          '${l10n.sourceEditorTabConsole}'
                          '${logs.isEmpty ? '' : ' (${logs.length})'}',
                    ),
                    Tab(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.sourceEditorTabFindings),
                          if (findings.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Icon(
                              Icons.error_outline,
                              size: 16,
                              color: theme.colorScheme.error,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.sourceEditorCopyReport,
                onPressed: onCopyReport,
                icon: const Icon(Icons.content_copy_outlined, size: 20),
              ),
            ],
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TabBarView(
                children: [
                  _Scrollable(
                    child: output.isEmpty
                        ? _Muted(l10n.sourceEditorTestOutputEmpty)
                        : _Mono(output),
                  ),
                  _Scrollable(
                    child: fetches.isEmpty
                        ? _Muted(l10n.sourceEditorNoRequests)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final f in fetches) _FetchTile(entry: f),
                            ],
                          ),
                  ),
                  _Scrollable(
                    child: logs.isEmpty
                        ? _Muted(l10n.sourceEditorNoConsole)
                        : Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final l in logs) _LogLine(entry: l),
                            ],
                          ),
                  ),
                  _Scrollable(
                    child: _Findings(trace: trace, findings: findings),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Scrollable extends StatelessWidget {
  const _Scrollable({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => SingleChildScrollView(child: child);
}

class _Muted extends StatelessWidget {
  const _Muted(this.text);

  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text,
    style: Theme.of(context).textTheme.bodySmall
        ?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
  );
}

class _Mono extends StatelessWidget {
  const _Mono(this.text, {this.color});

  final String text;
  final Color? color;

  @override
  Widget build(BuildContext context) => SelectableText(
    text,
    style: TextStyle(fontFamily: 'monospace', fontSize: 12, color: color),
  );
}

class _FetchTile extends StatelessWidget {
  const _FetchTile({required this.entry});

  final TraceEntry entry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final error = entry['error'] as String?;
    final status = entry['status'];
    final failed = error != null || (status is int && status >= 400);
    final body = entry['body'] as String?;
    final uri = Uri.tryParse('${entry['url']}');
    final short = uri == null ? '${entry['url']}' : '${uri.host}${uri.path}';

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.only(bottom: 8),
      dense: true,
      leading: Icon(
        failed ? Icons.error_outline : Icons.check_circle_outline,
        size: 18,
        color: failed ? theme.colorScheme.error : theme.colorScheme.primary,
      ),
      title: Text(
        '${entry['method']} $short',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
      ),
      subtitle: Text(
        error ??
            '$status · ${entry['took']} ms'
                '${entry['bodyLength'] == null ? '' : ' · ${entry['bodyLength']} chars'}',
        style: theme.textTheme.bodySmall?.copyWith(
          color: failed ? theme.colorScheme.error : null,
        ),
      ),
      children: [
        Align(
          alignment: Alignment.centerLeft,
          child: _Mono(
            [
              '${entry['url']}',
              if (entry['finalUrl'] != null) '-> ${entry['finalUrl']}',
              ..._headerLines('sent', entry['requestHeaders']),
              if (entry['requestBody'] != null)
                'body sent: ${entry['requestBody']}',
              ..._headerLines('received', entry['responseHeaders']),
            ].join('\n'),
          ),
        ),
        if (body != null && body.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _looksJson(body) ? 'JSON' : 'HTML / text',
                  style: theme.textTheme.labelSmall,
                ),
                TextButton(
                  onPressed: () => Clipboard.setData(ClipboardData(text: body)),
                  child: Text(l10n.sourceEditorCopyBody),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: _Mono(_looksJson(body) ? _prettyJson(body) : body),
          ),
        ],
      ],
    );
  }

  static bool _looksJson(String body) {
    final start = body.trimLeft();
    return start.startsWith('{') || start.startsWith('[');
  }

  // A preview cut mid document is not valid JSON, so it is shown as it is.
  static String _prettyJson(String body) {
    try {
      return const JsonEncoder.withIndent('  ').convert(jsonDecode(body));
    } catch (_) {
      return body;
    }
  }

  static List<String> _headerLines(String label, Object? headers) {
    if (headers is! Map || headers.isEmpty) return const [];
    return [
      '— headers $label —',
      for (final h in headers.entries) '${h.key}: ${h.value}',
    ];
  }
}

class _LogLine extends StatelessWidget {
  const _LogLine({required this.entry});

  final TraceEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final level = '${entry['level']}';
    final color = switch (level) {
      'error' => scheme.error,
      'warn' => scheme.tertiary,
      _ => null,
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: _Mono(
        '${entry['ms']} ms  [$level] ${entry['text']}',
        color: color,
      ),
    );
  }
}

class _Findings extends StatelessWidget {
  const _Findings({required this.trace, required this.findings});

  final List<TraceEntry> trace;
  final List<String> findings;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final queries = trace.where((e) => e['kind'] == 'query').toList();
    final sections = trace.where((e) => e['kind'] == 'section').toList();
    if (findings.isEmpty && queries.isEmpty && sections.isEmpty) {
      return _Muted(l10n.sourceEditorNoFindings);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (findings.isEmpty)
          _Muted(l10n.sourceEditorNoFindings)
        else
          for (final finding in findings)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 18,
                    color: theme.colorScheme.error,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: SelectableText(finding)),
                ],
              ),
            ),
        if (sections.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            l10n.sourceEditorFindingsSections,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          for (final s in sections) _Mono(_sectionLine(s)),
        ],
        if (queries.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            l10n.sourceEditorFindingsSearches,
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 4),
          for (final q in queries)
            _Mono(
              '${q['matches'] == 0 ? '✗' : '✓'} '
              '${q['selector'] ?? q['xpath']} → ${q['matches']}',
              color: q['matches'] == 0 ? theme.colorScheme.error : null,
            ),
        ],
      ],
    );
  }

  static String _sectionLine(TraceEntry s) {
    final empty = (s['empty'] as Map?)?.cast<String, Object?>() ?? const {};
    final gaps = [
      for (final f in empty.entries)
        '${f.key} empty ×${(f.value! as Map)['count']}',
    ];
    return '${s['url']} → ${s['items']} item(s)'
        '${gaps.isEmpty ? '' : '  (${gaps.join(', ')})'}';
  }
}
