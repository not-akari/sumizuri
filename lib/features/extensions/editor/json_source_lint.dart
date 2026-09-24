import 'dart:convert';

import 'package:sumizuri/features/extensions/data/engines/json/json_comments.dart'
    show stripJsonComments;

// Checks a JSON source for the mistakes the engine would otherwise swallow.

enum IssueLevel { error, warning }

class SourceIssue {
  const SourceIssue(this.level, this.path, this.message);

  final IssueLevel level;

  final String path;
  final String message;

  @override
  String toString() => '$path: $message';
}

const _topLevelKeys = {
  'name',
  'lang',
  'iconUrl',
  'baseUrl',
  'webBaseUrl',
  'rateLimitMs',
  'headers',
  'preferences',
  'filters',
  ..._sectionNames,
};

const _sectionNames = {
  'search',
  'popular',
  'latest',
  'chapters',
  'pages',
  'videos',
  'details',
  'comments',
  'chapterComments',
};

const _listSections = {
  'search',
  'popular',
  'latest',
  'chapters',
  'pages',
  'videos',
  'comments',
  'chapterComments',
};

const _sectionKeys = {
  'url',
  'method',
  'headers',
  'body',
  'itemSelector',
  'itemsPath',
  'htmlPath',
  'fields',
  'pagination',
  'pageSize',
  'pageStart',
  'sort',
  'resolve',
  'videoHeaders',
  'expandPlaylists',
  'render',
  'subtitles',
  'audioTracks',
  'intro',
  'outro',
};

const _fieldKeys = {
  'selector',
  'attr',
  'all',
  'path',
  'template',
  'join',
  'separator',
  'requireAll',
  'or',
  'if',
  'then',
  'else',
  'regex',
  'split',
  'index',
  'transform',
  'decode',
  'round',
  'map',
  'resolve',
  'resolveWeb',
  'default',
};

const _renderKeys = {
  'waitFor',
  'waitForResource',
  'capture',
  'script',
  'timeout',
  'userAgent',
};

const _transforms = {
  'number',
  'trim',
  'capitalize',
  'htmlToText',
  'unixTimestamp',
  'parseDate',
};

const _decoders = {'base64', 'urlDecode', 'unpack', 'megaplay'};

const _requiredFields = <String, List<List<String>>>{
  'search': [
    ['url'],
    ['title'],
  ],
  'popular': [
    ['url'],
    ['title'],
  ],
  'latest': [
    ['url'],
    ['title'],
  ],
  'chapters': [
    ['url'],
    ['title', 'number'],
  ],
  'pages': [
    ['imageUrl', 'text'],
  ],
  'videos': [
    ['url'],
  ],
  'comments': [
    ['author'],
    ['text'],
  ],
  'chapterComments': [
    ['author'],
    ['text'],
  ],
};

const _placeholders = {
  'baseUrl',
  'query',
  'page',
  'offset',
  'pageSize',
  'entryUrl',
  'chapterUrl',
  'entrySlug',
  'chapterSlug',
  'sort',
};

List<SourceIssue> lintJsonSource(Map<String, dynamic> config) {
  final issues = <SourceIssue>[];
  void error(String path, String message) =>
      issues.add(SourceIssue(IssueLevel.error, path, message));
  void warn(String path, String message) =>
      issues.add(SourceIssue(IssueLevel.warning, path, message));

  for (final key in config.keys) {
    if (!_topLevelKeys.contains(key)) {
      warn(key, 'Not a known option${_didYouMean(key, _topLevelKeys)}.');
    }
  }

  final baseUrl = config['baseUrl'];
  if (baseUrl is! String || baseUrl.trim().isEmpty) {
    warn(
      'baseUrl',
      'Missing. Relative addresses cannot be resolved without it.',
    );
  }

  final known = {
    ..._placeholders,
    ..._preferenceKeys(config['preferences']),
    ..._filterKeys(config['filters']),
  };

  for (final name in const ['search', 'popular', 'latest', 'chapters']) {
    if (config[name] == null) {
      warn(name, 'Missing, so this returns nothing.');
    }
  }
  if (config['pages'] == null && config['videos'] == null) {
    error(
      'pages',
      'A source needs "pages" (manga, novels) or "videos" (anime) to open a chapter.',
    );
  }

  for (final name in _sectionNames) {
    final section = config[name];
    if (section == null) continue;
    if (section is! Map) {
      error(name, 'Must be an object, not ${_kind(section)}.');
      continue;
    }
    _lintSection(
      name,
      section.cast<String, dynamic>(),
      known: known,
      error: error,
      warn: warn,
    );
  }

  issues.sort((a, b) => a.level.index.compareTo(b.level.index));
  return issues;
}

