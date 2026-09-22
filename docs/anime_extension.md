# Writing an anime source

This page covers everything specific to anime sources in one place: how
episodes and videos are listed, how to find a stream address on a
stubborn site, what the player does with what you give it, and how to
debug a source that will not play. It covers both formats, JSON and JS.
The rest of the schema for each format lives in
[json_extension.md](json_extension.md) and
[js_extension.md](js_extension.md).

## The short version

An anime source is an ordinary source with two differences:

1. Its **media type** is `anime` (set in the Source Editor, or as
   `mediaType` in the repository index, see [repository.md](repository.md)).
   It then shows up under Browse > Anime, and an episode opens in the
   player instead of the reader.
2. Where a manga source lists the **pages** of a chapter, an anime source
   lists the **videos** of an episode.

| Step | JSON source | JS source |
|---|---|---|
| Search, popular, latest | `search`, `popular`, `latest` sections | `search`, `getPopular`, `getLatest` |
| The episodes of a title | `chapters` section | `getChapterList` |
| The videos of an episode | `videos` section | `getVideoList` |

Episodes are just chapters, as far as the title's own page goes. The
only new step is the last one.

## Episodes

Each episode is one item in `chapters` / `getChapterList`:

```json
{ "url": "...", "title": "Episode 4", "number": 4, "dateUploaded": "2024-05-01T00:00:00Z" }
```

- **url** is required, and so is at least one of **title** or **number**.
  A source that only gives a number, which many anime sites do, gets the
  title "Episode N" for free.
- Keep **url** the same every time you refresh the list. The library
  remembers an episode, and whether it was watched, by its address. If a
  source ever changes what it uses as the address, Sumizuri still
  recognizes the same episode by its number and title and carries the
  watched state across, but a stable address avoids the problem
  entirely.
- Anime titles refresh from the source every time they are opened, so
  new episodes show up without needing to press refresh.

### Seasons

If one title lists several seasons, give each episode a season, and its
page shows one poster per season. Opening one lists only that season's
episodes:

```js
{ url: "...", title: "Episode 1", number: 1, season: 2, seasonName: "Part 2", seasonCoverUrl: "https://..." }
```

- **season** is either a number (`2`) or a label (`"Movies"`).
  **seasonName** is what to call it. Without it, a numbered season shows
  as "Season 2", and a label just shows as itself. **seasonCoverUrl** is
  the season's poster. Without it, the title's own poster is used
  instead. You only need to set these on one episode from each season.
- Numbered seasons are listed first, in order, then labelled ones in the
  order you listed them, then any episode with no season at all. A title
  with only one season, or none, is listed the same way it always was.
- In a JSON source, `season`, `seasonName`, and `seasonCoverUrl` are just
  ordinary fields on `chapters`, often read from a heading or a data
  attribute.

If each season is really a separate title on the site, you do not need
any of this.

## Videos

A video is one way to watch the episode. There is one per quality or
server, with the **best one listed first**, since the player starts with
whichever one is first unless the viewer picks something else.

```js
{
  url: "https://cdn.example/ep1/master.m3u8",   // required
  quality: "1080p",                             // shown in the picker: "720p Sub", "Server 2"
  headers: { Referer: "https://example.com/" }, // sent with every request for this video
  subtitles:   [{ url: "...", label: "English", language: "en" }],
  audioTracks: [{ url: "...", label: "English dub", language: "en" }],  // a dub, to pair with a video that has none
  intro: { start: 90, end: 180 },               // seconds, optional
  outro: { start: 1300, end: 1420 },
}
```

**url** must be a full `https://` (or `http://`) address: either a video
file (`.mp4`, `.mkv`), or an HLS (`.m3u8`) or DASH (`.mpd`) playlist. An
address that starts with `//cdn.example/x.m3u8` is given `https:`
automatically. Anything else, such as a bare `/master.m3u8`, is refused
with a message explaining why, since otherwise the player would try to
look for a file by that name on the viewer's own computer. Only text
values are kept in `headers`. A subtitle or audio entry with no `url` is
skipped. A video the app cannot read is skipped and the rest still play.
If none of them can be read, the reason is shown to the viewer.

