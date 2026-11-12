package com.sumizuri.app.data.settings

// The names the choices of the settings pages are kept under.
object SettingKey {
    const val CompactLists = "layout.compactLists"
    const val ReduceMotion = "layout.reduceMotion"

    // Kept apart from the other groups, so resetting the look does not turn it off.
    const val PerfOverlay = "debug.perfOverlay"
    const val PerfOverlayLevel = "debug.perfOverlayLevel"
    const val PerfOverlayAt = "debug.perfOverlayAt"

    // Whether a site opens in a page of the app or in the person's own browser.
    const val WebInApp = "web.inApp"
    const val Oled = "app.oled"
    const val OledGlow = "app.oledGlow"
    const val NavStyle = "layout.navStyle"
    const val NavLabels = "layout.navLabels"
    const val NavSwipe = "layout.navSwipe"

    // Whether the app opens on the page it was left on. Off, it opens on the library every time.
    const val ReopenPlace = "layout.reopenPlace"

    // Whether a wide window shows the title page with the cover standing on the left, or with the banner across the top.
    const val TitleSplit = "layout.titleSplit"

    // Whether the person has gone through, or skipped, the first steps after installing.
    const val OnboardingDone = "onboarding.done"

    // How one page gives way to another, and whether the parts of a page rise in one after the other.
    const val PageMotion = "layout.pageMotion"
    const val Stagger = "layout.stagger"
    const val Language = "app.language"

    // The pages new in this version that the person has opened, so the home stops marking them.
    const val SettingsSeen = "settings.seen"

    // How the entries of a source are laid out, the same for every source.
    const val BrowseStyle = "browse.style"

    // Whether saving chapters to the device is paused, kept for the next time the app opens.
    const val DownloadsPaused = "downloads.paused"

    // How many days go between the backups the app makes by itself, 0 for none, how many of them it keeps, and when it made the last one.
    const val AutoBackupDays = "backup.autoDays"
    const val AutoBackupKeep = "backup.autoKeep"
    const val AutoBackupLast = "backup.autoLast"

    // The choices of saving chapters, all under one prefix so they are read together.
    const val DownloadPrefix = "downloads."
    const val DownloadWifiOnly = "downloads.wifiOnly"
    const val DownloadPagesAtOnce = "downloads.pagesAtOnce"
    const val DownloadNew = "downloads.new"
    const val DownloadNewStarted = "downloads.new.startedOnly"
    const val DownloadNewLimit = "downloads.new.limit"
    const val DownloadSkipShelves = "downloads.new.skipShelves"
    const val DownloadAhead = "downloads.ahead"
    const val DownloadAheadSaved = "downloads.ahead.savedOnly"
    const val DownloadDeleteAfter = "downloads.delete.after"
    const val DownloadKeepBookmarked = "downloads.delete.keepBookmarked"
    const val DownloadDeleteOnMark = "downloads.delete.onMark"

    // The lock of the app, all under one prefix so they are read together: whether it is on, after how many seconds away it locks again, the PIN where the system has no lock of its own, and when the screen is hidden from screenshots.
    const val SecurityPrefix = "security."
    const val LockOn = "security.lock"
    const val LockAfter = "security.lockAfter"
    const val LockPin = "security.pin"
    const val SecureScreen = "security.secureScreen"

    // Whether the reader passes over read chapters, and the chapters the filters of the chapter list hide, on its way to the next or the one before.
    const val ReaderSkipRead = "reader.skipRead"
    const val ReaderSkipFiltered = "reader.skipFiltered"

    // Hours between two checks of the library for new chapters, 0 for only when asked.
    const val UpdateHours = "library.update.hours"
    const val DefaultUpdateHours = 1
    const val UpdateSkipCompleted = "library.update.skipCompleted"
    const val UpdateSkipNotStarted = "library.update.skipNotStarted"
    const val UpdateSkipUnread = "library.update.skipUnread"
    const val UpdateSmart = "library.update.smart"
    const val UpdateInBackground = "library.update.background"
    const val UpdateWifiOnly = "library.update.wifiOnly"
    const val UpdateCharging = "library.update.charging"
    const val UpdateNotify = "library.update.notify"
    const val NoticeAsked = "library.update.noticeAsked"

    // The most the image cache may keep on disk in megabytes, and the share of memory it may take in percent.
    const val ImageDiskMb = "cache.imageDiskMb"
    const val ImageMemoryPercent = "cache.imageMemoryPercent"

    // The most memory the pages of the reader may take in megabytes, and how long a page stays in minutes.
    const val PageMemoryMb = "cache.pageMemoryMb"
    const val PageKeepMinutes = "cache.pageKeepMinutes"

    // How many books a source pointed at are kept, so opening one again does not fetch it again.
    const val BooksKept = "cache.booksKept"

    // Whether the seasons of an anime get their covers from AniList, found by the names of the seasons.
    const val AniListSeasonCovers = "cache.aniListSeasonCovers"

    // Sync, for this profile and this device: the library it links to, what of it syncs, and how often. Settings files leave these out.
    const val SyncLibraryId = "sync.libraryId"

    // What syncs, reset together on its page.
    const val SyncProgress = "sync.what.progress"
    const val SyncShelves = "sync.what.shelves"
    const val SyncSources = "sync.what.sources"
    const val SyncSettings = "sync.what.settings"

    // When it syncs, reset together on its page.
    const val SyncEveryMinutes = "sync.when.everyMinutes"
    const val SyncWifiOnly = "sync.when.wifiOnly"
    const val SyncBackground = "sync.when.background"
    const val SyncOnOpen = "sync.when.onOpen"
    const val SyncAfterReading = "sync.when.afterReading"
    const val SyncCharging = "sync.when.charging"

    const val DefaultImageDiskMb = 256
    const val DefaultImageMemoryPercent = 15
    const val DefaultPageMemoryMb = 64
    const val DefaultPageKeepMinutes = 5
    const val DefaultBooksKept = 5
}
