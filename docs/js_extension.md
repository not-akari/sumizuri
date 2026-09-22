# Writing a Sumizuri JS extension

A JS file needs one global object named `extension`, with five methods.
(An anime source defines `getVideoList` instead of `getPageList`, see
below.)

```js
var extension = {
  search: function (query, page) { /* ... */ },
  getPopular: function (page) { /* ... */ },
  getLatest: function (page) { /* ... */ },
  getChapterList: function (entryUrl) { /* ... */ },
  getPageList: function (chapterUrl) { /* ... */ },
};
```

A method can be a plain function or an `async` one, either works. Throw
an error when something fails.

## Metadata (optional)

```js
var extension = {
  name: "My Source",
  lang: "en",
  iconUrl: "https://example.com/icon.png",
  baseUrl: "https://example.com",
  rateLimitMs: 500, // optional, slows down requests (for example while updating the library)
  // ...
};
```

## search / getPopular / getLatest

Return a list of Entry objects. `page` starts at 1.

```js
{
  url: "...",        // required
  title: "...",       // required
  coverUrl: "...",     // optional
  bannerUrl: "...",    // optional
  webUrl: "...",       // optional: the title's own page on the website, when url is an API address
  author: "...",       // optional
  description: "...",  // optional
  rating: 8.7,          // optional
  status: "Ongoing",    // optional
  genres: ["Action"],   // optional
}
```

## getChapterList(entryUrl)

Return a list of Chapter objects.

```js
{
  url: "...",         // required
  title: "...",        // required
  number: 12.5,          // optional
  dateUploaded: "2024-01-01T00:00:00.000Z", // optional, ISO 8601
  locked: false,          // optional, see "Locked chapters" below
  unlocksAt: null,        // optional, see "Locked chapters" below
}
```

An anime episode can also carry `season`, `seasonName`, and
`seasonCoverUrl`, see [anime_extension.md](anime_extension.md).

## getPageList(chapterUrl)

Return a list of Page objects.

```js
{
  index: 0,       // required
  imageUrl: "...", // manga
  text: "...",     // novel, never set both
}
```

## getVideoList(chapterUrl)

For an **anime** source, use this instead of `getPageList`. It returns
the videos of one episode, best one first. A source must define either
`getPageList` or `getVideoList`. The source's media type decides which
one the app calls. The Video shape (`url`, quality, headers, subtitles,
audio tracks, intro and outro), how to find a stream address, and how to
test it are all covered in [anime_extension.md](anime_extension.md).

## Optional methods

- `getDetails(entryUrl)`: returns one Entry, called on the detail page.
- `getComments(entryUrl, sort)`: returns a list of Comment, for a series
  page.
- `getChapterComments(chapterUrl, sort)`: returns a list of Comment, for
  a chapter page.
- `getFilters()`: returns a list of FilterGroup, for search filters.
- `getSourcePreferences()`: returns a list of SourcePreference, for
  settings saved for this source.

`sort` is `"newest"`, `"oldest"`, or `"top"`. You can use it or ignore
it.

```js
{
  author: "...", // required
  text: "...",    // required
  date: "2024-01-01T00:00:00.000Z", // optional
  avatarUrl: null, // optional
}
```

### getSourcePreferences()

Returns a list of settings that show up in the source's own settings
screen, and are saved for the user:

```js
getSourcePreferences: function () {
  return [
    {
      key: "preferred_server",
      title: "Preferred Server",
      type: "list", // "editText", "switch", "list", or "multiSelectList"
      options: [
        { label: "Server 1", value: "s1" },
        { label: "Server 2", value: "s2" },
      ],
      defaultValue: "s1",
    },
    {
      key: "show_adult",
      title: "Show 18+ Content",
      type: "switch",
      defaultValue: false,
    },
  ];
}
```

Mangayomi's own preference shapes, such as `EditTextPreference`,
`CheckBoxPreference`, `ListPreference`, and `MultiSelectListPreference`
with `entries`/`entryValues`, are also fully supported.

You can read a saved preference anywhere in the extension with:
- `host.preference.get(key)`
- `getPreferenceValue(key)` or `getPreferenceValue(sourceId, key)`
- `host.preference.all()`

### getFilters() and search(query, page, filters)

`getFilters()` returns a list of filter groups:

```js
getFilters: function () {
  return [
    {
      key: "genre",
      name: "Genre",
      type: "select", // "select", "multiSelect", or "checkbox"
      options: [
        { label: "All", value: "" },
        { label: "Action", value: "action" },
        { label: "Romance", value: "romance" },
      ],
      defaultIndex: 0,
    },
    {
      key: "completed",
      name: "Completed only",
      type: "checkbox",
      defaultValue: false,
    },
  ];
}
```

When `search` is called, `filters` is passed in as the third argument:

```js
search: function (query, page, filters) {
  // filters = { genre: "action", completed: true }
}
```

