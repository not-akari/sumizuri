sealed class IcuMessage {
  const IcuMessage();

  factory IcuMessage.parse(String raw) {
    final parsed = _tryParsePluralOrSelect(raw);
    if (parsed != null) return parsed;
    return PlainMessage(raw);
  }

  String format();
}

final class PlainMessage extends IcuMessage {
  const PlainMessage(this.text);
  final String text;

  @override
  String format() => text;
}

final class PluralMessage extends IcuMessage {
  const PluralMessage(this.argName, this.categories);
  final String argName;

  final Map<String, String> categories;

  @override
  String format() => _formatPluralOrSelect(argName, 'plural', categories);
}

final class SelectMessage extends IcuMessage {
  const SelectMessage(this.argName, this.categories);
  final String argName;
  final Map<String, String> categories;

  @override
  String format() => _formatPluralOrSelect(argName, 'select', categories);
}

String _formatPluralOrSelect(
  String argName,
  String type,
  Map<String, String> categories,
) {
  final body = categories.entries.map((e) => '${e.key}{${e.value}}').join(' ');
  return '{$argName, $type, $body}';
}

final _headerRegex = RegExp(r'^\{\s*(\w+)\s*,\s*(plural|select)\s*,\s*');

IcuMessage? _tryParsePluralOrSelect(String raw) {
  final match = _headerRegex.firstMatch(raw);
  if (match == null) return null;
  final argName = match.group(1)!;
  final type = match.group(2)!;

  var pos = match.end;
  final categories = <String, String>{};
  while (pos < raw.length) {
    while (pos < raw.length && raw[pos] == ' ') {
      pos++;
    }
    if (pos >= raw.length) return null;
    if (raw[pos] == '}') {
      pos++;
      break;
    }
    final labelStart = pos;
    while (pos < raw.length && raw[pos] != '{') {
      pos++;
    }
    if (pos >= raw.length) return null;
    final label = raw.substring(labelStart, pos).trim();
    if (label.isEmpty) return null;
    pos++;
    var depth = 1;
    final innerStart = pos;
    while (pos < raw.length && depth > 0) {
      if (raw[pos] == '{') depth++;
      if (raw[pos] == '}') depth--;
      if (depth > 0) pos++;
    }
    if (depth != 0) return null;
    categories[label] = raw.substring(innerStart, pos);
    pos++;
  }
  if (categories.isEmpty) return null;
  if (raw.substring(pos).trim().isNotEmpty) return null;

  return type == 'plural'
      ? PluralMessage(argName, categories)
      : SelectMessage(argName, categories);
}

Set<String> extractPlaceholders(String text) {
  final regex = RegExp(r'\{(\w+)\}');
  return {for (final m in regex.allMatches(text)) m.group(1)!};
}
