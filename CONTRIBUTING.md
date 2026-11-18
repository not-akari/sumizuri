# Contributing to Sumizuri

Thank you for wanting to help. This page says how to report a bug, translate the app, and send code.

## Ways to help

- **Report a bug.** Open an [issue](https://github.com/not-akari/sumizuri/issues). Say what you did, what you expected, and what happened. Add your app version, your device or system, and a screenshot if it helps. The logs in Settings, Diagnostics also help a lot.
- **Ask for a feature.** Open an issue and say what you want to do and why. A small idea is fine.
- **Translate the app.** Translations are done on [Weblate](https://weblate.notakari.com/projects/app/). You do not need git for this. Please do not change the translated `values-*` files by hand, since Weblate owns them.
- **Send code.** Read the rest of this page first.
- **Ask a question.** Join the [Discord](https://discord.gg/JZaqv5VFj7).

For a security problem, do not open an issue. Follow the [security policy](SECURITY.md).

## Before you start

For anything bigger than a small fix, open an issue or ask on Discord first. That way you know the change is wanted before you spend time on it.

## Content

Sumizuri is a viewer. It ships no content and no sources. Pull requests that add built in sources, links to sites that host content, or ways around paid access or copy protection are closed. Sources are made and shared by other people in their own repos. See [writing extensions](docs/extensions.md) to make one.

## Set up

You need JDK 21, and the Android SDK for the Android app. Android Studio brings both.

```bash
./gradlew :app:desktop:runReleaseDistributable   # run the desktop app
./gradlew :app:android:assembleDebug             # build an Android debug APK
./gradlew :sync:server:installDist               # build the sync server
```

The iPhone and iPad app needs a Mac with Xcode and XcodeGen. The [README](README.md#build) says how to build it.

Some parts of the app need a key from an outside service, such as the client id of AniList. Copy `.env.example` to `.env` and fill in your own keys. The `.env` file is never kept in git. Without a key the app still builds, and the part that needs it is turned off.

## Rules for code

- **Format.** Run `./gradlew spotlessApply` before you commit. The checks fail on code that is not formatted.
- **Repo checks.** Run `bash scripts/check-repo.sh`. It looks for three things:
  - stray files, such as build output, IDE files, logs or test folders
  - anything of a signing key
  - Kotlin files over 400 lines. Split a long file by what its parts do.
- **Comments.** Each comment is one line in plain words. Say why the code does something, not what each line does.
- **Text the app shows.** New text goes in English only, in `app/shared/src/commonMain/composeResources/values/strings.xml`. Never write text straight into the code. Weblate picks up the new strings for translators.
- **Style.** Write code that looks like the code around it. Keep to the shared parts of the interface, such as the cards, chips and setting rows, so every screen looks the same.
- **Options over fixed looks.** When a choice is a matter of taste, add a setting for it, and keep the old look as the default.

## Pull requests

1. Fork the repo and make a branch from `main`.
2. Keep one topic in each pull request.
3. Say what changed and why. For a change you can see, add a screenshot or a short video.
4. Open the pull request against `main`.

Two checks run on every pull request: **Repo rules** and **Build**. Both must pass before it can be merged. On your first pull requests, the checks wait until the maintainer lets them run, which is a safety rule of the repo.

## License

Sumizuri is under the [GNU General Public License v3.0](LICENSE). By sending a pull request, you agree that your work is shared under the same license.
