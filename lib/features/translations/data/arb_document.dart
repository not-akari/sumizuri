import 'dart:convert';

class ArbParseException implements Exception {
  const ArbParseException(this.message);
  final String message;

  @override
  String toString() => message;
}

class ArbEntryMeta {
  const ArbEntryMeta({this.description, this.placeholders = const []});
  final String? description;
  final List<String> placeholders;
}

class ArbDocument {
  const ArbDocument({
    required this.locale,
    required this.entries,
    required this.meta,
  });

  final String locale;
  final Map<String, String> entries;
  final Map<String, ArbEntryMeta> meta;
}

ArbDocument parseArb(String jsonText) {
  final dynamic decoded;
  try {
    decoded = jsonDecode(jsonText);
  } catch (e) {
    throw const ArbParseException('File is not valid JSON.');
  }

  if (decoded is! Map<String, dynamic>) {
    throw const ArbParseException('ARB root must be a JSON object.');
  }

  final locale = decoded['@@locale'] as String? ?? '';
  final entries = <String, String>{};
  final meta = <String, ArbEntryMeta>{};

  for (final key in decoded.keys) {
    if (key.startsWith('@')) continue;
    final value = decoded[key];
    if (value is! String) continue;
    entries[key] = value;

    final metaValue = decoded['@$key'];
    if (metaValue is Map<String, dynamic>) {
      final placeholders =
          (metaValue['placeholders'] as Map<String, dynamic>?)?.keys.toList() ??
          const [];
      meta[key] = ArbEntryMeta(
        description: metaValue['description'] as String?,
        placeholders: placeholders,
      );
    }
  }

  return ArbDocument(locale: locale, entries: entries, meta: meta);
}

String writeArb({
  required String locale,
  required List<String> orderedKeys,
  required Map<String, String> translatedValues,
}) {
  final map = <String, dynamic>{'@@locale': locale};
  for (final key in orderedKeys) {
    final value = translatedValues[key];
    if (value == null || value.trim().isEmpty) continue;
    map[key] = value;
  }
  return const JsonEncoder.withIndent('  ').convert(map);
}
