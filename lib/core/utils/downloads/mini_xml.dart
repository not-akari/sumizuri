// Lightweight XML parser tailored for DASH manifest inspection.

/// One element: its local name, its attributes, its own text and its children in order.
class XmlNode {
  XmlNode(this.tag, this.attributes);

  final String tag;
  final Map<String, String> attributes;
  final List<XmlNode> children = [];

  /// The text directly inside this element, trimmed. Only a leaf element needs it.
  String text = '';

  Iterable<XmlNode> child(String tag) => children.where((c) => c.tag == tag);

  XmlNode? first(String tag) {
    for (final c in children) {
      if (c.tag == tag) return c;
    }
    return null;
  }

  String? attr(String name) => attributes[name];
}

String _localName(String qualified) {
  final colon = qualified.indexOf(':');
  return colon < 0 ? qualified : qualified.substring(colon + 1);
}

String _unescape(String text) => text
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&amp;', '&');

final _attributeRe = RegExp(
  r'([:\w.-]+)\s*=\s*"([^"]*)"'
  r"|([:\w.-]+)\s*=\s*'([^']*)'",
);

Map<String, String> _parseAttributes(String text) {
  final out = <String, String>{};
  for (final m in _attributeRe.allMatches(text)) {
    final name = m[1] ?? m[3];
    final value = m[2] ?? m[4] ?? '';
    if (name != null) out[_localName(name)] = _unescape(value);
  }
  return out;
}

/// Reads [source] into a tree rooted at its outermost element, or null when nothing parses.
XmlNode? parseXml(String source) {
  // Comments, CDATA, the XML declaration and DOCTYPE never hold a tag this reader looks for.
  final text = source
      .replaceAll(RegExp(r'<\?[\s\S]*?\?>'), '')
      .replaceAll(RegExp(r'<!--[\s\S]*?-->'), '')
      .replaceAll(RegExp(r'<!DOCTYPE[\s\S]*?>'), '')
      .replaceAllMapped(
        RegExp(r'<!\[CDATA\[([\s\S]*?)\]\]>'),
        (m) => m[1] ?? '',
      );

  final tagRe = RegExp(r'<(/?)([:\w.-]+)((?:\s+[^<>]*?)?)(/?)>');
  final stack = <XmlNode>[];
  XmlNode? root;
  var previousEnd = 0;
  for (final m in tagRe.allMatches(text)) {
    if (stack.isNotEmpty) {
      final gap = text.substring(previousEnd, m.start).trim();
      if (gap.isNotEmpty) stack.last.text = _unescape(gap);
    }
    previousEnd = m.end;

    final closing = m[1] == '/';
    final name = _localName(m[2]!);
    final selfClosed = m[4] == '/';
    if (closing) {
      if (stack.isNotEmpty && stack.last.tag == name) stack.removeLast();
      continue;
    }
    final node = XmlNode(name, _parseAttributes(m[3] ?? ''));
    if (stack.isEmpty) {
      root ??= node;
    } else {
      stack.last.children.add(node);
    }
    if (!selfClosed) stack.add(node);
  }
  return root;
}
