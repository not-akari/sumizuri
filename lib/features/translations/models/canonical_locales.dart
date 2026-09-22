class CanonicalLocale {
  const CanonicalLocale({
    required this.code,
    required this.englishName,
    required this.nativeName,
  });

  final String code;
  final String englishName;
  final String nativeName;

  String get displayName => '$englishName ($nativeName)';
}

const List<CanonicalLocale> kCanonicalLocales = [
  CanonicalLocale(code: 'es', englishName: 'Spanish', nativeName: 'Español'),
  CanonicalLocale(code: 'ja', englishName: 'Japanese', nativeName: '日本語'),
  CanonicalLocale(
    code: 'zh-Hans',
    englishName: 'Chinese (Simplified)',
    nativeName: '简体中文',
  ),
  CanonicalLocale(
    code: 'zh-Hant',
    englishName: 'Chinese (Traditional)',
    nativeName: '繁體中文',
  ),
  CanonicalLocale(code: 'fr', englishName: 'French', nativeName: 'Français'),
  CanonicalLocale(code: 'de', englishName: 'German', nativeName: 'Deutsch'),
  CanonicalLocale(
    code: 'pt-BR',
    englishName: 'Portuguese (Brazil)',
    nativeName: 'Português (Brasil)',
  ),
  CanonicalLocale(
    code: 'pt',
    englishName: 'Portuguese (Portugal)',
    nativeName: 'Português',
  ),
  CanonicalLocale(code: 'ru', englishName: 'Russian', nativeName: 'Русский'),
  CanonicalLocale(code: 'ko', englishName: 'Korean', nativeName: '한국어'),
  CanonicalLocale(code: 'it', englishName: 'Italian', nativeName: 'Italiano'),
  CanonicalLocale(code: 'ar', englishName: 'Arabic', nativeName: 'العربية'),
  CanonicalLocale(code: 'hi', englishName: 'Hindi', nativeName: 'हिन्दी'),
  CanonicalLocale(
    code: 'id',
    englishName: 'Indonesian',
    nativeName: 'Bahasa Indonesia',
  ),
  CanonicalLocale(
    code: 'vi',
    englishName: 'Vietnamese',
    nativeName: 'Tiếng Việt',
  ),
  CanonicalLocale(code: 'th', englishName: 'Thai', nativeName: 'ไทย'),
  CanonicalLocale(code: 'tr', englishName: 'Turkish', nativeName: 'Türkçe'),
  CanonicalLocale(code: 'pl', englishName: 'Polish', nativeName: 'Polski'),
  CanonicalLocale(
    code: 'uk',
    englishName: 'Ukrainian',
    nativeName: 'Українська',
  ),
  CanonicalLocale(code: 'nl', englishName: 'Dutch', nativeName: 'Nederlands'),
  CanonicalLocale(code: 'cs', englishName: 'Czech', nativeName: 'Čeština'),
  CanonicalLocale(code: 'sv', englishName: 'Swedish', nativeName: 'Svenska'),
  CanonicalLocale(code: 'el', englishName: 'Greek', nativeName: 'Ελληνικά'),
  CanonicalLocale(code: 'he', englishName: 'Hebrew', nativeName: 'עברית'),
  CanonicalLocale(code: 'ro', englishName: 'Romanian', nativeName: 'Română'),
  CanonicalLocale(code: 'hu', englishName: 'Hungarian', nativeName: 'Magyar'),
  CanonicalLocale(code: 'fi', englishName: 'Finnish', nativeName: 'Suomi'),
  CanonicalLocale(code: 'da', englishName: 'Danish', nativeName: 'Dansk'),
  CanonicalLocale(code: 'no', englishName: 'Norwegian', nativeName: 'Norsk'),
  CanonicalLocale(
    code: 'ms',
    englishName: 'Malay',
    nativeName: 'Bahasa Melayu',
  ),
  CanonicalLocale(code: 'fil', englishName: 'Filipino', nativeName: 'Filipino'),
  CanonicalLocale(code: 'fa', englishName: 'Persian', nativeName: 'فارسی'),
  CanonicalLocale(code: 'ur', englishName: 'Urdu', nativeName: 'اردو'),
  CanonicalLocale(code: 'bn', englishName: 'Bengali', nativeName: 'বাংলা'),
  CanonicalLocale(code: 'ta', englishName: 'Tamil', nativeName: 'தமிழ்'),
  CanonicalLocale(code: 'te', englishName: 'Telugu', nativeName: 'తెలుగు'),
  CanonicalLocale(code: 'mr', englishName: 'Marathi', nativeName: 'मराठी'),
  CanonicalLocale(code: 'gu', englishName: 'Gujarati', nativeName: 'ગુજરાતી'),
  CanonicalLocale(code: 'kn', englishName: 'Kannada', nativeName: 'ಕನ್ನಡ'),
  CanonicalLocale(code: 'ml', englishName: 'Malayalam', nativeName: 'മലയാളം'),
  CanonicalLocale(code: 'my', englishName: 'Burmese', nativeName: 'မြန်မာစာ'),
  CanonicalLocale(code: 'km', englishName: 'Khmer', nativeName: 'ភាសាខ្មែរ'),
  CanonicalLocale(code: 'lo', englishName: 'Lao', nativeName: 'ລາວ'),
  CanonicalLocale(code: 'ka', englishName: 'Georgian', nativeName: 'ქართული'),
  CanonicalLocale(code: 'hy', englishName: 'Armenian', nativeName: 'Հայերեն'),
  CanonicalLocale(code: 'sr', englishName: 'Serbian', nativeName: 'Српски'),
  CanonicalLocale(code: 'hr', englishName: 'Croatian', nativeName: 'Hrvatski'),
  CanonicalLocale(code: 'sk', englishName: 'Slovak', nativeName: 'Slovenčina'),
  CanonicalLocale(
    code: 'bg',
    englishName: 'Bulgarian',
    nativeName: 'Български',
  ),
  CanonicalLocale(
    code: 'lt',
    englishName: 'Lithuanian',
    nativeName: 'Lietuvių',
  ),
  CanonicalLocale(code: 'lv', englishName: 'Latvian', nativeName: 'Latviešu'),
  CanonicalLocale(code: 'et', englishName: 'Estonian', nativeName: 'Eesti'),
  CanonicalLocale(
    code: 'sl',
    englishName: 'Slovenian',
    nativeName: 'Slovenščina',
  ),
  CanonicalLocale(code: 'eu', englishName: 'Basque', nativeName: 'Euskara'),
  CanonicalLocale(code: 'ca', englishName: 'Catalan', nativeName: 'Català'),
  CanonicalLocale(code: 'gl', englishName: 'Galician', nativeName: 'Galego'),
  CanonicalLocale(code: 'is', englishName: 'Icelandic', nativeName: 'Íslenska'),
  CanonicalLocale(code: 'ga', englishName: 'Irish', nativeName: 'Gaeilge'),
  CanonicalLocale(code: 'cy', englishName: 'Welsh', nativeName: 'Cymraeg'),
  CanonicalLocale(
    code: 'eo',
    englishName: 'Esperanto',
    nativeName: 'Esperanto',
  ),
  CanonicalLocale(code: 'la', englishName: 'Latin', nativeName: 'Latina'),
];

