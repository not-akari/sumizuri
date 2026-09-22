# Writing a Sumizuri JSON source

This is a lighter and safer way to write a source than JS. You fetch a
URL, run a CSS selector on it, and map the fields you find. It is all
plain JSON, no code. Pick the JSON engine kind in the Source Editor.

This guide covers manga and novel sources. If you are building an anime
source, read [anime_extension.md](anime_extension.md) instead. It covers
the same schema, plus everything anime needs on top.

Behind the scenes, your JSON is turned into a normal extension and run in
the same sandbox, with the same cookies and timeouts, as a JS extension.
The difference is that you cannot write a raw JavaScript expression
anywhere in this format. Every field is one of the fixed shapes below,
so nothing here can run arbitrary code. See
[js_extension.md](js_extension.md) if you want to know how a source
actually runs. This guide only covers the JSON shape itself.

You can write `//` and `/* */` comments anywhere outside a string.

## Top level fields

```json
{
  "name": "My Source",
  "lang": "en",
  "baseUrl": "https://example.com",
  "iconUrl": "https://example.com/icon.png",
  "rateLimitMs": 500,
  "search": {},
  "popular": {},
  "latest": {},
  "chapters": {},
  "pages": {},
  "videos": {},
  "details": {},
  "comments": {},
  "chapterComments": {},
  "filters": [],
  "preferences": []
}
```

`search`, `popular`, `latest`, and `chapters` are required. You also need
either `pages` (for manga or a novel) or `videos` (for anime, see
[anime_extension.md](anime_extension.md)). `details`, `comments`, and
`chapterComments` are optional, the same as in a JS extension.

`filters` is an optional list of search filters (a select, a multi
select, or a checkbox). `preferences` is an optional list of settings the
user can change, saved for this source. `rateLimitMs` slows down calls if
the site needs it, for example `500` for half a second between chapter
requests. Leave any of these out if the site does not need them.

### Source preferences

```json
"preferences": [
  {
    "key": "mirror",
    "title": "Preferred Mirror",
    "type": "select",
    "options": [
      { "label": "Mirror 1", "value": "https://node1.example.com" },
      { "label": "Mirror 2", "value": "https://node2.example.com" }
    ],
    "defaultValue": "https://node1.example.com"
  },
  {
    "key": "show_explicit",
    "title": "Show 18+ Content",
    "type": "switch",
    "defaultValue": false
  }
]
```

In any URL or request template, write `{pref_key}` or `{key}` to fill in
the value the user picked (or `defaultValue` if they have not changed
it).

### Search filters

```json
"filters": [
  {
    "key": "genre",
    "name": "Genre",
    "type": "select",
    "options": [
      { "label": "All", "value": "" },
      { "label": "Action", "value": "action" }
    ]
  }
]
```

In the `search` section's URL or request template, write `{key}` or
`{filter_key}` to fill in the value the user picked, for example
`{baseUrl}/search?q={query}&genre={genre}`.

## URL template (the common case)

```json
{
  "url": "{baseUrl}/popular?page={page}",
  "itemSelector": "div.manga-item",
  "fields": {
    "url": { "selector": "a", "attr": "href" },
    "title": { "selector": "a", "attr": "text" },
    "coverUrl": { "selector": "img", "attr": "src" }
  }
}
```

`url` is fetched, `itemSelector` matches each item on the page, and
`fields` turns each match into one Entry, Chapter, or Page.

**Placeholders you can use**: `baseUrl` (everywhere), `query` (search),
`page` (search, popular, latest), `entryUrl`/`entrySlug` (chapters,
details, comments), `chapterUrl`/`chapterSlug` (pages, chapterComments).
`entrySlug` and `chapterSlug` are just the last part of the matching URL.
Only `query` is URL encoded for you automatically.

### Pagination (reading more than one page for one call)

```json
{
  "url": "{baseUrl}/book/{entrySlug}/chapters",
  "itemSelector": "ul.chapter-list li a",
  "pagination": { "nextSelector": "a[rel=\"next\"]", "maxPages": 50 },
  "fields": { "url": { "attr": "href", "resolve": true }, "title": { "attr": "text" } }
}
```

