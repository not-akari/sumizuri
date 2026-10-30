package com.sumizuri.app.data

import androidx.compose.runtime.staticCompositionLocalOf
import androidx.room3.RoomDatabase
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.account.LibrarySyncer
import com.sumizuri.app.data.account.SyncApply
import com.sumizuri.app.data.account.TitleFromServer
import com.sumizuri.app.data.appupdate.AppUpdater
import com.sumizuri.app.data.backup.AutoBackups
import com.sumizuri.app.data.backup.BackupRestorer
import com.sumizuri.app.data.backup.BackupWriter
import com.sumizuri.app.data.backup.SourceMatcher
import com.sumizuri.app.data.backup.backupFolder
import com.sumizuri.app.data.blocks.ProfileBlocksRepository
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.buildDatabase
import com.sumizuri.app.data.download.AutoDownloads
import com.sumizuri.app.data.download.DownloadFiles
import com.sumizuri.app.data.download.Downloader
import com.sumizuri.app.data.download.downloadFolder
import com.sumizuri.app.data.library.CategoryRepository
import com.sumizuri.app.data.library.ChapterCarry
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.library.SeasonCovers
import com.sumizuri.app.data.library.StatisticsRepository
import com.sumizuri.app.data.local.localFolder
import com.sumizuri.app.data.migration.MigrationPrefsRepository
import com.sumizuri.app.data.migration.MigrationSession
import com.sumizuri.app.data.migration.TitleMigration
import com.sumizuri.app.data.net.SiteKinds
import com.sumizuri.app.data.security.AppLock
import com.sumizuri.app.data.settings.CatalogRepository
import com.sumizuri.app.data.settings.ControlsRepository
import com.sumizuri.app.data.settings.CoverFocusRepository
import com.sumizuri.app.data.settings.FeedPrefsRepository
import com.sumizuri.app.data.settings.LibraryPrefsRepository
import com.sumizuri.app.data.settings.PlayerPrefsRepository
import com.sumizuri.app.data.settings.ReaderSettingsRepository
import com.sumizuri.app.data.settings.SessionRepository
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.settings.ThemeRepository
import com.sumizuri.app.data.sources.DatabaseHostStore
import com.sumizuri.app.data.sources.RepoRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.sources.SourceUpdates
import com.sumizuri.app.data.storage.DatabaseLogSink
import com.sumizuri.app.data.storage.StorageRepository
import com.sumizuri.app.data.sync.TitleSync
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.browser.ChallengeSolver
import com.sumizuri.app.source.browser.page.RenderPageFactory
import com.sumizuri.app.ui.kit.image.PageCache
import com.sumizuri.app.ui.kit.image.PageSnapshots
import com.sumizuri.app.ui.kit.image.SourceReferers
import com.sumizuri.app.ui.kit.image.snapshotFolder
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import okio.FileSystem

// How often the page cache is looked through for pages to let go.
private const val SweepEveryMillis = 60_000L

