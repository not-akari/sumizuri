import 'package:html/dom.dart' as dom;
import 'package:html/parser.dart' as html_parser;
import 'package:xpath_selector_html_parser/xpath_selector_html_parser.dart';

class HtmlPages {
  HtmlPages({this.maxPages = 24});

  final int maxPages;
  final _pages = <int, _Page>{};
  final _idByHtml = <String, int>{};
  var _nextId = 1;

  int parse(String html) {
    final known = _idByHtml[html];
    if (known != null && _pages.containsKey(known)) {
      _touch(known);
      return known;
    }
    final id = _nextId++;
    _pages[id] = _Page(html, html_parser.parse(html));
    _idByHtml[html] = id;
    while (_pages.length > maxPages) {
      final oldest = _pages.keys.first;
      _idByHtml.remove(_pages.remove(oldest)!.html);
    }
    return id;
  }

  void _touch(int id) {
    final page = _pages.remove(id);
    if (page != null) _pages[id] = page;
  }

  _Page _page(int id) {
    final page = _pages[id];
    if (page == null) {
      throw StateError(
        'That parsed page is gone (only the $maxPages most recent are kept). '
        'Call host.parse(html) again.',
      );
    }
    _touch(id);
    return page;
  }

  Map<String, Object?> select(
    int pageId, {
    int? from,
    String? css,
    String? xpath,
    bool withHtml = true,
    int? limit,
  }) {
    if ((css == null) == (xpath == null)) {
      throw ArgumentError('Give either a CSS selector or an XPath');
    }
    final page = _page(pageId);
    final root = from == null ? page.document : page.element(from);

    if (css != null) {
      final found = _select(root, css);
      return {
        'items': [
          for (final element in _limited(found, limit))
            _describe(page, element, withHtml: withHtml),
        ],
      };
    }

    final result = HtmlXPath.node(root).query(xpath!);
    // An XPath such as //a/ href names attributes, which are the answer. Otherwise elements.
    if (result.attrs.any((a) => a != null)) {
      final values = result.attrs.whereType<String>().toList();
      return {'values': limit == null ? values : values.take(limit).toList()};
    }
    final elements = <dom.Element>[
      for (final node in result.nodes)
        if (node.node is dom.Element) node.node as dom.Element,
    ];
    if (elements.isEmpty && result.nodes.isNotEmpty) {
      final texts = [for (final node in result.nodes) (node.text ?? '').trim()];
      return {'values': limit == null ? texts : texts.take(limit).toList()};
    }
    return {
      'items': [
        for (final element in _limited(elements, limit))
          _describe(page, element, withHtml: withHtml),
      ],
    };
  }

  Iterable<dom.Element> _limited(List<dom.Element> all, int? limit) =>
      limit == null ? all : all.take(limit);

  Map<String, Object?> _describe(
    _Page page,
    dom.Element element, {
    required bool withHtml,
  }) => {
    'id': page.register(element),
    'tag': element.localName,
    'text': element.text.trim(),
    if (withHtml) 'html': element.innerHtml,
    'attributes': element.attributes.map(
      (key, value) => MapEntry(key.toString(), value),
    ),
  };
}

class _Page {
  _Page(this.html, this.document);

  final String html;
  final dom.Document document;
  final _elements = <dom.Element>[];
  final _idOf = Map<dom.Element, int>.identity();

  int register(dom.Element element) => _idOf.putIfAbsent(element, () {
    _elements.add(element);
    return _elements.length - 1;
  });

  dom.Element element(int id) {
    if (id < 0 || id >= _elements.length) {
      throw StateError('No element numbered $id in this page');
    }
    return _elements[id];
  }
}

/// The shared cache the older host.query goes through, so it too parses a page once.
final sharedHtmlPages = HtmlPages();

List<Map<String, Object?>> queryHtml(String html, String selector) {
  final pages = sharedHtmlPages;
  final id = pages.parse(html);
  final result = pages.select(id, css: selector);
  return [
    for (final item in (result['items'] as List).cast<Map<String, Object?>>())
      {
        'text': item['text'],
        'html': item['html'],
        'attributes': item['attributes'],
      },
  ];
}

