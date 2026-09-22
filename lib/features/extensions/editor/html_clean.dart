import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;

const _boilerplateTags = ['nav', 'header', 'footer', 'iframe', 'noscript'];

/// Which parts of a page to drop before showing it.
class HtmlCleanOptions {
  const HtmlCleanOptions({
    this.scripts = true,
    this.styles = true,
    this.comments = true,
    this.boilerplate = true,
    this.svg = false,
    this.meta = false,
  });

  final bool scripts;
  final bool styles;
  final bool comments;
  final bool boilerplate;
  final bool svg;
  final bool meta;
}

/// The page with the chosen parts removed, one tag per line and indented.
String cleanHtml(String html, HtmlCleanOptions options) {
  final document = html_parser.parse(html);
  final tagsToRemove = [
    if (options.scripts) 'script',
    if (options.styles) 'style',
    if (options.svg) 'svg',
    if (options.meta) ...['meta', 'link'],
    if (options.boilerplate) ..._boilerplateTags,
  ];
  for (final tag in tagsToRemove) {
    for (final element in document.querySelectorAll(tag).toList()) {
      element.remove();
    }
  }
  if (options.comments) _removeComments(document);
  return _prettyPrint(document);
}

/// Only the lines that contain one of the words, each with its line number.
String filterHtmlLines(String html, List<String> words) {
  final needles = words.map((t) => t.toLowerCase()).toList();
  final lines = html.split('\n');
  final matches = <String>[];
  for (var i = 0; i < lines.length; i++) {
    final lower = lines[i].toLowerCase();
    if (needles.any(lower.contains)) {
      matches.add('${i + 1}: ${lines[i].trim()}');
    }
  }
  return matches.isEmpty
      ? '(no lines match: ${words.join(', ')})'
      : matches.join('\n');
}

void _removeComments(dom.Node node) {
  node.nodes.removeWhere((child) => child.nodeType == dom.Node.COMMENT_NODE);
  for (final child in node.nodes.toList()) {
    _removeComments(child);
  }
}

String _prettyPrint(dom.Node node) {
  final buffer = StringBuffer();

  void write(dom.Node node, int depth) {
    if (node.nodeType == dom.Node.TEXT_NODE) {
      final text = node.text?.trim() ?? '';
      if (text.isNotEmpty) buffer.writeln('${'  ' * depth}$text');
      return;
    }
    if (node is! dom.Element) {
      for (final child in node.nodes) {
        write(child, depth);
      }
      return;
    }
    final attrs = node.attributes.entries
        .map((e) => ' ${e.key}="${e.value}"')
        .join();
    final childElements = node.nodes.where(
      (n) =>
          n.nodeType == dom.Node.ELEMENT_NODE ||
          (n.nodeType == dom.Node.TEXT_NODE &&
              (n.text?.trim().isNotEmpty ?? false)),
    );
    if (childElements.isEmpty) {
      buffer.writeln(
        '${'  ' * depth}<${node.localName}$attrs></${node.localName}>',
      );
      return;
    }
    buffer.writeln('${'  ' * depth}<${node.localName}$attrs>');
    for (final child in node.nodes) {
      write(child, depth + 1);
    }
    buffer.writeln('${'  ' * depth}</${node.localName}>');
  }

  write(node, 0);
  return buffer.toString().trim();
}
