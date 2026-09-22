import 'package:sumizuri/core/utils/formatting/series_status_bucket.dart';

class LibrarySearchTarget {
  const LibrarySearchTarget({
    required this.title,
    this.status,
    this.sourceName,
    this.categoryNames = const [],
    this.mediaType = '',
    this.favorite = false,
    this.unread = 0,
  });

  final String title;
  final String? status;
  final String? sourceName;
  final List<String> categoryNames;
  final String mediaType;
  final bool favorite;
  final int unread;
}

class LibrarySearch {
  const LibrarySearch._(this._root);

  final _Node? _root;

  bool get isEmpty => _root == null;

  bool matches(LibrarySearchTarget target) => _root?.eval(target) ?? true;

  static LibrarySearch parse(String input) {
    final text = input.trim();
    if (text.isEmpty) return const LibrarySearch._(null);
    final tokens = _tokenize(text);
    try {
      final parser = _Parser(tokens);
      final node = parser.parseAll();
      return LibrarySearch._(node);
    } on _SearchSyntax {
      // Every word on its own, so a half-typed operator still narrows sensibly.
      final words = [
        for (final t in tokens)
          if (t.kind == _Kind.word || t.kind == _Kind.phrase)
            _Term(t.text.toLowerCase()),
      ];
      return LibrarySearch._(words.isEmpty ? null : _And(words));
    }
  }
}

enum _Kind { word, phrase, open, close, or, and }

class _Token {
  const _Token(this.kind, this.text, {this.negated = false});

  final _Kind kind;
  final String text;

  final bool negated;
}

class _SearchSyntax implements Exception {
  const _SearchSyntax();
}

List<_Token> _tokenize(String input) {
  final tokens = <_Token>[];
  var i = 0;
  while (i < input.length) {
    final c = input[i];
    if (c == ' ' || c == '\t') {
      i++;
      continue;
    }
    var negated = false;
    if (c == '-' && i + 1 < input.length && input[i + 1] != ' ') {
      negated = true;
      i++;
    }
    final d = input[i];
    if (d == '(') {
      tokens.add(_Token(_Kind.open, '(', negated: negated));
      i++;
    } else if (d == ')') {
      tokens.add(const _Token(_Kind.close, ')'));
      i++;
    } else if (d == '"') {
      final end = input.indexOf('"', i + 1);
      final closed = end != -1;
      final stop = closed ? end : input.length;
      tokens.add(
        _Token(_Kind.phrase, input.substring(i + 1, stop), negated: negated),
      );
      i = closed ? end + 1 : input.length;
    } else {
      final start = i;
      while (i < input.length &&
          input[i] != ' ' &&
          input[i] != '(' &&
          input[i] != ')') {
        if (input[i] == ':' && i + 1 < input.length && input[i + 1] == '"') {
          final end = input.indexOf('"', i + 2);
          i = end == -1 ? input.length : end + 1;
          break;
        }
        i++;
      }
      final word = input.substring(start, i);
      if (!negated && word == 'OR') {
        tokens.add(const _Token(_Kind.or, 'OR'));
      } else if (!negated && word == 'AND') {
        tokens.add(const _Token(_Kind.and, 'AND'));
      } else {
        tokens.add(_Token(_Kind.word, word, negated: negated));
      }
    }
  }
  return tokens;
}

class _Parser {
  _Parser(this._tokens);

  final List<_Token> _tokens;
  int _at = 0;

  _Token? get _peek => _at < _tokens.length ? _tokens[_at] : null;

  _Node? parseAll() {
    final node = _parseOr();
    if (_peek != null) throw const _SearchSyntax();
    return node;
  }

  _Node? _parseOr() {
    final parts = <_Node>[];
    final first = _parseAnd();
    if (first != null) parts.add(first);
    while (_peek?.kind == _Kind.or) {
      _at++;
      final next = _parseAnd();
      if (next == null) throw const _SearchSyntax();
      parts.add(next);
    }
    if (parts.isEmpty) return null;
    return parts.length == 1 ? parts.single : _Or(parts);
  }