### In a JS source

```js
getVideoList: async function (chapterUrl) {
  var response = await host.fetch(chapterUrl);
  var sources = await host.query(response.body, "video source");
  return sources.map(function (source) {
    return {
      url: source.attributes.src,
      quality: source.attributes.label,
      headers: { Referer: "https://anime.example/" },
    };
  });
},
```

Anything a normal JS source can do also works here, including several
requests in a row, decoding, and `host.render`. See
[Finding the stream](#finding-the-stream) below.

### In a JSON source

`videos` is an ordinary list section (`url`, `itemSelector` or
`itemsPath`, `fields`), with `{chapterUrl}` standing in for the episode:

```json
"videos": {
  "url": "{chapterUrl}",
  "itemSelector": "video source",
  "fields": {
    "url": { "attr": "src" },
    "quality": { "attr": "label" }
  },
  "videoHeaders": { "Referer": "{baseUrl}/" }
}
```

Its own extra options:

- **videoHeaders** are what the *player* sends when it fetches the
  video, most often just a `Referer`. These are separate from the
  section's own `headers`, which fetch the page. The two are kept apart
  on purpose, so an API key used to fetch the page is never sent to a
  video host by mistake. `{baseUrl}`, `{chapterUrl}`, and `{chapterSlug}`
  all work inside them.
- **subtitles** and **audioTracks** are their own lists, attached to
  every video of the episode. Without a `url` of their own, they read
  the same page `videos` does, so only one fetch happens for both.

  ```json
  "subtitles": {
    "itemsPath": "data.subtitles",
    "fields": { "url": { "path": "src" }, "label": { "path": "name" }, "language": { "path": "lang" } }
  }
  ```

- **intro** and **outro** each read one `{ start, end }` pair, in
  seconds, from the page, the same way a details section reads one
  value, and it applies to every video:

  ```json
  "intro": { "itemsPath": "intro", "fields": { "start": { "path": "start" }, "end": { "path": "end" } } },
  "outro": { "itemsPath": "outro", "fields": { "start": { "path": "start" }, "end": { "path": "end" } } }
  ```

  A missing marker, or one where the times do not make sense (the end is
  not after the start, or either one is negative), is simply left off.
  That only costs the skip button, never the video itself.
- **expandPlaylists** (`true`) splits each HLS master playlist into an
  "Auto" video (the master itself) plus one video per quality it lists,
  so the viewer can choose one. A master that keeps its audio in a
  separate track is left as it is, since a single quality on its own
  would have no sound.
- **render** reads the page the way a browser shows it, after its own
  JavaScript has run. See below.
- A `join` field can take **requireAll: true**: the value becomes empty
  if any one piece is missing, instead of joining just the pieces that
  are there. Use this for an address built from several parts, so a
  missing part gives no address at all, rather than a broken one like
  `/master.m3u8`.

## Finding the stream

Sites hide their streams to different degrees. Work down this list, and
stop at the first step that works for the site you are building:

1. **The address is right there in the page.** A `<video>` or `<source>`
   tag, or a plain link. A selector reads it (`attr: "src"`).
2. **The address comes from another request.** The page gives you an id,
   a second request turns that into an embed page, and a third gives you
   the stream. In JSON this is a `resolve` list (see "A lookup before
   the main request" in [json_extension.md](json_extension.md)). In JS
   it is just a few `host.fetch` calls in a row.
3. **The response is JSON, not a page.** Use `itemsPath` and `path`. If
   the JSON holds a page's HTML inside one field, `htmlPath` names that
   field (`"*"` picks the longest string that contains markup).
4. **The address is wrapped somehow.** In JSON, `decode` can open
   `"base64"`, `"urlDecode"`, `"unpack"` (a `p.a.c.k.e.r` script, so a
   `regex` after it can pick the address out of the text), and
   `"megaplay"` (MegaPlay's encrypted streams). In JS, use
   `require("base64")`, `require("unpacker")`, or `host.crypto` (AES and
   HMAC, including the CryptoJS password format) for anything behind
   encryption.
5. **The page builds its own content with JavaScript.** A plain request
   only returns an almost empty shell. `render` (JSON) or `host.render`
   (JS) loads the page in a hidden browser and waits for it:

   ```json
   "videos": {
     "url": "{chapterUrl}",
     "render": { "waitForResource": "\\.m3u8", "capture": "\\.m3u8" },
     "itemSelector": "#sumizuri-captured a",
     "fields": { "url": { "attr": "href" } }
   }
   ```

   `waitFor` waits for a selector to appear, `waitForResource` waits for
   an address the page loads, and `capture` picks which loaded addresses
   come back to you. The addresses that were captured get added to the
   page as links, inside `<div id="sumizuri-captured">`, so a selector
   can read them out. This only works for GET requests, and a `videos`
   section and its subtitles share one render between them. It is
   slower than a plain fetch, so only use it when steps 1 to 4 do not
   work. It does not get past CAPTCHAs or bot checks (solve those in the
   browser screen the app offers instead), and it works on Windows,
   Android, iOS, and macOS. The full detail is in
   [js_extension.md](js_extension.md), under `host.render`.

If the final address turns out to be an HLS master playlist,
`expandPlaylists` (or `require("hls").expand(video)` in JS) turns it
into one video per quality.

## What the player does with it

- **Which video plays first.** In Settings > Player, the viewer can
  choose to start each episode with the last quality they picked, the
  best one, or the lowest one. The quality comes from your `quality`
  label ("1080p", "720p Sub", "4K"). A label with no resolution in it is
  just left in the order you gave. **Sub or dub** is worked out by
  looking for that word in the label ("Sub", "Dub", "Softsub"), so label
  your videos with it.
- **Subtitles.** The viewer can set a preferred language, which is
  matched against each track's `language` and `label`, along with a
  colour, style, size, and position. A track already inside the video is
  tried first, then the ones you list. Give `language` either a code
  (`en`) or a name (`English`).
- **Skip buttons.** With `intro` and `outro` set, the player shows "Skip
  intro" and "Skip ending" exactly when they apply. If the ending runs
  all the way to the end of the video, it goes straight to the next
  episode instead. Without these set, there is only a fixed length skip
  button.
- **Headers.** `headers` and `videoHeaders` are sent with every request
  for the video, including each individual piece of a playlist.
- **Casting.** A "Cast" button in the player (on Android and iOS) sends
  the playing video to a Chromecast on the same Wi-Fi, using Google's
  own "Default Media Receiver". A downloaded episode is served to the
  Chromecast from a small local server this device runs for as long as
  it is casting. A video played straight from a source is sent by its
  own address instead. Either way, the receiver fetches the video
  itself, and does not send any `headers` a source set, so a source
  whose video needs headers to load cannot be cast. The stock receiver
  also only plays formats a Chromecast understands on its own (MP4 and
  WebM are safe choices, a raw `.ts` or `.mkv` file is not).
- **Downloads.** Plain files (`.mp4`, `.mkv`), HLS playlists (`.m3u8`,
  master or media), and DASH manifests (`.mpd`) can all be downloaded
  for offline viewing. A download picks the quality named in the
  video's `quality` label ("1080p"), or the sharpest one if none match,
  and needs the same `headers` the video plays with. Video and audio are
  saved as separate files when the stream keeps them apart, the same as
  when an HLS stream has a separate audio track. HLS streams that use
  SAMPLE-AES encryption, and any live (non-VOD) stream, cannot be
  downloaded. A DASH stream with DRM (a `ContentProtection` entry in its
  manifest) is refused rather than attempted.
- **A bad stream.** A few damaged pieces are skipped and playback keeps
  going. A dropped connection restarts playback from the same spot, up
  to three times, before the viewer sees an error.

## Testing and debugging

In the Source Editor, open the **Test** panel and pick **Videos**, then
paste in an episode address. You get four tabs:

- **Result**: what your source returned, with how many headers,
  subtitles, and audio tracks each video has.
- **Requests**: every request the source made, with its response, so you
  can see whether a page came back empty or was refused outright.
- **Console**: `console.log` output from a JS source.
- **Findings**: what looks wrong, written in plain words (a 403 that
  needs a header, a selector that matched nothing, a field that came
  back empty on every item, episodes listed twice).

The copy button puts the whole run, including your source, on the
clipboard, as a report you can paste when asking for help. A JSON source
is also checked as you type for misspelled options and missing pieces.

While an episode is playing, a small **log at the top of the player**
(off by default, turn it on in Settings > Advanced > Show the video log)
shows what happened: the address it opened, what the source answered,
which video was chosen, any retries, and the player's own warnings, with
a button to copy all of it.

Common messages:

| You see | It means |
|---|---|
| `htmlPath "*" found no HTML in the response` | The response was JSON with no HTML inside it. The message lists its keys, so you can read those fields with `itemsPath` and `path` instead. |
| `The video address "/master.m3u8" is not a full address` | An address was built from several parts and one of them was missing. Add `requireAll: true` and find another way to get that missing part. |
| `The site answered 403` | It wants a header, usually `Referer`, sometimes `Origin` or `User-Agent`, either on the page request (`headers`) or on the video itself (`videoHeaders`). |
| `tcp: ffurl_read returned 0xffffff76` | The video host timed out. This is often the host's own fault. Try a different server, or check `videoHeaders`. |
| `Packet corrupt`, `Error decoding audio` | The stream is arriving damaged. The player keeps going. A different server may be cleaner. |
| An empty list, and `render` not used | The page probably builds itself with JavaScript. Try `render`. |

## Full example: JSON

A source whose episode page lists its videos as `<source>` tags. The
episodes are the chapters.

```json
{
  "name": "Example Anime",
  "lang": "en",
  "baseUrl": "https://anime.example",
  "iconUrl": "https://anime.example/icon.png",
  "popular": {
    "url": "{baseUrl}/popular?page={page}",
    "itemSelector": "div.anime",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "latest": {
    "url": "{baseUrl}/latest?page={page}",
    "itemSelector": "div.anime",
    "fields": {
      "url": { "selector": "a", "attr": "href" },
      "title": { "selector": "a", "attr": "text" },
      "coverUrl": { "selector": "img", "attr": "src" }
    }
  },
  "search": {
    "url": "{baseUrl}/search?q={query}&page={page}",
    "itemSelector": "div.anime",
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
```

## Full example: JS

The same source, with `getVideoList` in place of `getPageList`.

```js
var extension = {
  search: async function (query, page) { return []; },
  getPopular: async function (page) { return []; },
  getLatest: async function (page) { return []; },

  getChapterList: async function (entryUrl) {
    var response = await host.fetch(entryUrl);
    var items = await host.query(response.body, "ul.episodes li a");
    return items.map(function (item, i) {
      return { url: item.attributes.href, title: item.text, number: items.length - i };
    });
  },

  getVideoList: async function (chapterUrl) {
    var response = await host.fetch(chapterUrl);
    var sources = await host.query(response.body, "video source");
    return sources.map(function (source) {
      return {
        url: source.attributes.src,
        quality: source.attributes.label,
        headers: { Referer: "https://anime.example/" },
      };
    });
  },
};
```

## Not supported

- Streaming over torrents.
- Downloading an HLS stream with SAMPLE-AES encryption, or a DASH stream
  with DRM. Plain files, ordinary HLS, and ordinary DASH, including
  byte-range pieces, can all still be downloaded.
- Rendered pages on Linux.