Any of these optional methods can be left out. Sumizuri just hides the
matching part of the UI.

## Locked chapters

Set `locked: true` for a chapter that sits behind a login or a paywall
Sumizuri cannot get past.

Set `unlocksAt` (an ISO 8601 date) for a chapter on a wait timer that
becomes free later. Sumizuri shows a countdown for it.

These two settings are independent of each other, and only change what
is shown, nothing else.

## Host functions

This is a plain JS sandbox. Nothing is global except the functions
below.

**`host.fetch(url, options)`**

```js
var response = await host.fetch(url, { method: "GET", headers: {}, body: "" });
// response.statusCode, response.body, response.headers
```

Cookies are saved and sent automatically for you.

**`fetch(url, options)`**

The same thing as `host.fetch`, but shaped like a browser's own `fetch`.

```js
var response = await fetch(url);
var text = await response.text();
var json = await response.json();
// response.ok, response.status, response.url (after any redirects), response.redirected
// response.headers.get("content-type")  (any letter case), response.headers.has(name)
```

Beyond the usual options, `json: value` sends a JSON body, `form: { a: 1
}` sends a form, and a `URLSearchParams` body is sent as a form too. A
request with a body is treated as a POST unless you say otherwise. Any
header you set yourself is never overridden.

**`URL`, `URLSearchParams`, `TextEncoder`, `TextDecoder`**

The usual ones, for building and reading addresses, and turning text
into bytes and back (as UTF-8).

```js
var u = new URL("../ep-2", "https://site.tv/anime/naruto/ep-1"); // resolves the same way a browser would
u.searchParams.set("server", "2");
u.href; // "https://site.tv/anime/ep-2?server=2"
```

**`host.query(html, selector)`**

```js
var results = await host.query(html, "div.title a");
// results[0].text, results[0].html, results[0].attributes.href
```

**`host.parse(html)`**

Parses a page once, then gives you back a document you can ask many
questions of, with CSS selectors or XPath:

```js
var doc = await host.parse(html);
var rows = await doc.select("div.ep");            // elements
var first = await rows[0].selectOne("a");         // search inside one element
var link = first.attributes.href;                 // .text .html .attributes .tag
var hrefs = await doc.xpath("//div[@class='ep']/a/@href"); // strings, for attributes or text()
var title = await doc.text("h1");                 // first match's text, or null
var cover = await doc.attr("img.cover", "src");   // first match's attribute, or null
```

`select` and `xpath` take `{ html: false, limit: 20 }` if you want to
skip the inner HTML or stop early on a big page. Besides the usual CSS
selectors, `:has(...)` and `:contains("text")` also work. Only the 24
most recently parsed pages are kept. Asking for an older one is refused
with a message telling you to parse it again. A bad selector is refused
with the selector shown in the message.

`host.query(html, selector)` still works, and now reuses the parsed page
too.

**`host.render(url, options)`**

Loads a page in a real, hidden browser, lets the page's own JavaScript
run, and gives you back the page as it looks once that has finished. Use
this when a page comes back empty from `fetch` (the Requests tab in the
test panel shows an almost empty page), because the site builds its
content with JavaScript.

```js
var page = await host.render(url, {
  waitFor: ".episode-list",     // wait until this CSS selector exists
  waitForResource: /\.m3u8/,    // or until the page has loaded an address like this
  capture: /\.m3u8/,            // which loaded addresses to send back in page.resources
  script: "document.title",    // JavaScript to run once ready; its value becomes page.result
  timeout: 20000,              // milliseconds, up to 60000
});
// page.html      the finished page (parse it with host.parse)
// page.url       where it ended up after any redirects
// page.resources the addresses the page loaded that matched capture, in order
// page.result    what script evaluated to, as text
// page.timedOut  true if waitFor / waitForResource never showed up (the page is still returned)
```

`waitForResource` and `capture` are how you find a stream address that a
player only asks for once it starts playing, without reading the site's
own scripts.

Some things to know: it is slower than `fetch`, since a whole page has to
load, so only use it where `fetch` is not enough. Pages are rendered one
at a time. It works on Windows, Android, iOS, and macOS, but not Linux.
It does not get past CAPTCHAs or bot checks. Solve those in the browser
screen the app offers instead, and that session is kept for later. It
refuses private or internal addresses, even after a redirect. The
Requests tab in the test panel lists each render as `RENDER`, with the
finished page attached.

**`console.log(...)`**

`console.log`, `info`, `warn`, `error`, and `debug` all show up in the
Source Editor's Console tab while testing. Any value works, and objects
are printed as JSON.

**`host.hash(algorithm, input)`**

```js
var digest = await host.hash("sha256", "text to hash");
```

`algorithm` is one of `md5`, `sha1`, `sha224`, `sha256`, `sha384`, or
`sha512`.

**`atob(str)` / `btoa(str)`**

The usual base64 decode and encode, done right away (not async).

**`host.crypto`**

