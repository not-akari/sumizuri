<p align="center">
  <picture>
    <source media="(prefers-color-scheme: dark)" srcset=".github/readme/banner-dark.svg">
    <source media="(prefers-color-scheme: light)" srcset=".github/readme/banner-light.svg">
    <img alt="Sumizuri, a media viewer for manga, comics, novels and anime" src=".github/readme/banner-dark.svg" width="100%">
  </picture>
</p>

<p align="center">
  <a href="https://sumizuri.notakari.com"><b>Website</b></a> &nbsp;·&nbsp;
  <a href="https://github.com/not-akari/sumizuri/releases/latest"><b>Download</b></a> &nbsp;·&nbsp;
  <a href="docs/extensions.md"><b>Guides</b></a> &nbsp;·&nbsp;
  <a href="https://discord.gg/JZaqv5VFj7"><b>Discord</b></a>
</p>

---

Sumizuri is one app for the things you read and watch. Open files from your device, or connect it to sources you choose. It keeps your library, progress and settings, and can sync them between devices through a server you host yourself.

> [!NOTE]
> Sumizuri comes with no content and lists no sources by default. You choose what to add, and you are responsible for it.

<p align="center">
  <img src=".github/readme/screenshot-profile.jpg" alt="The profile page" width="32%">
  &nbsp;
  <img src=".github/readme/screenshot-settings.jpg" alt="The settings page" width="32%">
</p>

## Features

- **Manga and comics:** pages right to left, left to right or downwards, or a long scroll, with tap zones and keys you can change.
- **Novels:** text set the way you read best, with word lookup.
- **Anime:** a player with subtitles and audio tracks.
- **Your own files:** folders of pictures, ZIP and CBZ, and EPUB.
- **Library:** shelves, a feed of new chapters, downloads, and backups you can lock with a password.
- **Sync:** keep devices the same through your own [sync server](docs/sync-server.md).

## Download

Android 7.0 and newer, Windows, and Linux. Get the newest version from the [download page](https://sumizuri.notakari.com/download) or the [releases](https://github.com/not-akari/sumizuri/releases/latest). If you are not sure which Android file to take, take **Universal**.

## Guides

- [Writing extensions](docs/extensions.md): connect Sumizuri to an API.
- [Profile block scripts](docs/profile-blocks.md): make your own profile blocks.
- [Run a sync server](docs/sync-server.md): host your own, with Docker.

## Build

You need JDK 21, and the Android SDK for the Android app.

```bash
./gradlew :app:desktop:runReleaseDistributable   # run the desktop app
./gradlew :app:android:assembleDebug             # build an Android debug APK
./gradlew :sync:server:installDist               # build the sync server
```

Before a pull request, run `bash scripts/check-repo.sh`.

## Content

Sumizuri is an app, not a content service. It does not host, sell or hand out any content, and it runs no servers that hold content. Sources and repos are made by other people and are not checked or stood behind by this project. See the [terms](docs/terms.md) and the [privacy page](docs/privacy.md).