void _lintSection(
  String name,
  Map<String, dynamic> section, {
  required Set<String> known,
  required void Function(String path, String message) error,
  required void Function(String path, String message) warn,
}) {
  for (final key in section.keys) {
    if (!_sectionKeys.contains(key)) {
      warn(
        '$name.$key',
        'Not a known option${_didYouMean(key, _sectionKeys)}.',
      );
    }
  }

  final url = section['url'];
  if (url is! String || url.trim().isEmpty) {
    if (name != 'details' || section['fields'] != null) {
      warn('$name.url', 'Missing: the section has no page to read.');
    }
  } else {
    for (final match in RegExp(r'\{(\w+)\}').allMatches(url)) {
      final placeholder = match.group(1)!;
      if (!known.contains(placeholder) &&
          !placeholder.startsWith('filter_') &&
          !placeholder.startsWith('pref_') &&
          !_declaresVar(section, placeholder)) {
        warn(
          '$name.url',
          '{$placeholder} is not filled in by anything'
              '${_didYouMean(placeholder, known)}. It will be left as text in the address.',
        );
      }
    }
  }

  final hasSelector = section['itemSelector'] != null;
  final hasPath = section['itemsPath'] != null;
  if (_listSections.contains(name)) {
    if (!hasSelector && !hasPath) {
      error(
        name,
        'Needs "itemSelector" (a page) or "itemsPath" (a JSON API) to say where the items are, or it returns nothing.',
      );
    }
    if (hasSelector && hasPath) {
      warn(
        name,
        'Both "itemSelector" and "itemsPath" are set; "itemsPath" is used.',
      );
    }
  }
  if (section['htmlPath'] != null && hasPath) {
    warn(
      '$name.htmlPath',
      'Ignored: "itemsPath" reads the response as JSON. "htmlPath" is for pages inside JSON, read with "itemSelector".',
    );
  }
  final method = section['method'];
  if (method is String &&
      !const {
        'GET',
        'POST',
        'PUT',
        'PATCH',
        'DELETE',
        'HEAD',
      }.contains(method.toUpperCase())) {
    warn('$name.method', '"$method" is not an HTTP method.');
  }

  final render = section['render'];
  if (render != null) {
    if (render is! bool && render is! Map) {
      error(
        '$name.render',
        'Must be true or an object like {"waitFor": ".episodes"}.',
      );
    } else if (render is Map) {
      for (final key in render.keys) {
        if (!_renderKeys.contains(key)) {
          warn(
            '$name.render.$key',
            'Not a known option${_didYouMean('$key', _renderKeys)}, so it is ignored.',
          );
        }
      }
    }
    if (render != false && method is String && method.toUpperCase() != 'GET') {
      error('$name.render', '"render" only works for GET requests.');
    }
  }

  final fields = section['fields'];
  if (fields is! Map) {
    error(
      '$name.fields',
      'Missing or not an object: nothing says what to read.',
    );
    return;
  }
  for (final group in _requiredFields[name] ?? const <List<String>>[]) {
    if (!group.any(fields.containsKey)) {
      error(
        '$name.fields',
        'Needs ${group.length == 1 ? '"${group.first}"' : 'one of ${group.map((g) => '"$g"').join(' or ')}'}, '
            'or every item is rejected.',
      );
    }
  }
  for (final entry in fields.entries) {
    _lintField(
      '$name.fields.${entry.key}',
      entry.value,
      // Without "itemsPath" a section reads a page, or HTML inside JSON with "htmlPath".
      // "details" has no itemSelector and can read HTML directly or JSON from root.
      inSelectorSection: hasPath
          ? false
          : (hasSelector || name != 'details' ? true : null),
      error: error,
      warn: warn,
    );
  }

  for (final sub in const ['subtitles', 'audioTracks']) {
    final value = section[sub];
    if (value is Map && value['fields'] is Map) {
      final subFields = value['fields'] as Map;
      if (!subFields.containsKey('url')) {
        error('$name.$sub.fields', 'Needs "url".');
      }
    }
  }

  final pagination = section['pagination'];
  if (pagination is Map &&
      pagination['nextSelector'] == null &&
      pagination['nextPath'] == null) {
    warn(
      '$name.pagination',
      'Needs "nextSelector" (a page) or "nextPath" (a JSON API) to find the next page.',
    );
  }
}

