---
title: Writing extensions
description: Write a Sumizuri source in JavaScript, test it in the app and share it in a repo.
eyebrow: Guide for developers
heading: Writing Sumizuri extensions
lead: Connect Sumizuri to an API with one JavaScript file. Here is how to write a source, test it in the app and share it with others.
facts:
  - Plain JavaScript
  - Tested in the app
  - Shared through repos
---

A source tells Sumizuri how to talk to one API. It lists and searches the titles there. It gets the chapters of a title. It gets the pages, text or videos of a chapter.

The usual source is a few requests to a JSON API, such as your own library server or a service that offers an API for people to build on. Only use APIs you have the right to use. If a server gives HTML and not JSON, `cheerio` is there to read it. See [part 1](#1-how-a-source-looks).

Sumizuri sources are plain JavaScript files with a small, open format. Sumizuri adds a few things on top of the base format, such as videos for anime. Those are listed in [part 6](#6-sumizuri-additions).

## 1. How a source looks

A source is one JavaScript file. It has a class named `Source` and hands it out at the end:

```js
class Source {
  async getSearchResults(request, metadata) { /* ... */ }
  async getMangaDetails(mangaId) { /* ... */ }
  async getChapters(mangaId) { /* ... */ }
  async getChapterDetails(mangaId, chapterId) { /* ... */ }
}

module.exports = { Source };
```

These globals are there for you:

| Global | What it is |
| --- | --- |
| `App` | Requests, settings and saved values. See [part 4](#4-the-app-helpers). |
| `cheerio` | Reads HTML, for a server that gives pages and not JSON. `cheerio.load(html)` gives you `$`, as on a web page. It is the slim build of cheerio 1.2.0, so a piece of HTML stays as it is and is not put inside html and body tags. Most sources talk to a JSON API and do not need it. |
| `CryptoJS` | Hashes and ciphers, such as MD5, SHA and AES. |
| `console` | `console.log`, `console.warn` and `console.error` write to the app log. |

Sources run in a small JavaScript engine (QuickJS) on the device. The engine is closed off from the rest of the device. A source can only reach public `http` and `https` addresses. It can never reach the device itself or the local network.

### A small example

This source reads a library from a JSON API. The API is made up. Change the address and the field names to match yours.

```js
const manager = App.createRequestManager({ rateLimit: { requestsPerSecond: 4 } });
const API = 'https://library.example.com/api';

async function getJSON(path) {
  const response = await manager.schedule(App.createRequest({ url: API + path, method: 'GET' }));
  return JSON.parse(response.data);
}

class Source {
  async getSearchResults(request, metadata) {
    const page = (metadata && metadata.page) || 1;
    const data = await getJSON('/titles?search=' + encodeURIComponent(request.title || '') + '&page=' + page);
    return {
      results: data.items.map((item) => ({ mangaId: item.slug, title: item.name, image: item.cover })),
      metadata: data.hasMore ? { page: page + 1 } : undefined,
    };
  }

  async getMangaDetails(mangaId) {
    const item = await getJSON('/titles/' + mangaId);
    return { mangaInfo: { title: item.name, image: item.cover, author: item.author, desc: item.summary, status: 'ONGOING' } };
  }

  async getChapters(mangaId) {
    const item = await getJSON('/titles/' + mangaId + '/chapters');
    return item.chapters.map((chapter) => ({ chapterId: chapter.id, name: chapter.title, number: chapter.number, time: chapter.publishedAt }));
  }

  async getChapterDetails(mangaId, chapterId) {
    const chapter = await getJSON('/chapters/' + chapterId);
    return { pages: chapter.pages };
  }
}

module.exports = { Source };
```

A server that only gives HTML can still be read with `cheerio`. Load the page with `cheerio.load(response.data)` and pick out what you need with the same selectors as on a web page. A JSON API is steadier, because its fields do not change when a page is redesigned.

## 2. Build and test in the app

1. Open **Browse**. Go to **Extensions** and tap **Create a source**. The editor opens on a template that reads a library from a server of your own. Its comments tell you what to change.
2. Write your code on the **Code** tab.
3. On the **Details** tab, set the name, language code, kind, site address and icon.
4. On the **Test** tab, tap **Run all** to try every part of your code. You can also run one part at a time. Open a title in the results to test its details and chapters. Open a chapter to test its pages.
5. The **Console** shows what your code logs. It also shows each request.
6. Save. The source shows in Browse with your other sources.

To change a source you installed, open it. Then choose **Edit code** in its menu with three dots. If the source came from a repo, your changes are saved as your own copy. The repo version stays as it was.

You can also add a source from a file. In **Extensions**, tap **Add a source from a file** and pick the `.js` file.

In the editor, each call can take up to 30 seconds. In normal use, it can take up to 90 seconds.

## 3. The methods

Four methods are needed. The rest are optional. Any method can be `async`.

### 3.1 getSearchResults(request, metadata)

This one method gives every list: the feeds, a search and a search with filters.

`request` has these fields:

| Field | What it holds |
| --- | --- |
| `title` | The words of the search. Empty for a feed. |
| `feed` | The id of the feed to show, when the person opened a feed. |
| `includedTags` | The tags picked, as `[{ id }]`. |
| `excludedTags` | The tags to leave out, as `[{ id }]`. |
| `sortId` | The id of the sort picked, from `getSortOptions`. |

`metadata` is empty for the first page. For later pages it is the `metadata` you gave back last time. Put anything you need in it, such as a page number or a cursor.

Give back an object:

```js
return {
  results: [{ mangaId: 'harbor-lights', title: 'Harbor Lights', image: 'https://...' }],
  metadata: { page: 2 },
};
```

Leave out `metadata`, or set it to nothing, when the list ends.

Each title in `results` has:

| Field | Needed | What it is |
| --- | --- | --- |
| `mangaId` | yes | Your own id for the title. You get it back in the other methods. |
| `title` | yes | The name. |
| `image` | no | The cover address. |
| `tags` | no | Genres, as text. |

### 3.2 getMangaDetails(mangaId)

Gives the page of one title. Put the fields under `mangaInfo`:

```js
return {
  mangaInfo: {
    title: 'Harbor Lights',
    image: 'https://...',
    author: 'Your Name',
    desc: 'A short story about a small town by the sea.',
    status: 'ONGOING',
    tags: ['Slice of life'],
    webURL: 'https://library.example.com/titles/harbor-lights',
  },
};
```

`status` is one of `ONGOING`, `COMPLETED`, `HIATUS` or `CANCELLED`. You can also give `rating` as a number.

### 3.3 getChapters(mangaId)

Gives a list of chapters. Each one has:

| Field | Needed | What it is |
| --- | --- | --- |
| `chapterId` | yes | Your own id for the chapter. `id` works too. |
| `name` | no | The name shown in the list. |
| `number` | no | The chapter number. When it is missing, the app looks for a number in the name. |
| `volume` | no | The volume number. |
| `group` | no | The group that made the release. |
| `language` | no | A language code. |
| `time` | no | When it came out, in milliseconds or as a date written out. |
| `isLocked` | no | True for a chapter that needs a paid account or more time. |
| `unlockAt` | no | When a locked chapter opens, in milliseconds. |

### 3.4 getChapterDetails(mangaId, chapterId)

Gives the pages of a chapter:

```js
return { pages: ['https://.../1.jpg', 'https://.../2.jpg'] };
```

A novel source gives its words instead, as one text or as a list of paragraphs:

```js
return { text: ['First paragraph.', 'Second paragraph.'] };
```

A paragraph that is only a picture, written as `![](https://.../art.jpg)`, shows as that picture among the words. This suits the art in a light novel.

### 3.5 Optional methods

| Method | What it gives |
| --- | --- |
| `getSourceFeeds()` | The lists the source page shows as tabs, as `[{ id, name }]`. It is not `async`. |
| `getSearchTags()` | The tags a search can use. Either a flat list `[{ id, label }]`, or sections `[{ id, label, tags: [{ id, label }] }]`. |
| `getSortOptions()` | The orders a search can use, as `[{ id, label }]`. |
| `getPageData(mangaId, chapterId, index)` | One page, for an API that hands pages out one at a time. Give back `{ url }`, or `{ base64, mimeType }`. |

When a source reads `excludedTags` anywhere in its code, the filters get a **Leave out** group.

## 4. The App helpers

### 4.1 Requests

```js
const manager = App.createRequestManager({ rateLimit: { requestsPerSecond: 4 } });
const request = App.createRequest({ url: 'https://example.com', method: 'GET', headers: { Referer: 'https://example.com/' } });
const response = await manager.schedule(request);
// response.status, response.headers, response.data
```

`rateLimit` can also have `requestsPerMinute`. Keep it to what the API allows. A `body` that is not text is sent as JSON.

### 4.2 Settings and saved values

`App.getSourceSetting(key)` gives the value the person chose on the settings page of the source, as text. The settings come from `settingsSchema` in the repo. See [part 5](#5-publishing-a-repo).

To keep a value between calls, such as a token:

```js
const state = App.createSourceStateManager();
await state.store('token', 'abc');
const token = await state.retrieve('token');
```

### 4.3 Other helpers

| Helper | What it does |
| --- | --- |
| `App.base64Encode(text)` | Encodes text as base64. |
| `App.base64Decode(text)` | Decodes base64 to text. |

## 5. Publishing a repo

A repo is a folder on the web with a `versioning.json` and one folder for each source:

```
versioning.json
mysource/index.js
othersource/index.js
```

`versioning.json` looks like this:

```json
{
  "repositoryName": "My repo",
  "sources": [
    {
      "id": "mysource",
      "name": "My Source",
      "version": "1.0.0",
      "medium": "comics",
      "website": "https://example.com",
      "language": "en",
      "contentRating": "safe",
      "iconUrl": "https://example.com/icon.png",
      "sha256": "the hash of index.js"
    }
  ]
}
```

| Field | What it is |
| --- | --- |
| `id` | The folder name of the source. |
| `version` | Three numbers. Raise it for each change, so the app offers the update. |
| `medium` | `comics`, `novel`, `both` or `anime`. |
| `contentRating` | `safe` or `adult`. Adult sources are hidden until the person turns them on. |
| `sha256` | The SHA 256 hash of `index.js`. The app checks it before it installs the file. |
| `hosts` | Optional. The only hosts the source may reach. |
| `settingsSchema` | Optional. The settings page of the source. |
| `status`, `statusNote` | Optional. Tells people a source is broken, and why. |
| `imageHeaders` | Optional. Headers sent with every picture of the source, such as `{ "Sec-Fetch-Dest": "image" }` for a site whose pictures only load for a browser. |

Each setting in `settingsSchema` has a `key`, a `label` and a `type`. The type is `toggle`, `select`, `multiSelect` or `text`. A setting can have a `default`. A `select` or `multiSelect` has `options` as `[{ value, label }]`. A `text` setting can have a `placeholder`.

A repo can also sort its sources into folders by kind, such as `comics/mysource/index.js`. When a source is not at the top, the app looks for it in `anime`, `donghua`, `drama`, `western`, `comics`, `novels` and `mixed`.

To add the repo, people paste its address in **Browse**, on the **Repos** tab. The address of the folder works, and so does the address of `versioning.json`.

### An Open in Sumizuri button

A page about your repo can have a button that opens the app and fills in the address for people. Make it a link like this:

```
sumizuri://add-repo?url=https%3A%2F%2Fexample.com%2Fmy-repo
```

Put the address of your repo after `url=`, encoded the way a web address is encoded inside another. In JavaScript, `encodeURIComponent` does it. The app opens on the Repos tab with the window for adding a repo, and the person still taps **Add** themselves. The link works on Android, on Windows once the app is installed with its setup, and on Linux once the app has been opened one time.

## 6. Sumizuri additions

These are on top of the base format. An app that does not know them simply ignores them, so a source that uses them still runs there.

### 6.1 Anime

Set `medium` to `anime` in the repo. The chapters become episodes. Add one method:

```js
async getVideos(mangaId, chapterId) {
  return [
    {
      url: 'https://.../master.m3u8',
      quality: '1080p',
      headers: { Referer: 'https://example.com/' },
      subtitles: [{ url: 'https://.../en.vtt', label: 'English', language: 'en' }],
      audio: [{ url: 'https://.../ja.m3u8', label: 'Japanese', language: 'ja' }],
      intro: { start: 90000, end: 180000 },
      outro: { start: 1300000, end: 1390000 },
    },
  ];
}
```

Only `url` is needed. `intro` and `outro` are in milliseconds. The player offers to skip them.

### 6.2 Seasons

A chapter or episode can say which season it is in. The title page groups them by season.

| Field | What it is |
| --- | --- |
| `season` | The id of the season. |
| `seasonName` | The name shown for it. |
| `seasonCover` | A cover for the season. |

### 6.3 Pick one tag

A tag section with `single: true` lets the person pick one tag of it, or none:

```js
{ id: 'type', label: 'Type', single: true, tags: [{ id: 'manga', label: 'Manga' }, { id: 'manhwa', label: 'Manhwa' }] }
```

### 6.4 Banner

`mangaInfo` can have a `banner`, a wide picture shown behind the title page.

### 6.5 A whole book

A chapter that is a PDF or an EPUB file can point at the file in place of giving its pages:

```js
return { book: { url: 'https://.../volume-1.epub', headers: { Referer: 'https://example.com/' } } };
```

The app fetches the file through the source, so its address must be one the source may reach. A PDF shows as pages of pictures, and an EPUB as words. The app keeps the last few books, so opening one again does not fetch it again.
