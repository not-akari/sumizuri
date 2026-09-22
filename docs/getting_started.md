# Building your first source

This is a guide for total beginners. You do not need to know JavaScript or
CSS. By the end you will have one working source. For every detail this
guide skips, see [json_extension.md](json_extension.md) (every JSON field)
and [js_extension.md](js_extension.md) (the JS format, for harder sites).

## What a source is

A source tells Sumizuri four things about one site:

1. How to search it.
2. How to list its popular and latest titles.
3. How to turn one title into a list of chapters.
4. How to turn one chapter into readable pages.

That is all. An anime source is almost the same, except the last step
lists the videos of an episode instead of pages. See
[anime_extension.md](anime_extension.md) for that.

Most sites can be described with the **JSON** format: you just fill in a
few URLs and say where each piece of data sits on the page. You do not
write any code for this. A harder site may need the **JS** format instead,
which lets you write real logic. This guide only covers JSON, since it
covers almost every site.

## Step 1: Open the Source Editor

Go to Browse, then tap the **+** button in the top right. Pick **JSON
declarative**. Fill in the Info section:

- **Name**: whatever you want shown for this source.
- **Base URL**: the site's homepage, for example `https://example.com`.
  Do not add a slash at the end.
- **Language** and **Media type**: pick what matches the site.
- **Icon URL**: optional.

You can write the JSON in any text editor you like and paste it into the
Code tab. You only need to open Sumizuri to test and save it.

## Step 2: Find a page to copy from

Pick a page that lists titles. Popular or latest is usually the easiest to
start with. Open **HTML Inspector**, paste that page's URL in, and tap
**Fetch**. This shows you the real HTML the site sends back. This is the
HTML your source will read.

## Step 3: CSS selectors, the short version

A selector is a short piece of text that finds elements on a page. A few
examples:

- `div.item` finds every div with the class `item`.
- `a` finds every link.
- `img.cover` finds every image with the class `cover`.
- `div.item a.title` finds a link with the class `title`, but only if it
  sits inside a `div.item`.

### Finding the right block

The easiest way: open the real site in a normal browser, right click a
title's cover or its name, and choose **Inspect**. This jumps straight to
that element's HTML. Do this once per site to work out your selectors.

A second way: use the HTML Inspector's filter box. Type a word you know is
on the page, and it narrows the view down to the matching lines.

Either way, you are looking for the smallest tag that wraps one whole
title and repeats once for every item on the page:

```html
<div class="manga-item">
  <a href="/series/my-manga">
    <img class="cover" src="https://example.com/covers/my-manga.jpg">
    <span class="title">My Manga</span>
  </a>
</div>
```

`div.manga-item` is the selector for one item. This becomes your
`itemSelector`. Everything else you write is found inside it.

## Step 4: Write `popular`

```json
"popular": {
  "url": "{baseUrl}/popular?page={page}",
  "itemSelector": "div.manga-item",
  "fields": {
    "url": { "selector": "a", "attr": "href", "resolve": true },
    "title": { "selector": "span.title", "attr": "text" },
    "coverUrl": { "selector": "img.cover", "attr": "src" }
  }
}
```

- `url` is the page to fetch. `{baseUrl}` and `{page}` are filled in for
  you automatically.
- `itemSelector` finds every title on the page.
- `fields` says where to read each piece of data. `selector` says where,
  `attr` says what to read. `"text"` means the text you can see on the
  page. Anything else is the name of an attribute, such as `href` or
  `src`.
- `resolve: true` turns a relative link into a full address. Add this to
  any field that reads a URL.

Match the selectors to the real site you are working on. The ones above
are only an example.

## Step 5: Test it

Tap **Test**, pick **Popular**, and run it. If the result is empty or
wrong, check these things:

- Does `itemSelector` actually match something in the Inspector?
- Is `attr` right? A common mistake is using `"text"` on an `<img>`, when
  you want `"src"` instead. Also check you have not forgotten
  `resolve: true`.
- If the real content is not in the Inspector at all, the site probably
  builds it with its own JavaScript after the page loads. Add
  `"render": true` to that section. See "Pages that build themselves with
  JavaScript" in [json_extension.md](json_extension.md).

Test each section as you write it. This habit is what keeps building a
source fast.

## Step 6: `latest` and `search`

`latest` is usually just `popular` with a different URL. `search` has the
same shape, with `{query}` added:

```json
"search": {
  "url": "{baseUrl}/search?q={query}&page={page}",
  "itemSelector": "div.manga-item",
  "fields": { "url": {...}, "title": {...}, "coverUrl": {...} }
}
```

Test each one.

## Step 7: `chapters`

Open one real title's page in the Inspector (you can copy a URL from your
`popular` test). Find the block of HTML that repeats once per chapter:

```json
"chapters": {
  "url": "{entryUrl}",
  "itemSelector": "ul.chapter-list li a",
  "fields": {
    "url": { "attr": "href", "resolve": true },
    "title": { "attr": "text" }
  }
}
```

`{entryUrl}` is the title's own URL, filled in for you automatically.
Leaving `selector` off a field means "read the item itself", which works
here because `itemSelector` already points straight at the link.

Test this with a real title's URL.

## Step 8: `pages`

For manga, find the repeating image tags:

```json
"pages": {
  "url": "{chapterUrl}",
  "itemSelector": "div.page-container img",
  "fields": {
    "imageUrl": { "attr": "src" }
  }
}
```

For a novel, use one text block instead:

```json
"pages": {
  "url": "{chapterUrl}",
  "itemSelector": "div.chapter-content",
  "fields": {
    "text": { "attr": "html", "transform": "htmlToText" }
  }
}
```

Test it, then save. You now have a complete, working source.

<details>
<summary>What this would look like in JS instead</summary>

The JS format does the same thing, but as real code, with no
`itemSelector`/`fields` shape at all. Here is what step 4 (`popular`)
looks like written that way:

```js
getPopular: async function (page) {
  var response = await host.fetch("https://example.com/popular?page=" + page);
  var items = await host.query(response.body, "div.manga-item");
  return items.map(function (item) {
    return {
      url: item.selectOne("a").attributes.href,
      title: item.selectOne("span.title").text,
      coverUrl: item.selectOne("img.cover").attributes.src,
    };
  });
}
```

Only use this format if a site genuinely needs it (fetching more than one
page, running some logic, and so on). See
[js_extension.md](js_extension.md) for the full format.

</details>

## Where to go from here

- [json_extension.md](json_extension.md): every JSON field, multi-page
  results, fields that only apply sometimes, and a small JS escape hatch
  for the one field that needs it.
- [js_extension.md](js_extension.md): the full JS format, for a site that
  needs real logic all through.
- [anime_extension.md](anime_extension.md): building an anime source
  instead. Set **Media type** to anime and the editor starts you from an
  anime template. Step 8 becomes a `videos` section (JSON) or a
  `getVideoList` method (JS), and the Test panel can run that step too.