void _lintField(
  String path,
  Object? field, {
  required bool? inSelectorSection,
  required void Function(String path, String message) error,
  required void Function(String path, String message) warn,
}) {
  if (field is! Map) {
    error(
      path,
      'Must be an object like {"selector": "a", "attr": "href"}, not ${_kind(field)}.',
    );
    return;
  }
  for (final key in field.keys) {
    if (!_fieldKeys.contains(key)) {
      warn(
        '$path.$key',
        'Not a known option${_didYouMean('$key', _fieldKeys)}, so it is ignored.',
      );
    }
  }

  final sources = [
    for (final key in const [
      'selector',
      'path',
      'template',
      'join',
      'or',
      'if',
    ])
      if (field.containsKey(key)) key,
  ];
  if (sources.length > 1) {
    warn(
      path,
      'Uses ${sources.map((s) => '"$s"').join(' and ')} together; only one of them is used.',
    );
  }
  if (field['path'] != null && inSelectorSection == true) {
    warn(
      path,
      '"path" reads a JSON field, but this section reads a page with "itemSelector"; use "selector".',
    );
  }
  if (field['selector'] != null && inSelectorSection == false) {
    warn(
      path,
      '"selector" reads HTML, but this section reads JSON with "itemsPath"; use "path".',
    );
  }

  final transform = field['transform'];
  if (transform != null && !_transforms.contains(transform)) {
    error(
      '$path.transform',
      '"$transform" is not a transform${_didYouMean('$transform', _transforms)}. '
          'Use one of: ${_transforms.join(', ')}.',
    );
  }
  final decode = field['decode'];
  if (decode != null) {
    for (final step in decode is List ? decode : [decode]) {
      if (!_decoders.contains(step)) {
        error(
          '$path.decode',
          '"$step" is not a decoder${_didYouMean('$step', _decoders)}. '
              'Use: ${_decoders.join(', ')}.',
        );
      }
    }
  }
  final regex = field['regex'];
  if (regex is String) {
    try {
      RegExp(regex);
    } on FormatException catch (e) {
      warn('$path.regex', 'May not be a valid pattern: ${e.message}');
    }
  } else if (regex != null) {
    error('$path.regex', 'Must be a string.');
  }
  if (field['split'] != null && field['index'] is! int) {
    warn(path, '"split" needs an "index" saying which piece to keep.');
  }
  if (field['index'] != null && field['split'] == null) {
    warn(path, '"index" does nothing without "split".');
  }
  final round = field['round'];
  if (round != null && round is! int) {
    warn('$path.round', 'Must be a whole number of decimal places.');
  }

  for (final key in const ['join', 'or']) {
    final list = field[key];
    if (list == null) continue;
    if (list is! List) {
      error('$path.$key', 'Must be a list of fields.');
      continue;
    }
    for (var i = 0; i < list.length; i++) {
      _lintField(
        '$path.$key[$i]',
        list[i],
        inSelectorSection: inSelectorSection,
        error: error,
        warn: warn,
      );
    }
  }
  for (final key in const ['then', 'else']) {
    if (field[key] is Map) {
      _lintField(
        '$path.$key',
        field[key],
        inSelectorSection: inSelectorSection,
        error: error,
        warn: warn,
      );
    }
  }
}

bool _declaresVar(Map<String, dynamic> section, String name) {
  final resolve = section['resolve'];
  if (resolve is Map) return resolve['as'] == name;
  if (resolve is List) {
    return resolve.any((step) => step is Map && step['as'] == name);
  }
  return false;
}

Set<String> _preferenceKeys(Object? preferences) => {
  if (preferences is List)
    for (final p in preferences)
      if (p is Map && p['key'] is String) p['key'] as String,
};

Set<String> _filterKeys(Object? filters) => {
  if (filters is List)
    for (final f in filters)
      if (f is Map && f['key'] is String) f['key'] as String,
};

String _kind(Object? value) => switch (value) {
  null => 'empty',
  List() => 'a list',
  Map() => 'an object',
  String() => 'text',
  num() => 'a number',
  bool() => 'true/false',
  _ => 'something else',
};

String _didYouMean(String word, Iterable<String> options) {
  String? best;
  var bestDistance = 3;
  for (final option in options) {
    final d = _distance(word.toLowerCase(), option.toLowerCase());
    if (d < bestDistance) {
      bestDistance = d;
      best = option;
    }
  }
  return best == null ? '' : ' (did you mean "$best"?)';
}

int _distance(String a, String b) {
  if (a == b) return 0;
  var previous = List<int>.generate(b.length + 1, (i) => i);
  for (var i = 1; i <= a.length; i++) {
    final row = [i, ...List<int>.filled(b.length, 0)];
    for (var j = 1; j <= b.length; j++) {
      final cost = a[i - 1] == b[j - 1] ? 0 : 1;
      row[j] = [
        row[j - 1] + 1,
        previous[j] + 1,
        previous[j - 1] + cost,
      ].reduce((x, y) => x < y ? x : y);
    }
    previous = row;
  }
  return previous[b.length];
}

String? validateJsonSource(String text) {
  try {
    final decoded = jsonDecode(stripJsonComments(text));
    if (decoded is! Map) {
      return 'Top-level JSON must be an object, not a ${decoded.runtimeType}.';
    }
    return null;
  } on FormatException catch (e) {
    return e.message;
  }
}

Map<String, String?>? detectJsonMetadata(String text) {
  try {
    final decoded = jsonDecode(stripJsonComments(text));
    if (decoded is! Map) return null;
    String? asString(Object? value) => value is String ? value : null;
    return {
      'name': asString(decoded['name']),
      'lang': asString(decoded['lang']),
      'iconUrl': asString(decoded['iconUrl']),
      'baseUrl': asString(decoded['baseUrl']),
      'webBaseUrl': asString(decoded['webBaseUrl']),
    };
  } on FormatException {
    return null;
  }
}
