const apiSuggestions = [
  'host.fetch(',
  'host.query(',
  'host.hash(',
  'host.storage.get(',
  'host.storage.set(',
  'host.storage.delete(',
  'host.storage.clear(',
  'host.storage.all(',
  'host.preference.get(',
  'host.preference.all(',
  'host.isTesting',
  'getPreferenceValue(',
  'atob(',
  'btoa(',
  'entities.decode(',
  'entities.encode(',
  'url.resolve(',
  'url.parse(',
  'date.parse(',
  'require(',
  'extension.search',
  'extension.getPopular',
  'extension.getLatest',
  'extension.getChapterList',
  'extension.getPageList',
  'extension.getVideoList',
  'host.render(',
  'host.parse(',
  'host.crypto.aes.decrypt(',
  'extension.getDetails',
  'extension.getComments',
  'extension.getChapterComments',
  'extension.getFilters',
  'extension.getSourcePreferences',
  'extension.rateLimitMs',
  'extension.name',
  'extension.lang',
  'extension.iconUrl',
  'extension.baseUrl',
  'NAME',
  'LANG',
  'ICON_URL',
  'BASE_URL',
  'RATE_LIMIT_MS',
];

const jsonSchemaSuggestions = [
  'name',
  'lang',
  'baseUrl',
  'iconUrl',
  'search',
  'popular',
  'latest',
  'chapters',
  'pages',
  'videos',
  'videoHeaders',
  'subtitles',
  'audioTracks',
  'filters',
  'preferences',
  'rateLimitMs',
  'url',
  'itemSelector',
  'itemsPath',
  'htmlPath',
  'fields',
  'selector',
  'attr',
  'path',
  'js',
  'pageStart',
  'pageSize',
  'method',
  'headers',
  'body',
  'request',
  'script',
];

const sourceTemplate = '''
var extension = {
  search: async function (query, page) {
    return [];
  },
  getPopular: async function (page) {
    return [];
  },
  getLatest: async function (page) {
    return [];
  },
  getChapterList: async function (entryUrl) {
    return [];
  },
  getPageList: async function (chapterUrl) {
    return [];
  },
};
''';

const jsonSourceTemplate = '''
{
  "name": "",
  "lang": "en",
  "baseUrl": "",
  "iconUrl": "",
  "popular": {
    "url": "{baseUrl}/popular?page={page}",
    "itemSelector": "div.item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "latest": {
    "url": "{baseUrl}/latest?page={page}",
    "itemSelector": "div.item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "search": {
    "url": "{baseUrl}/search?q={query}&page={page}",
    "itemSelector": "div.item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "chapters": {
    "url": "{entryUrl}",
    "itemSelector": "ul.chapters li a",
    "fields": {
      "url": { "attr": "href" },
      "title": { "attr": "text" }
    }
  },
  "pages": {
    "url": "{chapterUrl}",
    "itemSelector": "img.page-image",
    "fields": {
      "imageUrl": { "attr": "src" }
    }
  }
}
''';

const animeSourceTemplate = '''
var extension = {
  search: async function (query, page) {
    return [];
  },
  getPopular: async function (page) {
    return [];
  },
  getLatest: async function (page) {
    return [];
  },
  getChapterList: async function (entryUrl) {
    // Episodes: one Chapter each, with season, seasonName and seasonCoverUrl for seasons.
    return [];
  },
  getVideoList: async function (chapterUrl) {
    // Best first. Each: { url, quality, headers, subtitles: [{ url, label, language }] }
    return [];
  },
};
''';

const animeJsonSourceTemplate = '''
{
  "name": "",
  "lang": "en",
  "baseUrl": "",
  "iconUrl": "",
  "popular": {
    "url": "{baseUrl}/popular?page={page}",
    "itemSelector": "div.item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "latest": {
    "url": "{baseUrl}/latest?page={page}",
    "itemSelector": "div.item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "search": {
    "url": "{baseUrl}/search?q={query}&page={page}",
    "itemSelector": "div.item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "chapters": {
    "url": "{entryUrl}",
    "itemSelector": "ul.episodes li a",
    "fields": {
      "url": { "attr": "href" },
      "title": { "attr": "text" }
    }
  },
  "videos": {
    "url": "{chapterUrl}",
    "itemSelector": "video source",
    "fields": {
      "url": { "attr": "src" },
      "quality": { "attr": "label" }
    },
    "videoHeaders": { "Referer": "{baseUrl}/" }
  }
}
''';

String templateFor({required bool json, required bool anime}) => json
    ? (anime ? animeJsonSourceTemplate : jsonSourceTemplate)
    : (anime ? animeSourceTemplate : sourceTemplate);

bool isSourceTemplate(String text) =>
    text == sourceTemplate ||
    text == jsonSourceTemplate ||
    text == animeSourceTemplate ||
    text == animeJsonSourceTemplate;
