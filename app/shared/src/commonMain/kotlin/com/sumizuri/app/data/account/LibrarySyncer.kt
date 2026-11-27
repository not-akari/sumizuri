package com.sumizuri.app.data.account

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.backup.AutoBackups
import com.sumizuri.app.data.backup.BackupExtras
import com.sumizuri.app.data.backup.BackupRestorer
import com.sumizuri.app.data.backup.BackupWriter
import com.sumizuri.app.data.backup.ImportedTitle
import com.sumizuri.app.data.backup.readSumizuriBackup
import com.sumizuri.app.data.download.canTellNetwork
import com.sumizuri.app.data.download.onUnmeteredNetwork
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.data.work.BusyHandle
import com.sumizuri.app.data.work.BusyKind
import com.sumizuri.app.data.work.BusyWork
import com.sumizuri.app.ui.tv.isTvDevice
import com.sumizuri.sync.core.ErrorCodes
import com.sumizuri.sync.core.LibraryKeys
import com.sumizuri.sync.core.Snapshot
import com.sumizuri.sync.core.SyncCrypto
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.Job
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path.Companion.toPath

// A copy that another device sent in between is merged again, this many times at most.
private const val MostTries = 3

// A sync keeps this many of its conflicts for the details page.
private const val ConflictsKept = 20

// A sync asked for after reading waits this long, so a few chapters in a row make one sync.
private const val AfterReadingMs = 30_000L

// A sync that runs longer than this keeps the app awake in the background.
private const val BusyAfterMs = 3_000L