// Holds the database, the repositories and the source engine, built once by the entry point of each platform.
class AppContainer(
    builder: RoomDatabase.Builder<AppDatabase>,
    pages: RenderPageFactory,
    // Opens a site in a window a person can see, for a bot check the hidden browser could not pass.
    opener: ChallengeSolver = ChallengeSolver {},
    // Where the database file of this profile is, to show on the storage page.
    val databasePath: String = "",
) {
    val database: AppDatabase = buildDatabase(builder)

    // Where the lists that several screens watch are kept running once for all of them.
    private val shared = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    val library = LibraryRepository(database, shared)
    val settings = SettingsRepository(database, shared)

    // The covers of the seasons of anime from AniList, kept beside the cache of pictures.
    val seasonCovers = SeasonCovers(FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri_covers_meta")
    val session = SessionRepository(database)
    val reading = ReaderSettingsRepository(database)
    val catalogs = CatalogRepository(database)
    val sources = SourceRepository(database)
    val hostStore = DatabaseHostStore(database)
    val manager = SourceManager(pages, hostStore, hostStore, localFolder(databasePath))

    // A bot check a person passes in a window they can see. The hidden browser then starts its pages again, so they carry what was passed.
    val solver = ChallengeSolver { url ->
        opener.solve(url)
        manager.resetBrowser()
    }

    val repos = RepoRepository(database, manager.repos)
    val carry = ChapterCarry(database)
    private val work = CoroutineScope(SupervisorJob() + Dispatchers.IO)

    // Saved chapters are kept next to the database of the profile, in a folder of their own for each profile.
    val downloads =
        Downloader(database, library, sources, manager, settings, DownloadFiles(downloadFolder(databasePath)), work, PlayerPrefsRepository(database))
    val categories = CategoryRepository(database)
    val autoDownloads = AutoDownloads(library, categories, downloads, settings, work)
    val lock = AppLock(settings, shared)
    val updater = AppUpdater(settings, work)
    val sync = TitleSync(library, sources, manager, settings, carry, autoDownloads)
    val updates = SourceUpdates(sources, repos, manager.repos, settings)
    val focus = CoverFocusRepository(database)
    val migration = TitleMigration(database, library, reading, focus, carry)
    val migrationPrefs = MigrationPrefsRepository(settings)
    val playerPrefs = PlayerPrefsRepository(database)
    val migrations = MigrationSession(library, sources, manager, migration, migrationPrefs)
    val controls = ControlsRepository(database)
    val libraryPrefs = LibraryPrefsRepository(database)
    val statistics = StatisticsRepository(database, library)
    val blocks = ProfileBlocksRepository(settings)
    val storage = StorageRepository(database)
    val themes = ThemeRepository(database)
    val updatesPrefs = FeedPrefsRepository(database, "updates")
    val historyPrefs = FeedPrefsRepository(database, "history")
    val restorer = BackupRestorer(database, categories, sources, carry)
    val backupWriter = BackupWriter(database)
    val matcher = SourceMatcher(database, library, sources, manager, carry)

    // The backups the app makes by itself, in a folder beside the library.
    val autoBackups = AutoBackups(backupWriter, settings, backupFolder(databasePath))

    // Keeps this profile the same as its copy on the sync server, once the profile host gives it the account.
    val librarySync =
        LibrarySyncer(
            settings,
            backupWriter,
            restorer,
            SyncApply(database, categories, carry, restorer),
            databasePath,
            work,
        )

    // Puts a title the server has into the library of this device, from the pages of the sync.
    val titleFromServer = TitleFromServer(database, restorer, librarySync)

    init {
        // Reading asks for a sync a little later, which waits while the reading goes on.
        library.onReading = librarySync::syncSoon
    }

    private val sweeper = CoroutineScope(SupervisorJob() + Dispatchers.Main)
    private val logSink = DatabaseLogSink(database, work)

    init {
        // The log is kept in the database as well, so the lines of the last run can be read after a restart.
        AppLog.addSink(logSink)
        // Covers name the site of their source as the referrer, so the sites are kept up to date as sources come and go.
        shared.launch {
            sources.installed.collect { list ->
                SourceReferers.bySource =
                    list.filter { it.baseUrl.isNotBlank() }.associate { it.id to it.baseUrl.trimEnd('/') + "/" }
                SiteKinds.bySource = list.associate { it.id to it.kind }
            }
        }
        // The pictures of the pages last read sit beside the database of this profile.
        PageSnapshots.useFolder(snapshotFolder(databasePath))
        // Chapters that wait to be saved go on from where they were.
        downloads.start()
        // Pages of the reader that were not shown for five minutes are let go, on the main thread that uses them.
        sweeper.launch {
            while (true) {
                delay(SweepEveryMillis)
                PageCache.sweep(nowMillis())
            }
        }
    }

    // Lets go of the database and the sources, for when the profile this container was made for is left.
    suspend fun close() {
        AppLog.removeSink(logSink)
        sweeper.cancel()
        shared.cancel()
        work.cancel()
        manager.shutdown()
        database.close()
    }
}

val LocalAppContainer = staticCompositionLocalOf<AppContainer> {
    error("No AppContainer was provided")
}
