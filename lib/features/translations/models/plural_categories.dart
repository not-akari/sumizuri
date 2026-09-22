const Map<String, List<String>> cldrPluralCategories = {
  'ar': ['zero', 'one', 'two', 'few', 'many', 'other'],
  'he': ['one', 'two', 'many', 'other'],
  'ru': ['one', 'few', 'many', 'other'],
  'uk': ['one', 'few', 'many', 'other'],
  'pl': ['one', 'few', 'many', 'other'],
  'cs': ['one', 'few', 'many', 'other'],
  'sk': ['one', 'few', 'many', 'other'],
  'ro': ['one', 'few', 'other'],
  'lt': ['one', 'few', 'many', 'other'],
  'lv': ['zero', 'one', 'other'],
  'ja': ['other'],
  'ko': ['other'],
  'zh': ['other'],
  'vi': ['other'],
  'th': ['other'],
  'id': ['other'],
  'ms': ['other'],
};

const _defaultPluralCategories = ['one', 'other'];

List<String> pluralCategoriesFor(String localeCode) =>
    cldrPluralCategories[localeCode] ?? _defaultPluralCategories;

const allPluralCategoryLabels = ['zero', 'one', 'two', 'few', 'many', 'other'];
