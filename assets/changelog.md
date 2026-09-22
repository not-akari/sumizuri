# Changelog

## Unreleased

### New
- Import your library from Mangayomi (Settings > Backup & Restore > Import from Mangayomi) or Mihon (Import from Mihon). Titles, categories where the format has them, chapters and reading history come in; nothing is matched to an installed source automatically, so each imported title needs Migrate afterward. A freshly imported title is also tried against an installed source right away in the background when its address or source name lines up with one, so most titles never need a manual Migrate at all.
- Create backup can now protect the file with a password (Settings > Backup & Restore); leave it blank for a plain file as before. Restoring a protected backup asks for the password. This only applies to a file you export, not the automatic rotating backups kept on-device.
- Mass migration got a "Select all" button, and a "Migrate now" action shows up right in the result message after importing from AniList, Mangayomi or Mihon.
- Android: long-press the app icon for shortcuts to Library, Updates and History.
- Repo browsing can filter by language, and a repo that flags a source NSFW hides it behind a "Show NSFW" toggle. Installed sources can also be filtered by language.
- A download queue (Settings > Downloads > Download queue). Downloads run one at a time, in order, and you can see each one's progress, pause and resume it, cancel it (which deletes what was downloaded), try a failed one again, or pause and cancel everything at once. A download that is paused or that fails keeps what it fetched and carries on from there. The queue is kept when the app is closed: what was still downloading starts again next time (on Wi-Fi only, if you keep downloads to Wi-Fi, otherwise it waits for you to resume it).
- Your AniList account is built in (Settings > Trackers > AniList). See your profile and stats, browse your anime and manga lists with search and status filters, and edit any entry (status, progress, score, dates) or remove it. The Queue tab shows what is waiting to be sent to AniList, with Send now. Import your AniList lists into the library, then move them to a source with the mass Migrate. Sync progress marks what AniList says you have read as read here, and sends anything you are further along in.
- On phones, the library is now checked for new chapters and episodes while the app is closed (Settings > Library > Auto update). The system decides exactly when, a big library is checked over several runs, and Wi-Fi only is respected. It can notify you of what it finds if you turn on notifications (Settings > Notifications; the system asks for permission), and it leaves downloading to the app.
- Episodes offered as an HLS stream (.m3u8) can now be downloaded: the pieces are fetched a few at a time, asked for again after a pause when the server says "too many requests", decrypted if needed, and joined into one file that plays offline. A ring on the download button shows how far it has got.
- Anime. Watch episodes in a built-in player with its own controls: quality, subtitles, audio tracks, speed, resume where you left off, and next episode. Download episodes to watch offline, and track them on AniList. Turn anime on under Settings > Library.
- Anime with several seasons show a poster for each season on their page. Open one to see only its episodes. A source opts in by giving each episode a season.
- Pinch to zoom in the vertical reader (two fingers, or a trackpad pinch); drag sideways while zoomed, scroll up and down as usual.
- A stronger extension engine: JS sources get `URL`, `URLSearchParams` and `TextEncoder`, a `fetch` that follows the standard (final address, headers, form and JSON bodies), AES and HMAC (`host.crypto`, including the CryptoJS password format), a p.a.c.k.e.r unpacker, and an HLS playlist reader. JSON sources can `decode` wrapped values and `expandPlaylists` into qualities.
- The Source Editor's test panel is now a debugger: every request a source made (with its response), what it printed, how each search did, and Findings that say what looks wrong (a 403 needing a header, a selector that matched nothing, a field empty in every item). One button copies the whole run as a report to paste for help. JSON sources are also checked as you type for misspelled options, wrong field types and missing pieces.
- JS sources can parse a page once and ask it many questions (`host.parse`), with XPath and `:contains()`. A single bad item no longer empties a whole list.
- Debug builds are a separate app from the release (own id, name and data folder), so running one never touches your installed copy.
- Extensions can read pages that build themselves with JavaScript: `host.render` (JS) and `"render"` (JSON) load the page in a hidden browser, wait for what you name, and can capture the stream addresses a player requests. Windows, Android, iOS and macOS.
- If a source changes the addresses it gives its episodes, the library now recognises the same episodes (by number and title) instead of listing each twice, and keeps what you had watched. Lists already doubled are cleaned up the next time the title is refreshed.
- Opening a title no longer erases its saved cover when the source's details page has none, and details now fill in from the listing.
- The player restarts itself where it left off when the connection drops, and says so plainly if it can't recover.
- The player has a small log at the top, off until you turn it on in Settings > Advanced > Show the video log (the episode, what the source answered, the video chosen, retries, the engine's warnings) that opens to the full list and copies in one tap.
- The player no longer stops for a damaged piece of the stream (a corrupt packet, an audio frame that will not decode); it carries on, and restarts from the same spot only if playback really stops.
- Sources can mark an episode's opening and ending, and the player offers "Skip intro" and "Skip ending" exactly then.
- Subtitle settings have their own page (Settings > Subtitles): always show subtitles, a preferred language, size, colour, style (plain, shadow, box), bold and position, with a live preview.
- Many more player settings (Settings > Player): start each episode at the last quality picked, the best or the lowest; prefer sub or dub; how far a double tap jumps; how long the controls stay; starting speed; swipe gestures on or off and the hold speed.
- Settings > Storage can now clear source sessions (the cookies sources keep, and the hidden browser's data). Your library and history are not touched.
- Extensions can offer videos: JS sources define getVideoList, JSON sources declare a videos section. The Source Editor has anime templates and a getVideoList test.
- Choose where Sumizuri keeps its data and where downloads go, on first run and later in Settings > Storage. Moving the data folder copies everything and asks for a restart.
- If a database upgrade fails, or saved data is too old to upgrade, the app now offers to save a copy to a file before it starts fresh, instead of failing.

### Improved
- The vertical reader reads each page's size from the start of its file so pages keep their height while loading, shows the page number while a page loads, and a page that failed to load can be retried by tapping anywhere on it.
- App bars slide away when you scroll down and come back when you scroll up, on every page except a title's page.
- Page margins and spacing follow the width of the screen, so a small phone gets slimmer margins and a tablet gets roomier ones.
- The reader settings page scrolls as one list. Before, the switches and tabs stayed fixed and only a small area below them scrolled.
- Text that was written straight into screens (translation editor, statistics, app language, cloud challenge page and others) now comes from the translation files, so it can be translated. The three-dot menus share one implementation.
- The Wi-Fi only switch for library updates and the rules for what an update skips moved from Settings > Downloads to Settings > Library > Auto update, so Downloads has one Wi-Fi only switch.
- Reader settings can belong to one series. With This series on in the reader settings, every reader setting you change (scale, background, page gap, invert taps, column width, image quality, and the novel font, size and spacing) is kept for that series only; other series keep the app-wide settings, and turning it off returns the series to them. Settings > Reader now says these are the defaults. Synced with your library.
- Downloads can be set per series too: in a title's menu, Download settings for this series sets the auto-download limit, download-ahead and keep-behind for that series, and what you leave alone follows Settings > Downloads.
- The animated background is gone. The soft colour washes behind the screens are still there, now still, so the app uses less battery and there is nothing left to look blocky on a phone. Its strength is under Settings > Appearance > Background.
- A new app icon on every platform, and a plain white icon for Android notifications.
- Every theme, including Sumizuri Ink, now uses the normal system font by default (it no longer downloads Work Sans and Shippori Mincho). Only OpenDyslexic ships with the app; PT Serif and Atkinson Hyperlegible are gone, and a saved theme or novel font that used them uses the default. Other fonts are still in the theme editor.
- Desktop pop-up notifications stay away while you are in the app, and any that appeared while you were away are cleared when you come back. Turn it off in Settings > Notifications.
- Backups and exports on phones open the system Save dialog, so you choose the file and folder.

### Fixed
- A fresh start could stay on the loading screen for good. The app checks the database version while the database is being created, and when the two met the file was locked and the check never finished. It now carries on if the version cannot be read. If starting still takes over 15 seconds, or fails, a page says which step it is on and lets you copy the details or try again.
- A data folder that already holds data from an older version, chosen on first run, is now checked and backed up before it is opened, like on a normal start.
- On phones with a 90 or 120 Hz screen the reader could run at 60 Hz, because the system slows a window that keeps the screen on. The app now asks for the fastest refresh rate the screen has. It can be turned off in Settings > Advanced (Fastest screen refresh rate).
- Scrolling is smoother on 60 Hz screens. Touch input is now timed to each frame, so a drag no longer moves in uneven steps when the screen updates 60 times a second.
- With the floating tab bar, the last rows of the Profile, Settings, Browse and Library pages are no longer hidden behind it. Pages leave room for it and its safe-area gap.
- The Profile page bar leaves the screen when you scroll down and returns when you scroll up.
- In the vertical reader, loading the previous chapter no longer throws you to the top of it, and scrolling back up over pages you have already seen no longer jumps or stalls: pages remember their height while they reload and keep their decoded image.
- Leaving the reader for a title opened from the Updates row no longer raises "No Material widget found".
- Opening a source and leaving again quickly, while a message bar was showing, could raise a framework error. Message bars are now cleared when a page opens or closes.
- Leaving the source inspector, a source's search or the translation editor while it was still loading could raise a "defunct element" error.
- The library page no longer draws its title under the phone's status bar.
- Opening a title and leaving again very quickly no longer raises a "defunct element" error.
- Reopening a chapter in vertical reading mode now returns to the page you left. Before, the list drifted to an earlier page while unloaded pages above it loaded, and that wrong page was saved, so each reopen landed earlier than the last.
- Search and name dialogs (browse search, add repo, categories, branches, translations) no longer crash with "TextEditingController was used after being disposed" when they close.
- On phones the reader can hide the status and navigation bars (Settings > Reader).
- Manual and automatic backups no longer fail on some settings (theme mode, reader mode, library mode and others).

## 0.1.1

### New
- A redesigned look across the whole app, with a new navigation bar, list rows, settings pages and onboarding.
- A theme editor: colors, corner shapes, fonts, spacing, effects and motion. Themes import and export as .sumizuri-theme.json files.
- Light, Dark and OLED modes, with an OLED option per theme.
- Automatic backups with restore points, a restore preview, and a storage overview.
- Backups now include custom themes, reading history, category sort rules and more settings.
- Log viewer with filters, a diagnostic report you can export, and automatic detection of memory leaks and slow frames.
- A new open source licenses page and a "What's new" page.

### Improved
- Smoother tab switching and theme changes.
- The calendar and statistics no longer freeze the app while they load.
- The translation editor has a clearer layout.

### Fixed
- Several layout overlaps in app bars and detail pages.

## 0.0.2

- First tracked release.
