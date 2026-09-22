# Hosting a Sumizuri source repo

A repo is just a JSON file, hosted anywhere reachable by a URL: GitHub
Pages, a gist's raw URL, or your own server. To add it in Sumizuri (go to
Browse > Repos > Add repo), you only need that URL. The app fetches this
file live every time the repo is opened, so there is nothing else to do
beyond keeping the file up to date.

```json
{
  "name": "My Repo",
  "sources": [
    {
      "id": "galaxymanga",
      "name": "GalaxyManga",
      "lang": "en",
      "mediaType": "manga",
      "engineKind": "js",
      "version": 3,
      "iconUrl": "https://example.com/icon.png",
      "baseUrl": "https://galaxymanga.example",
      "fileUrl": "https://example.com/sources/galaxymanga.js",
      "nsfw": false
    },
    {
      "id": "exampleanime",
      "name": "Example Anime",
      "lang": "en",
      "mediaType": "anime",
      "engineKind": "json",
      "version": 1,
      "iconUrl": "https://anime.example/icon.png",
      "baseUrl": "https://anime.example",
      "fileUrl": "https://example.com/sources/exampleanime.json"
    }
  ]
}
```

- `name`: the repo's own display name.
- `sources`: one flat list. You can mix any media type freely, since
  each source is sorted into the right Browse screen by its own
  `mediaType`.
- `id`: this repo's own stable id for the source. It is not a Sumizuri
  database id. Keep it the same across every version, since this is how
  Sumizuri tells that a source is already installed, and whether an
  update is available.
- `mediaType`: `manga`, `novel`, or `anime`. An `anime` source must give
  its episodes a way to be watched: a JS source defines `getVideoList`,
  and a JSON source declares `videos` (both covered in
  `docs/anime_extension.md`). It shows up under Browse > Anime, and its
  episodes open in the player instead of the reader.
- `engineKind`: `js` for a JS extension, or `json` for a JSON one (see
  `docs/json_extension.md`).
- `version`: a plain number that only ever goes up. Raise it whenever
  `fileUrl` changes. This is what makes the "Update" button show up for
  people who already installed it.
- `fileUrl`: the source's actual code. It is only fetched when someone
  installs or updates it, not while they are just browsing the repo's
  list.
- `iconUrl`, `baseUrl`: optional, but worth adding.
- `nsfw`: optional, defaults to `false`. This is just the repo's own
  claim. Sumizuri does not check it itself. It only affects the "Show
  NSFW" filter while browsing the repo. Nothing is blurred or blocked
  because of it.

Once a source from a repo is installed, it behaves exactly like one that
was added by hand. The repo is only a way to find and fetch it.

## An add button for your repo

A link such as `sumizuri://add-repo?url=https://example.com/index.json`
opens Sumizuri, asks the person to confirm, and adds the repo for them.
GitHub does not show links that use a custom scheme like this one, so
point your README at the redirect page in this project instead. It opens
the app the same way:

```markdown
[Add to Sumizuri](https://not-akari.github.io/sumizuri/add-repo.html?url=https://example.com/index.json)
```

If the repo's own address contains a `?` or `&`, encode it first with
`encodeURIComponent`. Only `http` and `https` addresses are accepted, and
the app always asks for confirmation before it adds anything.