  _Node? _parseAnd() {
    final parts = <_Node>[];
    while (true) {
      final token = _peek;
      if (token == null ||
          token.kind == _Kind.or ||
          token.kind == _Kind.close) {
        break;
      }
      if (token.kind == _Kind.and) {
        _at++;
        continue;
      }
      parts.add(_parseUnit());
    }
    if (parts.isEmpty) return null;
    return parts.length == 1 ? parts.single : _And(parts);
  }

  _Node _parseUnit() {
    final token = _tokens[_at++];
    _Node node;
    switch (token.kind) {
      case _Kind.open:
        final inner = _parseOr();
        if (_peek?.kind != _Kind.close) throw const _SearchSyntax();
        _at++;
        if (inner == null) throw const _SearchSyntax();
        node = inner;
      case _Kind.phrase:
        node = _Term(token.text.toLowerCase());
      case _Kind.word:
        node = _fieldOrTerm(token.text);
      default:
        throw const _SearchSyntax();
    }
    return token.negated ? _Not(node) : node;
  }

  _Node _fieldOrTerm(String word) {
    final colon = word.indexOf(':');
    if (colon > 0 && colon < word.length - 1) {
      final name = word.substring(0, colon).toLowerCase();
      var value = word.substring(colon + 1);
      if (value.length >= 2 && value.startsWith('"') && value.endsWith('"')) {
        value = value.substring(1, value.length - 1);
      }
      final field = _Field.tryCreate(name, value.toLowerCase());
      if (field != null) return field;
    }
    return _Term(word.toLowerCase());
  }
}

sealed class _Node {
  bool eval(LibrarySearchTarget t);
}

class _And extends _Node {
  _And(this.parts);

  final List<_Node> parts;

  @override
  bool eval(LibrarySearchTarget t) => parts.every((p) => p.eval(t));
}

class _Or extends _Node {
  _Or(this.parts);

  final List<_Node> parts;

  @override
  bool eval(LibrarySearchTarget t) => parts.any((p) => p.eval(t));
}

class _Not extends _Node {
  _Not(this.inner);

  final _Node inner;

  @override
  bool eval(LibrarySearchTarget t) => !inner.eval(t);
}

class _Term extends _Node {
  _Term(this.text);

  final String text;

  @override
  bool eval(LibrarySearchTarget t) => t.title.toLowerCase().contains(text);
}

class _Field extends _Node {
  _Field._(this._test);

  final bool Function(LibrarySearchTarget) _test;

  static bool _truthy(String v) => v == 'true' || v == 'yes' || v == '1';

  static _Field? tryCreate(String name, String value) {
    switch (name) {
      case 'status':
        final bucket = switch (value) {
          'completed' ||
          'complete' ||
          'finished' ||
          'ended' => SeriesStatusBucket.completed,
          'ongoing' => SeriesStatusBucket.ongoing,
          'hiatus' => SeriesStatusBucket.hiatus,
          _ => null,
        };
        return _Field._(
          (t) => bucket != null
              ? classifySeriesStatus(t.status) == bucket
              : (t.status ?? '').toLowerCase().contains(value),
        );
      case 'source':
        return _Field._(
          (t) => (t.sourceName ?? '').toLowerCase().contains(value),
        );
      case 'category' || 'cat':
        return _Field._(
          (t) => t.categoryNames.any((c) => c.toLowerCase().contains(value)),
        );
      case 'type':
        return _Field._((t) => t.mediaType.toLowerCase() == value);
      case 'fav' || 'favorite' || 'favourite':
        return _Field._((t) => t.favorite == _truthy(value));
      case 'unread':
        final match = RegExp(r'^(>=|<=|>|<|=)?(\d+)$').firstMatch(value);
        if (match != null) {
          final n = int.parse(match.group(2)!);
          return _Field._(
            (t) => switch (match.group(1)) {
              '>' => t.unread > n,
              '<' => t.unread < n,
              '>=' => t.unread >= n,
              '<=' => t.unread <= n,
              _ => t.unread == n,
            },
          );
        }
        if (value == 'true' ||
            value == 'false' ||
            value == 'yes' ||
            value == 'no') {
          return _Field._((t) => (t.unread > 0) == _truthy(value));
        }
        return null;
    }
    return null;
  }

  @override
  bool eval(LibrarySearchTarget t) => _test(t);
}