Video sites often hide their stream address behind encryption. These
functions are handled by the app itself, so they are fast and correct:

```js
// AES. mode: "cbc" (default), "ecb", "ctr" or "gcm". The key must be 16, 24 or 32 bytes.
var url = await host.crypto.aes.decrypt(base64Text, {
  key: "0123456789abcdef", iv: "fedcba9876543210",
  // keyEncoding / ivEncoding / dataEncoding / output: "utf8" | "hex" | "base64"
  // decrypt reads base64 and writes utf8 by default; encrypt does the opposite.
  // padding: "none" skips PKCS7 (for cbc and ecb). For gcm the tag is the last 16 bytes.
});

// What CryptoJS.AES.encrypt(text, "password") produces ("Salted__" in base64):
var text = await host.crypto.aes.decrypt(salted, { passphrase: "password" });

var mac = await host.crypto.hmac("sha256", key, message, { output: "hex" });
```

A wrong key or broken data is refused with a message saying so, instead
of quietly returning nonsense.

**`require(name)`**

```js
var entities = require("entities"); // entities.decode(str)
var url = require("url");           // url.resolve(baseUrl, url): a simple joiner
                                    // url.absolute(base, ref): resolves like a browser
var date = require("date");         // date.parse(str)
var base64 = require("base64");     // encode(text), decode(b64) as UTF-8, toBytes(b64)
var crypto = require("crypto");     // the same thing as host.crypto
var unpacker = require("unpacker"); // unpack(script), unpackAll(html)
var hls = require("hls");           // isMaster(text), parseMaster(text, baseUrl), expand(video)
```

`base64.decode` also accepts a missing `=` and the URL-safe alphabet, and
reads the result as UTF-8 (`atob` only gives you Latin-1).

**`unpacker`** opens the `eval(function(p,a,c,k,e,d){...})` scripts many
video embed pages use, and gives back the plain text they would have
run, with the stream address readable again. `unpackAll(html)` opens
every one of these on a page at once.

**`hls`** reads playlists. `parseMaster(text, baseUrl)` returns
`{ variants, audio, subtitles }`: the available qualities (`url`,
`quality` such as "1080p", `bandwidth`, `width`, `height`, `codecs`),
best one first, with full addresses. `expand(video)` takes a video whose
`url` is a master playlist and returns an "Auto" video (the master
itself), followed by one video per quality, so the viewer can pick one
and a download only needs to save a single stream. A playlist that keeps
its audio in a separate track is left unchanged, since one quality on
its own would have no sound. Any failure also just returns the video
unchanged.

**`host.storage`**

A persistent key-value store for this source alone, safe to use from any
isolate (it is saved to `storage.json` on disk):
- `await host.storage.get(key)`: returns the value, or `null`
- `await host.storage.set(key, value)`: stores any value that can be
  turned into JSON
- `await host.storage.delete(key)`: removes one key
- `await host.storage.clear()`: removes every stored key
- `await host.storage.all()`: returns everything that is stored

**`host.preference` / `getPreferenceValue`**

Reads the settings the user has changed for this source (saved to
`preferences.json` on disk):
- `await host.preference.get(key)`: returns the user's choice, or the
  default
- `getPreferenceValue(key)` or `getPreferenceValue(sourceId, key)`: a
  shorter way to write the same thing
- `await host.preference.all()`: returns every setting

**`host.isTesting`**

A true or false value. It is `true` while the extension runs inside the
Source Editor's Test panel, and `false` during normal use (library
updates, browsing, and so on). Useful for printing extra detail, or
running a smaller version of something, while you are developing.

## Not available

There is no filesystem access. No network access except through
`host.fetch`/`fetch`. No DOM. No Node.js. Nothing here gets past
Cloudflare or a similar bot check on its own.

## Limits

Each source runs in its own isolate, separate from the rest of the app.
A call that gets stuck is stopped after 15 seconds, and the extension is
reloaded.

## Example

```js
var extension = {
  search: async function (query, page) {
    var response = await host.fetch(
      "https://example.com/search?q=" + encodeURIComponent(query) + "&page=" + page
    );
    var items = await host.query(response.body, "div.result");
    return items.map(function (item) {
      return {
        url: item.attributes["data-id"],
        title: item.text,
        coverUrl: null,
      };
    });
  },

  getPopular: async function (page) { return []; },
  getLatest: async function (page) { return []; },

  getChapterList: async function (entryUrl) {
    var response = await host.fetch("https://example.com/title/" + entryUrl);
    var items = await host.query(response.body, "a.chapter-link");
    return items.map(function (item) {
      return { url: item.attributes.href, title: item.text };
    });
  },

  getPageList: async function (chapterUrl) {
    var response = await host.fetch(chapterUrl);
    var images = await host.query(response.body, "img.page-image");
    return images.map(function (img, i) {
      return { index: i, imageUrl: img.attributes.src };
    });
  },
};
```