`nextSelector` (for HTML) or `nextPath` (a dotted path, for JSON) finds
the link to the next page. `nextAttr` defaults to `href`. `maxPages`
defaults to 20.

### Field shapes

These are checked in order. The first shape that fits is used.

```json
{ "coverUrl": { "or": [ { "path": "cover_url" }, { "path": "thumbnail" } ] } }
```

`or`: uses the first field spec in the list that is not empty.

```json
{ "imageUrl": { "if": "string", "then": { "path": "" }, "else": { "path": "url" } } }
```

`if`/`then`/`else`: a simple way to say "use this value, or that one, it
depends". The type names are `string`, `number`, `boolean`, `array`,
`object`, `null`, `defined`, and `truthy`. Wrap one in `not`, `and`, or
`or` to check more than one thing. `if` can also point at one field:
`{ "if": { "path": "premium", "is": "truthy" } }`.

`selector` plus `attr`: reads inside the matched item. `attr` can be
`text` (the visible text) or the name of any attribute. Leave `selector`
out to read the matched item itself.

`path`: a dotted path into a JSON item.

```json
{ "url": { "template": "/series/{slug}", "resolve": true } }
```

`template`: builds a string out of this item's own fields (or `baseUrl`,
`page`, `query`, `entrySlug`, `chapterSlug`).

```json
{ "title": { "join": [{ "template": "Ch. {num}" }, { "path": "title" }], "separator": ": " } }
```

`join`: combines several field specs into one string. `separator`
defaults to a single space.

`selector` plus `attr` plus `all`: same as `selector` and `attr`, but
returns every match as a list instead of just the first one.

### Cleaning up a value (combine these freely)

- `regex`: keeps the first captured group (or the whole match if there is
  no group).
- `split` plus `index`: splits the text on a separator and keeps one
  piece. A negative index counts from the end.
- `transform`: `number`, `trim`, `capitalize`, `htmlToText` (for a novel
  chapter body, use it together with `"attr": "html"`), `unixTimestamp`
  (turns an epoch number into a date), `parseDate` (turns most other date
  strings into one too).
