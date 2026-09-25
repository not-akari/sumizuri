import 'package:flutter/painting.dart';
import 'package:flutter_highlight/themes/atom-one-dark.dart';
import 'package:highlight/highlight_core.dart' show Highlight, Node;
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/json.dart';
import 'package:highlight/languages/xml.dart';

/// The languages the editors colour: a source's script, its JSON, and the HTML
/// of a page. Registered one by one, since the package's own `highlight`
/// carries about two hundred languages and all of them end up in the app.
final _highlight = Highlight()
  ..registerLanguage('javascript', javascript)
  ..registerLanguage('json', json)
  ..registerLanguage('xml', xml);

/// [text] coloured as [language] (`html` is `xml`).
List<TextSpan> highlightSpans(String text, String language) {
  final nodes = _highlight.parse(text, language: language).nodes ?? const [];
  final spans = <TextSpan>[];
  var current = spans;
  final stack = <List<TextSpan>>[];

  void traverse(Node node) {
    if (node.value != null) {
      current.add(
        node.className == null
            ? TextSpan(text: node.value)
            : TextSpan(
                text: node.value,
                style: atomOneDarkTheme[node.className!],
              ),
      );
    } else if (node.children != null) {
      final inner = <TextSpan>[];
      current.add(
        TextSpan(
          children: inner,
          style: atomOneDarkTheme[node.className ?? ''],
        ),
      );
      stack.add(current);
      current = inner;
      for (final child in node.children!) {
        traverse(child);
      }
      current = stack.removeLast();
    }
  }

  for (final node in nodes) {
    traverse(node);
  }
  return spans;
}