final Map<String, CanonicalLocale> _localeCodeMap = {
  for (final loc in kCanonicalLocales) loc.code.toLowerCase(): loc,
};

final Set<String> _knownPrimaryLanguageCodes = {
  'en',
  for (final loc in kCanonicalLocales)
    loc.code.split(RegExp(r'[-_]')).first.toLowerCase(),
};

final _bcp47Regex = RegExp(
  r'^[a-z]{2,3}([-_][a-z0-9]{2,4})*$',
  caseSensitive: false,
);

bool isValidLocaleCode(String rawCode) {
  final trimmed = rawCode.trim();
  if (trimmed.isEmpty || trimmed.length > 20) return false;
  if (trimmed.contains(RegExp(r'[/\\:\*\?"<>\|\.]'))) return false;

  final normalized = trimmed.toLowerCase();
  if (_localeCodeMap.containsKey(normalized)) return true;

  if (!_bcp47Regex.hasMatch(trimmed)) return false;

  // Primary language must be a recognized language root.
  final primarySubtag = trimmed.split(RegExp(r'[-_]')).first.toLowerCase();
  return _knownPrimaryLanguageCodes.contains(primarySubtag);
}

CanonicalLocale? lookupCanonicalLocale(String code) {
  final normalized = code.trim().toLowerCase();
  if (normalized == 'en') {
    return const CanonicalLocale(
      code: 'en',
      englishName: 'English',
      nativeName: 'English',
    );
  }
  if (_localeCodeMap.containsKey(normalized)) {
    return _localeCodeMap[normalized];
  }
  final primary = normalized.split(RegExp(r'[-_]')).first;
  return _localeCodeMap[primary];
}

List<CanonicalLocale> searchCanonicalLocales(String query) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return kCanonicalLocales;

  return kCanonicalLocales.where((loc) {
    return loc.code.toLowerCase().contains(q) ||
        loc.englishName.toLowerCase().contains(q) ||
        loc.nativeName.toLowerCase().contains(q);
  }).toList();
}

const Set<String> _rtlLanguageRoots = {
  'ar',
  'he',
  'fa',
  'ur',
  'yi',
  'ps',
  'sd',
  'ckb',
};

bool isRtlLocale(String localeCode) {
  final primary = localeCode.trim().split(RegExp(r'[-_]')).first.toLowerCase();
  return _rtlLanguageRoots.contains(primary);
}
