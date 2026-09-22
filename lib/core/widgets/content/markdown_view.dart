import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'package:sumizuri/core/theming/theme_shapes.dart';

class MarkdownView extends StatefulWidget {
  const MarkdownView({super.key, required this.text, this.onLink});

  final String text;

  /// Called with a link's target. Without it links are shown but do nothing.
  final ValueChanged<String>? onLink;

  @override
  State<MarkdownView> createState() => _MarkdownViewState();
}

class _MarkdownViewState extends State<MarkdownView> {
  final _recognizers = <TapGestureRecognizer>[];

  void _disposeRecognizers() {
    for (final r in _recognizers) {
      r.dispose();
    }
    _recognizers.clear();
  }

  @override
  void dispose() {
    _disposeRecognizers();
    super.dispose();
  }

  static final _inline = RegExp(
    r'\*\*(.+?)\*\*|`([^`]+)`|\[([^\]]+)\]\(([^)]+)\)',
  );

  List<InlineSpan> _spans(String text, TextStyle base, ColorScheme cs) {
    final spans = <InlineSpan>[];
    var index = 0;
    for (final m in _inline.allMatches(text)) {
      if (m.start > index) {
        spans.add(TextSpan(text: text.substring(index, m.start)));
      }
      if (m.group(1) != null) {
        spans.add(
          TextSpan(
            text: m.group(1),
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        );
      } else if (m.group(2) != null) {
        spans.add(
          TextSpan(
            text: m.group(2),
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: (base.fontSize ?? 13.5) - 1,
              backgroundColor: cs.surfaceContainerHighest,
            ),
          ),
        );
      } else {
        final target = m.group(4)!;
        TapGestureRecognizer? tap;
        if (widget.onLink != null) {
          tap = TapGestureRecognizer()..onTap = () => widget.onLink!(target);
          _recognizers.add(tap);
        }
        spans.add(
          TextSpan(
            text: m.group(3),
            recognizer: tap,
            style: TextStyle(
              color: cs.primary,
              decoration: TextDecoration.underline,
              decorationColor: cs.primary.withValues(alpha: 0.5),
            ),
          ),
        );
      }
      index = m.end;
    }
    if (index < text.length) spans.add(TextSpan(text: text.substring(index)));
    return spans;
  }

  Widget _text(String text, TextStyle style, ColorScheme cs) =>
      Text.rich(TextSpan(children: _spans(text, style, cs)), style: style);

  @override
  Widget build(BuildContext context) {
    _disposeRecognizers();
    final cs = Theme.of(context).colorScheme;
    final body = TextStyle(fontSize: 13.5, height: 1.5, color: cs.onSurface);
    final blocks = <Widget>[];
    final lines = widget.text.replaceAll('\r\n', '\n').split('\n');

    final paragraph = <String>[];
    void flushParagraph() {
      if (paragraph.isEmpty) return;
      blocks.add(
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: _text(
            paragraph.join(' '),
            body.copyWith(color: cs.onSurfaceVariant),
            cs,
          ),
        ),
      );
      paragraph.clear();
    }

    var i = 0;
    while (i < lines.length) {
      final line = lines[i];
      final trimmed = line.trim();

      if (trimmed.startsWith('```')) {
        flushParagraph();
        final code = <String>[];
        i++;
        while (i < lines.length && !lines[i].trim().startsWith('```')) {
          code.add(lines[i]);
          i++;
        }
        i++;
        blocks.add(
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: cs.outlineVariant),
            ),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SelectableText(
                code.join('\n'),
                style: TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  height: 1.45,
                  color: cs.onSurface,
                ),
              ),
            ),
          ),
        );
        continue;
      }

      if (trimmed.isEmpty) {
        flushParagraph();
        i++;
        continue;
      }

      final heading = RegExp(r'^(#{1,4})\s+(.*)$').firstMatch(trimmed);
      if (heading != null) {
        flushParagraph();
        final level = heading.group(1)!.length;
        final title = heading.group(2)!;
        blocks.add(
          Padding(
            padding: EdgeInsets.only(top: level <= 2 ? 20 : 12, bottom: 4),
            child: level <= 2
                ? Text(
                    title,
                    style: TextStyle(
                      fontFamily: context.displayFont,
                      fontSize: level == 1 ? 24 : 18,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                      color: cs.onSurface,
                    ),
                  )
                : Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1,
                      color: cs.outline,
                    ),
                  ),
          ),
        );
        i++;
        continue;
      }

      final bullet = RegExp(r'^(\s*)([-*]|\d+\.)\s+(.*)$').firstMatch(line);
      if (bullet != null) {
        flushParagraph();
        final indent = bullet.group(1)!.length;
        final marker = bullet.group(2)!;
        final item = StringBuffer(bullet.group(3)!);
        i++;
        while (i < lines.length &&
            lines[i].trim().isNotEmpty &&
            lines[i].startsWith(RegExp(r'\s+')) &&
            !RegExp(r'^\s*([-*]|\d+\.)\s+').hasMatch(lines[i])) {
          item.write(' ${lines[i].trim()}');
          i++;
        }
        blocks.add(
          Padding(
            padding: EdgeInsets.only(left: indent * 6.0, top: 3, bottom: 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 22,
                  child: marker.length > 1
                      ? Text(marker, style: body.copyWith(color: cs.outline))
                      : Padding(
                          padding: const EdgeInsets.only(top: 8, right: 10),
                          child: Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: cs.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                ),
                Expanded(child: _text(item.toString(), body, cs)),
              ],
            ),
          ),
        );
        continue;
      }

      paragraph.add(trimmed);
      i++;
    }
    flushParagraph();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: blocks,
    );
  }
}