List<dom.Element> _queryAll(dom.Node root, String selector) {
  try {
    return switch (root) {
      dom.Element e => e.querySelectorAll(selector),
      dom.Document d => d.querySelectorAll(selector),
      dom.DocumentFragment f => f.querySelectorAll(selector),
      _ => const <dom.Element>[],
    };
  } on UnimplementedError catch (error) {
    throw FormatException(
      'The selector "$selector" uses something the HTML engine does not '
      'support (${error.message ?? 'unsupported'}). '
      'Supported extras: :has(...), :contains("text"). XPath is also available.',
    );
  } on FormatException catch (error) {
    throw FormatException('Bad selector "$selector": ${error.message}');
  }
}

const _extras = [':has(', ':contains('];

List<dom.Element> _select(dom.Node root, String selector) {
  if (!_extras.any(selector.contains)) return _queryAll(root, selector);

  final result = <dom.Element>[];
  final seen = <dom.Element>{};
  for (final part in _splitTopLevel(selector, ',')) {
    for (final e in _selectWithExtras(root, part.trim())) {
      if (seen.add(e)) result.add(e);
    }
  }
  return result;
}

Iterable<dom.Element> _selectWithExtras(dom.Node root, String selector) {
  var start = -1;
  var isContains = false;
  for (final extra in _extras) {
    final at = selector.indexOf(extra);
    if (at >= 0 && (start < 0 || at < start)) {
      start = at;
      isContains = extra == ':contains(';
    }
  }
  if (start < 0) return _queryAll(root, selector);

  final open = start + (isContains ? 9 : 4);
  var depth = 0;
  var end = -1;
  var quote = '';
  for (var i = open; i < selector.length; i++) {
    final c = selector[i];
    if (quote.isNotEmpty) {
      if (c == quote) quote = '';
      continue;
    }
    if (c == '"' || c == "'") quote = c;
    if (c == '(') depth++;
    if (c == ')') {
      depth--;
      if (depth == 0) {
        end = i;
        break;
      }
    }
  }
  if (end < 0) return const [];

  final base = selector.substring(0, start).trim();
  final inner = selector.substring(open + 1, end).trim();
  final rest = selector.substring(end + 1).trim();

  final candidates = base.isEmpty
      ? _queryAll(root, '*')
      : _queryAll(root, base);

  final Iterable<dom.Element> matches;
  if (isContains) {
    final needle = _unquote(inner);
    matches = candidates.where((el) => el.text.contains(needle));
  } else {
    matches = candidates.where((el) {
      return _splitTopLevel(inner, ',').any((alt) {
        final trimmed = alt.trim();
        if (trimmed.startsWith('>')) {
          final child = trimmed.substring(1).trim();
          return el.children.any((c) => _matchesSelf(c, child));
        }
        return _selectWithExtras(el, trimmed).isNotEmpty;
      });
    });
  }

  if (rest.isEmpty) return matches;
  final out = <dom.Element>[];
  for (final el in matches) {
    if (rest.startsWith('>')) {
      final child = rest.substring(1).trim();
      out.addAll(el.children.where((c) => _matchesSelf(c, child)));
    } else {
      out.addAll(_selectWithExtras(el, rest));
    }
  }
  return out;
}

String _unquote(String text) {
  if (text.length >= 2 &&
      (text.startsWith('"') && text.endsWith('"') ||
          text.startsWith("'") && text.endsWith("'"))) {
    return text.substring(1, text.length - 1);
  }
  return text;
}

bool _matchesSelf(dom.Element element, String selector) {
  final parent = element.parent;
  if (parent == null) return false;
  return parent.querySelectorAll(selector).contains(element);
}

List<String> _splitTopLevel(String input, String separator) {
  final parts = <String>[];
  var depth = 0;
  var last = 0;
  var quote = '';
  for (var i = 0; i < input.length; i++) {
    final c = input[i];
    if (quote.isNotEmpty) {
      if (c == quote) quote = '';
      continue;
    }
    if (c == '"' || c == "'") quote = c;
    if (c == '(' || c == '[') depth++;
    if (c == ')' || c == ']') depth--;
    if (depth == 0 && c == separator) {
      parts.add(input.substring(last, i));
      last = i + 1;
    }
  }
  parts.add(input.substring(last));
  return parts;
}
