import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:intl/intl.dart' as intl;
import 'package:path/path.dart' as p;

import 'package:sumizuri/bootstrap/storage/app_paths.dart';
import 'package:sumizuri/features/translations/data/arb_document.dart';
import 'package:sumizuri/features/translations/models/icu_message.dart';
import 'package:sumizuri/l10n/generated/app_localizations.dart';
import 'package:sumizuri/l10n/generated/app_localizations_en.dart';

String _symbolName(Symbol symbol) {
  final str = symbol.toString();
  if (str.startsWith('Symbol("') && str.endsWith('")')) {
    return str.substring(8, str.length - 2);
  }
  return str;
}

Locale parseLocale(String raw) {
  final parts = raw.replaceAll('_', '-').split('-');
  if (parts.length == 1) {
    return Locale(parts[0]);
  } else if (parts.length == 2) {
    if (parts[1].length == 4) {
      return Locale.fromSubtags(languageCode: parts[0], scriptCode: parts[1]);
    }
    return Locale.fromSubtags(languageCode: parts[0], countryCode: parts[1]);
  } else if (parts.length >= 3) {
    return Locale.fromSubtags(
      languageCode: parts[0],
      scriptCode: parts[1],
      countryCode: parts[2],
    );
  }
  return Locale(raw);
}

String formatLocalizedTemplate({
  required String template,
  required String locale,
  required List<dynamic> positionalArgs,
  required Map<Symbol, dynamic> namedArgs,
  List<String> paramNames = const [],
}) {
  final args = <String, dynamic>{};
  for (var i = 0; i < positionalArgs.length; i++) {
    final key = i < paramNames.length ? paramNames[i] : 'arg$i';
    args[key] = positionalArgs[i];
  }
  for (final entry in namedArgs.entries) {
    args[_symbolName(entry.key)] = entry.value;
  }

  final icu = IcuMessage.parse(template);
  if (icu is PluralMessage) {
    final count = args[icu.argName];
    final numValue = (count is num) ? count : (int.tryParse('$count') ?? 0);

    final category = intl.Intl.pluralLogic(
      numValue,
      locale: locale,
      zero: icu.categories['=0'] ?? icu.categories['zero'],
      one: icu.categories['=1'] ?? icu.categories['one'],
      two: icu.categories['=2'] ?? icu.categories['two'],
      few: icu.categories['few'],
      many: icu.categories['many'],
      other: icu.categories['other'] ?? icu.categories.values.firstOrNull ?? '',
    );
    return _substituteTokens(category, args, positionalArgs);
  } else if (icu is SelectMessage) {
    final val = '${args[icu.argName]}';
    final category =
        icu.categories[val] ??
        icu.categories['other'] ??
        icu.categories.values.firstOrNull ??
        '';
    return _substituteTokens(category, args, positionalArgs);
  }

  return _substituteTokens(template, args, positionalArgs);
}

String _substituteTokens(
  String text,
  Map<String, dynamic> args,
  List<dynamic> positional,
) {
  var result = text;
  for (final entry in args.entries) {
    result = result.replaceAll('{${entry.key}}', '${entry.value}');
  }
  if (result.contains('{') && positional.isNotEmpty) {
    result = result.replaceAllMapped(RegExp(r'\{([a-zA-Z0-9_]+)\}'), (m) {
      final token = m.group(1)!;
      if (args.containsKey(token)) return '${args[token]}';
      if (positional.length == 1) return '${positional.first}';
      return m.group(0)!;
    });
  }
  return result;
}

class DynamicAppLocalizations extends AppLocalizations {
  DynamicAppLocalizations(
    super.locale, {
    required this.translations,
    required this.sourceEntries,
    this.sourceMeta = const {},
  });

  final Map<String, String> translations;
  final Map<String, String> sourceEntries;
  final Map<String, ArbEntryMeta> sourceMeta;

  @override
  dynamic noSuchMethod(Invocation invocation) {
    final name = _symbolName(invocation.memberName);
    final translated = translations[name];
    final template = (translated != null && translated.isNotEmpty)
        ? translated
        : (sourceEntries[name] ?? name);

    if (invocation.isGetter) {
      return template;
    }

    if (invocation.isMethod) {
      final meta = sourceMeta[name];
      final paramNames = meta?.placeholders ?? const [];

      return formatLocalizedTemplate(
        template: template,
        locale: localeName,
        positionalArgs: invocation.positionalArguments,
        namedArgs: invocation.namedArguments,
        paramNames: paramNames,
      );
    }

    return super.noSuchMethod(invocation);
  }
}

class SumizuriLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const SumizuriLocalizationsDelegate({
    this.activeDraftTranslations,
    this.sourceDoc,
  });

  final Map<String, String>? activeDraftTranslations;
  final ArbDocument? sourceDoc;

  @override
  bool isSupported(Locale locale) => true;

  static ArbDocument? _cachedSource;

  static Future<ArbDocument> getOrLoadSource() async {
    if (_cachedSource != null) return _cachedSource!;
    final raw = await rootBundle.loadString('lib/l10n/app_en.arb');
    return _cachedSource = parseArb(raw);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    final tag = locale.toLanguageTag();
    final isEnglish = locale.languageCode.toLowerCase() == 'en';

    if (isEnglish &&
        (activeDraftTranslations == null || activeDraftTranslations!.isEmpty)) {
      return SynchronousFuture<AppLocalizations>(AppLocalizationsEn());
    }

    final source = sourceDoc ?? await getOrLoadSource();

    Map<String, String> draft = activeDraftTranslations ?? {};
    if (draft.isEmpty) {
      draft = await _loadDraftForLocale(locale);
    }

    return DynamicAppLocalizations(
      tag,
      translations: draft,
      sourceEntries: source.entries,
      sourceMeta: source.meta,
    );
  }

  static Future<Map<String, String>> _loadDraftForLocale(Locale locale) async {
    try {
      final dir = await translationDraftsDirectory();
      final candidates = [
        locale.toLanguageTag(),
        locale.languageCode,
        '${locale.languageCode}-${locale.countryCode}',
        '${locale.languageCode}_${locale.countryCode}',
      ];

      for (final candidate in candidates) {
        final file = File(p.join(dir.path, 'draft_$candidate.arb'));
        if (file.existsSync()) {
          final doc = parseArb(await file.readAsString());
          return doc.entries;
        }
      }
    } catch (e, st) {
      debugPrint('Error loading translation draft for $locale: $e\n$st');
    }
    return {};
  }

  @override
  bool shouldReload(SumizuriLocalizationsDelegate old) => true;
}