- `decode`: opens a value that is wrapped somehow, before anything else
  runs. The options are `"base64"`, `"urlDecode"`, `"unpack"` (for the
  text of a `p.a.c.k.e.r` script, so a `regex` after it can pick an
  address out), or `"megaplay"` (for MegaPlay's encrypted streams). You
  can also give a list of these to run one after another. A value that
  cannot be decoded becomes empty, so `default` kicks in.
- `requireAll: true` (on a `join`): makes the whole value empty if any one
  piece is missing, instead of joining just the pieces that are there.
  Use this for an address built from several parts, so a missing part
  gives no address at all, rather than a broken one like
  `/master.m3u8`.
- `round`: how many decimal places to keep for a number.
- `map`: a dotted path, used to pull one property out of every item in a
  list.
- `resolve: true`: turns a relative URL into a full one, against
  `baseUrl`.
- `resolveWeb: true`: same idea, but against the source's own top level
  `webBaseUrl` (the actual website) instead of `baseUrl` (which is often
  an API address). Use this for `webUrl`.
- `default`: the value to fall back to when everything else comes back
  empty.

```json
{
  "rating": { "path": "rating_text", "regex": "([0-9.]+)", "transform": "number", "round": 1 },
  "status": { "path": "status", "transform": "capitalize", "default": "Unknown" },
  "genres": { "path": "genres", "map": "name" }
}
```

### Pagination number settings

- `pageStart`: set this to `0` if a site's first page is page 0.
- `pageSize`: adds `offset` and `pageSize` placeholders, for an API that
  uses offset and limit instead of a page number.

```json
{
  "url": "{baseUrl}/list?offset={offset}&limit={pageSize}",
  "pageSize": 20,
  "itemSelector": "div.manga-item",
  "fields": { "url": { "selector": "a", "attr": "href" }, "title": { "selector": "a", "attr": "text" } }
}
```

### Sorting

```json
{ "sort": { "by": "number", "order": "desc" } }
```

`by` is a dotted path into the result you already mapped. `order` is
`asc` (the default) or `desc`. Anything with no value sorts to the end.

### Changing the request itself

A section can set its own method, headers, and body, all as string
templates.

```json
{
  "url": "{baseUrl}/api/list",
  "method": "POST",
  "headers": { "Content-Type": "application/json" },
  "body": "{\"page\": {page}, \"query\": \"{query}\"}",
  "itemsPath": "data.items",
  "fields": { "url": { "path": "id" }, "title": { "path": "name" } }
}
```

A top level `headers` field (next to `name`, `lang`, and `baseUrl`)
applies to every section. A section's own `headers` with the same name
override it.

### A lookup before the main request

```json
{
  "resolve": { "url": "{baseUrl}/api/resolve/{entrySlug}", "path": "id", "as": "entryId" },
  "url": "{baseUrl}/api/series/{entryId}/chapters",
  "itemsPath": "data",
  "fields": { "url": { "path": "id" }, "title": { "path": "name" } }
}
```

This fetches `url`, reads `path` out of the response, and makes it
available under the new placeholder name given by `as`.

`resolve` can also be a list of steps, run one after another, for a site
that needs more than one lookup, such as a session token or a hidden
address. Each step can read from JSON (`path`), from HTML (`selector`
plus `attr`, with an optional `htmlPath`), or from plain text (`regex`).
Each step can also set its own `headers` and `transform`:

```json
"resolve": [
  { "url": "{chapterUrl}", "htmlPath": "*", "regex": "data-link-id=\"([^\"]*)\"", "as": "linkId" },
  { "url": "{baseUrl}/ajax/server?get={linkId}", "path": "result.url", "as": "embedUrl" },
  { "url": "{embedUrl}", "headers": { "Referer": "{baseUrl}/" }, "regex": "data-id=\"([0-9]+)\"", "as": "megaId" }
]
```

### JSON API responses

Set `itemsPath` instead of `itemSelector`. It is a dotted path to the
list of results (leave it empty if the response itself is the list).
Fields then use `path` instead of `selector` and `attr`.

### HTML hiding inside JSON

Some sites answer an AJAX request with JSON, where one field holds a
piece of HTML:

```json
{ "status": 200, "result": "<ul>\n<li><a data-id=\"7\">...<\/a><\/li>\n<\/ul>" }
```

Running `itemSelector` directly on that raw text matches escaped
characters like `<\/li>`, `\n`, and `\t`, so titles come out broken and
blank duplicate rows show up. Add **htmlPath** to the section instead,
and that field is used as the page. Selectors and fields then work the
same way they would on any normal HTML page:

```json
{
  "chapters": {
    "url": "{baseUrl}/ajax/episode/list/{entrySlug}",
    "htmlPath": "result",
    "itemSelector": "li a[data-id]",
    "fields": { "title": { "selector": "span", "attr": "text" } }
  }
}
```

`htmlPath` is a dotted path to that field. Use `"*"` if you do not know
its name. It picks the longest string in the response that contains
markup. If a response turns out not to be JSON after all, it is used as
plain HTML as it is, so a site that sometimes sends plain HTML still
works. If a path finds no HTML at all, that is treated as an error, not
an empty list. This works on list sections and on `details`.

### Pages that build themselves with JavaScript

If a page comes back nearly empty because the site builds its content
with its own JavaScript, add `"render": true` to that section. The page
is then loaded in a hidden browser and read once its scripts have run.
Say what to wait for if it takes a moment:

```json
"chapters": {
  "url": "{entryUrl}",
  "render": { "waitFor": "ul.episodes li", "timeout": 20000 },
  "itemSelector": "ul.episodes li a",
  "fields": { "url": { "attr": "href" }, "title": { "attr": "text" } }
}
```

Options: `waitFor` (a CSS selector to wait for), `waitForResource` and
`capture` (patterns matched against the addresses the page loads, for
finding a stream, see [anime_extension.md](anime_extension.md)),
`script`, and `timeout` (in milliseconds, up to 60000). This only works
for GET requests, and it is slower than a plain request, so only use it
where a plain request is not enough. It does not get past CAPTCHAs or
bot checks. More detail is under `host.render` in
[js_extension.md](js_extension.md).

## details / comments / chapterComments

`details` produces one object, not a list, so it has no `itemSelector`.
For HTML, fields read straight off the page. For JSON, set `itemsPath` to
the object to read from, or leave it out to read from the response root.

```json
{
  "details": {
    "url": "{entryUrl}",
    "fields": {
      "url": { "template": "{entryUrl}" },
      "title": { "selector": "h1.title" },
      "description": { "selector": "div.synopsis" },
      "genres": { "selector": "span.genre", "all": true }
    }
  }
}
```

`url` and `title` are required, and are usually just
`{ "template": "{entryUrl}" }`.

`comments` and `chapterComments` work like a list section, with one extra
placeholder for sorting (`newest`, `oldest`, or `top`).

```json
{
  "comments": {
    "url": "{entryUrl}/comments?sort={sort}",
    "itemSelector": "div.comment",
    "fields": {
      "author": { "selector": ".author" },
      "text": { "selector": ".body" },
      "date": { "attr": "datetime", "transform": "parseDate" }
    }
  }
}
```

## Anime: the `videos` section

An anime source declares `videos` in place of `pages`. It lists the ways
to watch one episode. Everything about it, including `videoHeaders`,
subtitles, audio tracks, intro and outro markers, `expandPlaylists`,
`render`, and how to find a stream address, is covered in
[anime_extension.md](anime_extension.md).

## Field names by section

- `search`, `popular`, `latest`, and `details` each produce an **Entry**:
  `url` and `title` are required. `coverUrl`, `bannerUrl`, `author`,
  `description`, `rating`, `status`, and `genres` are optional.
  **webUrl** is the title's own page on the website. Set it when `url`
  is an API address, so "open in webview" shows the real site instead of
  raw data.
- `chapters` produces a **Chapter**: `url` and `title` are required.
  `number`, `dateUploaded`, `locked`, and `unlocksAt` are optional (see
  "Locked chapters" in [js_extension.md](js_extension.md)). For anime,
  `season`, `seasonName`, and `seasonCoverUrl` are also read, see
  [anime_extension.md](anime_extension.md).
- `pages` produces a **Page**: set `imageUrl` or `text`. `index` is
  filled in for you automatically.
- `videos` produces a **Video** for anime: `url` is required, see
  [anime_extension.md](anime_extension.md) for the rest of its fields.
- `comments` and `chapterComments` each produce a **Comment**: `author`
  and `text` are required. `date` and `avatarUrl` are optional.

## Full example: manga

```json
{
  "name": "Example Scans",
  "lang": "en",
  "baseUrl": "https://example.com",
  "iconUrl": "https://example.com/favicon.png",
  "popular": {
    "url": "{baseUrl}/popular?page={page}",
    "itemSelector": "div.manga-item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "latest": {
    "url": "{baseUrl}/latest?page={page}",
    "itemSelector": "div.manga-item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "search": {
    "url": "{baseUrl}/search?q={query}&page={page}",
    "itemSelector": "div.manga-item",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "chapters": {
    "url": "{entryUrl}",
    "itemSelector": "ul.chapter-list li a",
    "fields": {
      "url": { "attr": "href" },
      "title": { "attr": "text" },
      "dateUploaded": { "attr": "data-date", "transform": "parseDate" }
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
```

## Novel sources

A novel source is written the same way as a manga source, with one
difference: `pages` sets `text` instead of `imageUrl`. Pair a selector on
the chapter body with `"attr": "html"` and `"transform": "htmlToText"`,
which turns the HTML into plain, readable text:

```json
"pages": {
  "url": "{chapterUrl}",
  "itemSelector": "div.chapter-content",
  "fields": {
    "text": { "attr": "html", "transform": "htmlToText" }
  }
}
```

Everything else, search, popular, latest, and chapters, is written
exactly the way it is for a manga source.

## When to use JS instead

If a source needs more than one fetch in a row, real step by step logic,
or anything else these fixed shapes cannot express, write a full JS
extension instead. See [js_extension.md](js_extension.md).