// Keeps the library of this profile the same as its rows on the server. It fetches the rows that changed since the last sync, merges them with this device by what each side changed since they last agreed, writes the result here, and sends only the rows that differ, in batches. The state they agreed on, with the number of the last change fetched, is kept in a file beside the profile.
class LibrarySyncer(
    private val settings: SettingsRepository,
    private val writer: BackupWriter,
    private val restorer: BackupRestorer,
    private val applier: SyncApply,
    private val databasePath: String,
    private val scope: CoroutineScope,
    private val client: SyncClient = SyncClient(),
    private val backups: AutoBackups? = null,
) {
    // The title read further on another device in the last sync, for offering to go on reading it here.
    val handoff: MutableStateFlow<Long?> get() = applier.handoff

    // The account of the app, given once the profile is open, since one account serves every profile.
    var accounts: SyncAccountStore? = null

    private val lock = Mutex()
    private val mutable = MutableStateFlow<SyncRun>(SyncRun.Idle)
    val run: StateFlow<SyncRun> = mutable
    private val mutableProgress = MutableStateFlow<SyncProgress?>(null)

    // How far the sync that runs now is, for the sync page and the notice.
    val progress: StateFlow<SyncProgress?> = mutableProgress
    private var soon: Job? = null
    private val guard = BigChangeGuard(backups)

    // A sync that would take a lot from this device and waits for the person to choose.
    val waiting: StateFlow<BigChange?> = guard.waiting
    private val log = SyncHistory(settings)

    // Whether this profile is signed in and linked to a profile on the server.
    suspend fun ready(): Boolean =
        accounts?.account?.value != null && settings.textNow(SettingKey.SyncLibraryId)?.toLongOrNull() != null

    // A sync the app starts by itself, which keeps to Wi-Fi when the person asked for that and says nothing when there is nothing to sync.
    suspend fun syncAuto(why: SyncWhy) {
        // A big change waits for the person, so the app does not ask the server again and again by itself.
        if (!ready() || guard.waiting.value != null) return
        if (settings.flag(SettingKey.SyncWifiOnly, false).first() && canTellNetwork && !onUnmeteredNetwork()) {
            AppLog.debug("sync", "skipped a sync (${why.name}), not on Wi-Fi")
            return
        }
        try {
            sync(why)
            SyncNotices.worked(settings)
        } catch (error: CancellationException) {
            throw error
        } catch (problem: SyncProblem) {
            SyncNotices.failed(settings, problem)
        }
    }

    // Asks the server only for the newest number of the profile's rows, which is a few bytes, and syncs when it moved past the one this device fetched last.
    suspend fun checkForChanges() {
        if (!ready() || run.value == SyncRun.Running) return
        val account = accounts?.account?.value ?: return
        val libraryId = settings.textNow(SettingKey.SyncLibraryId)?.toLongOrNull() ?: return
        val head = try {
            client.libraries(account).firstOrNull { it.id == libraryId }?.rowHead ?: return
        } catch (_: SyncProblem) {
            return
        }
        val seen = readRowBase(rowBasePath(account.userId, libraryId))?.head
        if (head != seen) {
            AppLog.info("sync", "the server moved from change $seen to $head, syncing")
            syncAuto(SyncWhy.OtherDevice)
        }
    }

    // Asks for a sync a little later, so reading several chapters in a row makes one.
    fun syncSoon() {
        soon?.cancel()
        soon = scope.launch {
            delay(AfterReadingMs)
            if (settings.flag(SettingKey.SyncAfterReading, true).first()) syncAuto(SyncWhy.AfterReading)
        }
    }

    // One sync. Only one runs at a time, and one asked for while another runs waits for it.
    suspend fun sync(why: SyncWhy = SyncWhy.Asked, choice: BigChoice? = null): SyncRun.Done = lock.withLock {
        mutable.value = SyncRun.Running
        val started = nowMillis()
        AppLog.info("sync", "sync started (${why.name})")
        val running = currentCoroutineContext()[Job]
        // Most syncs end in a moment. One that goes on, such as the first one of a big library, keeps the app awake with a notice.
        var busy: BusyHandle? = null
        val waiting = scope.launch {
            delay(BusyAfterMs)
            busy =
                BusyWork.begin(
                    BusyKind.Sync,
                    { mutableProgress.value?.let { it.done to it.total } },
                    { running?.cancel() },
                )
        }
        try {
            val done = withContext(Dispatchers.IO) { once(choice) }
            mutable.value = done
            settings.setText(LastAtKey, done.at.toString())
            val took = nowMillis() - started
            AppLog.info(
                "sync",
                "sync done in $took ms, ${done.here.titleCount} titles changed here, ${done.there.titleCount} sent",
            )
            log.record(
                SyncLogEntry(
                    done.at,
                    ok = true,
                    changedHere = done.changedHere,
                    sent = done.sent,
                    bytes = done.bytes,
                    conflicts = done.conflicts.take(ConflictsKept),
                    why = why,
                    tookMs = took,
                    fetchedRows = done.fetchedRows,
                    fetchedBytes = done.fetchedBytes,
                    sentRows = done.sentRows,
                    here = done.here,
                    there = done.there,
                ),
            )
            done
        } catch (error: CancellationException) {
            mutable.value = SyncRun.Idle
            throw error
        } catch (problem: SyncProblem) {
            AppLog.warn(
                "sync",
                "sync (${why.name}) failed after ${nowMillis() - started} ms, ${problem.code}: ${problem.message}",
            )
            mutable.value = SyncRun.Failed(problem)
            // Every failure is kept, and the same one again is counted on the last, so a server that is down for a day is one line.
            log.record(
                SyncLogEntry(
                    nowMillis(),
                    ok = false,
                    message = problem.message.orEmpty(),
                    why = why,
                    tookMs = nowMillis() - started,
                    code = problem.code,
                ),
            )
            throw problem
        } finally {
            waiting.cancel()
            busy?.end()
            mutableProgress.value = null
        }
    }

    // One round: fetch the rows that changed since the last sync, merge them with this device, write the result here, and send the rows that differ from the server. A batch another device beat is merged again.
    private suspend fun once(choice: BigChoice?): SyncRun.Done {
        val account =
            accounts?.account?.value ?: throw SyncProblem(ErrorCodes.SignedOut, "This device is not signed in.")
        val libraryId =
            settings.textNow(SettingKey.SyncLibraryId)?.toLongOrNull()
                ?: throw SyncProblem(NoLibrary, "Pick a profile on the server first.")
        val accountKey = SyncCrypto.fromBase64(account.accountKey)
        val entry =
            client.libraries(account).firstOrNull { it.id == libraryId }
                ?: throw SyncProblem(NoLibrary, "The profile on the server is gone.")
        val library =
            LibraryKeys.open(entry, accountKey)
                ?: throw SyncProblem(KeyMismatch, "This profile on the server could not be opened.")
        val withSources = settings.flag(SettingKey.SyncSources, true).first()
        val withSettings = settings.flag(SettingKey.SyncSettings, true).first()
        val parts =
            SyncParts(
                settings.flag(SettingKey.SyncProgress, true).first(),
                settings.flag(SettingKey.SyncShelves, true).first(),
                withSettings,
                withSources,
                // A TV has no lists, so it never takes them.
                settings.flag(SettingKey.SyncLists, true).first() && !isTvDevice(),
            )
        val rowsPath = rowBasePath(account.userId, libraryId)
        val exchange = RowExchange(client, account, libraryId, library.libraryKey) { mutableProgress.value = it }
        repeat(MostTries) {
            val fetchedBefore = client.rowBytesFetched
            var saved = readRowBase(rowsPath)
            val pullStarted = nowMillis()
            var pulled = exchange.pull(saved?.head ?: 0)
            // The server holds fewer changes than this device saw, such as after it was set up again, so this device joins it again from the start.
            if (saved != null && pulled.serverHead < saved.head) {
                AppLog.warn(
                    "sync",
                    "the server is at change ${pulled.serverHead}, behind the ${saved.head} this device saw, joining it again from the start",
                )
                saved = null
                pulled = exchange.pull(0)
            }
            val fetchedBytes = client.rowBytesFetched - fetchedBefore
            AppLog.info(
                "sync",
                "fetched ${pulled.rows.size} rows, ${fetchedBytes / 1024} KB, in ${nowMillis() - pullStarted} ms, server at change ${pulled.serverHead}",
            )
            // Before the first sync in rows, a copy from the older way of syncing stands for the server, together with what this device agreed on with it.
            val legacy = if (saved == null && pulled.rows.isEmpty()) {
                client.fetchCopy(account, libraryId)?.let { copy ->
                    Snapshot.unpack(copy.bytes, library.libraryKey)?.decodeToString()?.let(::readSumizuriBackup)
                        ?: throw SyncProblem(KeyMismatch, "The copy on the server could not be opened.")
                }
            } else {
                null
            }
            // With nothing agreed on yet, both sides are joined and nothing is taken as removed.
            val base =
                saved?.state
                    ?: if (legacy !=
                        null
                    ) {
                        readOldBase("$databasePath.sync-${account.userId}-$libraryId.json".toPath())
                    } else {
                        SyncState()
                    }
            val rowsServer = SyncRowCodec.overlay(saved?.state ?: SyncState(), pulled.rows.values)
            val server = legacy?.let(::stateOf) ?: rowsServer
            val insertFrom = legacy ?: SyncRowCodec.backupOf(pulled.rows.values)
            val serverExtras = pulled.rows[RowKind.Extras]?.extras ?: saved?.extras
            val localBackup = readSumizuriBackup(packLibrary(writer, withSources, withSettings))
            val localState = stateOf(localBackup)
            val names = (insertFrom?.titles.orEmpty() + localBackup.titles).filter { it.sourceId != null }.associate {
                syncKey(it.sourceId!!, it.url) to
                    it.name
            } + (server.lists + localState.lists).mapValues { it.value.name }
            val conflicts = ArrayList<SyncConflict>()
            var merged = SyncMerge.merge(localState, server, base, parts) { key, kind ->
                conflicts +=
                    SyncConflict(names[key] ?: key, kind)
            }
            merged = guard.check(localState, merged, names, choice)
            val here = changesBetween(localState, merged, names)
            AppLog.info(
                "sync",
                "merged, ${here.titleCount} titles, ${here.settings} settings and ${here.sources} sources change here, ${conflicts.size} conflicts",
            )
            for (title in here.titles) AppLog.debug("sync", "here: ${describe(title)}")
            val changed = applier.apply(merged, localState, insertFrom)
            // Sources and repos this device lacks are added. The settings came with the merge.
            if (withSources) {
                insertFrom?.extras?.let {
                    restorer.restoreExtras(BackupExtras(repos = it.repos, values = it.values), withSettings = false)
                }
            }
            val afterText = packLibrary(writer, withSources, withSettings)
            val after = stateOf(readSumizuriBackup(afterText))
            val send = SyncRowCodec.changed(after, rowsServer, parts, SyncRowCodec.entriesOf(afterText), serverExtras)
            if (send.isEmpty()) {
                writeRowBase(rowsPath, RowBase(after.only(parts), pulled.head, serverExtras))
                AppLog.info("sync", "nothing to send")
                return SyncRun.Done(
                    nowMillis(),
                    changed,
                    sent = false,
                    conflicts = conflicts,
                    fetchedRows = pulled.rows.size,
                    fetchedBytes = fetchedBytes,
                    here = here,
                )
            }
            val there = changesBetween(rowsServer.only(parts), after.only(parts), names)
            for (title in there.titles) AppLog.debug("sync", "there: ${describe(title)}")
            try {
                val pushStarted = nowMillis()
                val (head, bytes) = exchange.push(send, pulled.head)
                writeRowBase(
                    rowsPath,
                    RowBase(
                        after.only(parts),
                        head,
                        send.lastOrNull { it.kind == RowKind.Extras }?.extras ?: serverExtras,
                    ),
                )
                AppLog.info(
                    "sync",
                    "sent ${send.size} rows, ${bytes / 1024} KB, in ${nowMillis() - pushStarted} ms, server now at change $head",
                )
                return SyncRun.Done(
                    nowMillis(),
                    changed,
                    sent = true,
                    bytes = bytes,
                    conflicts = conflicts,
                    fetchedRows = pulled.rows.size,
                    fetchedBytes = fetchedBytes,
                    sentRows = send.size,
                    here = here,
                    there = there,
                )
            } catch (problem: SyncProblem) {
                if (problem.code != ErrorCodes.Changed) throw problem
                AppLog.info("sync", "another device changed some of the same rows in between, merging again")
            }
        }
        throw SyncProblem(ErrorCodes.Changed, "Other devices kept changing the same rows. Try again in a moment.")
    }

    // The titles the server holds for this profile, with their chapters, for the pages that show the server's side. Every row is fetched, a page at a time.
    suspend fun serverTitles(): List<ImportedTitle>? {
        val account = accounts?.account?.value ?: return null
        val libraryId = settings.textNow(SettingKey.SyncLibraryId)?.toLongOrNull() ?: return null
        val entry = client.libraries(account).firstOrNull { it.id == libraryId } ?: return null
        val library =
            LibraryKeys.open(entry, SyncCrypto.fromBase64(account.accountKey))
                ?: throw SyncProblem(KeyMismatch, "This profile on the server could not be opened.")
        val rows = RowExchange(client, account, libraryId, library.libraryKey) {}.pull(0).rows.values
        if (rows.isNotEmpty()) return SyncRowCodec.backupOf(rows)?.titles.orEmpty()
        val copy = client.fetchCopy(account, libraryId) ?: return null
        return Snapshot
            .unpack(copy.bytes, library.libraryKey)
            ?.decodeToString()
            ?.let(::readSumizuriBackup)
            ?.titles
    }

    private fun rowBasePath(userId: Long, libraryId: Long) = "$databasePath.sync-rows-$userId-$libraryId.json".toPath()

    // The syncs of this profile, newest first, for the details page.
    val history: Flow<List<SyncLogEntry>> = log.entries

    // Forgets what this device and the server last agreed on, then syncs, which joins both sides again without removing anything.
    suspend fun startOver(): SyncRun.Done {
        val account = accounts?.account?.value
        val libraryId = settings.textNow(SettingKey.SyncLibraryId)?.toLongOrNull()
        if (account != null && libraryId != null) {
            FileSystem.SYSTEM.delete("$databasePath.sync-${account.userId}-$libraryId.json".toPath(), mustExist = false)
            FileSystem.SYSTEM.delete(rowBasePath(account.userId, libraryId), mustExist = false)
        }
        return sync(SyncWhy.FromScratch)
    }

    companion object {
        const val NoLibrary = "no_library"
        const val KeyMismatch = "key_mismatch"

        // When this profile last synced, as epoch milliseconds.
        const val LastAtKey = "sync.lastAt"

        // The syncs of this profile, as a list kept in the settings.
        const val HistoryKey = SyncHistory.Key
    }
}
