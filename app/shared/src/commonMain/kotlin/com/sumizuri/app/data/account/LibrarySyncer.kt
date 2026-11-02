package com.sumizuri.app.data.account

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.backup.BackupExtras
import com.sumizuri.app.data.backup.BackupPart
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
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.serialization.Serializable
import kotlinx.serialization.builtins.ListSerializer
import kotlinx.serialization.json.Json
import okio.Buffer
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

// One sync as the details page lists it: when, whether it worked, how many titles changed here, whether and how much it sent, or why it failed.
@Serializable
data class SyncLogEntry(
    val at: Long,
    val ok: Boolean,
    val changedHere: Int = 0,
    val sent: Boolean = false,
    val bytes: Long = 0,
    val message: String = "",
    val conflicts: List<SyncConflict> = emptyList(),
)

// How a sync of this profile went last, for the sync page.
sealed interface SyncRun {
    data object Idle : SyncRun
    data object Running : SyncRun
    data class Done(
        val at: Long,
        val changedHere: Int,
        val sent: Boolean,
        val bytes: Long = 0,
        val conflicts: List<SyncConflict> = emptyList(),
    ) : SyncRun
    data class Failed(val problem: SyncProblem) : SyncRun
}

// Keeps the library of this profile the same as its rows on the server. It fetches the rows that changed since the last sync, merges them with this device by what each side changed since they last agreed, writes the result here, and sends only the rows that differ, in batches. The state they agreed on, with the number of the last change fetched, is kept in a file beside the profile.
class LibrarySyncer(
    private val settings: SettingsRepository,
    private val writer: BackupWriter,
    private val restorer: BackupRestorer,
    private val applier: SyncApply,
    private val databasePath: String,
    private val scope: CoroutineScope,
    private val client: SyncClient = SyncClient(),
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
    private val json = Json { ignoreUnknownKeys = true }

    // Whether this profile is signed in and linked to a profile on the server.
    suspend fun ready(): Boolean =
        accounts?.account?.value != null && settings.textNow(SettingKey.SyncLibraryId)?.toLongOrNull() != null

    // A sync the app starts by itself, which keeps to Wi-Fi when the person asked for that and says nothing when there is nothing to sync.
    suspend fun syncAuto() {
        if (!ready()) return
        if (settings.flag(SettingKey.SyncWifiOnly, false).first() && canTellNetwork && !onUnmeteredNetwork()) return
        try {
            sync()
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
        if (head != readRowBase(rowBasePath(account.userId, libraryId))?.head) syncAuto()
    }

    // Asks for a sync a little later, so reading several chapters in a row makes one.
    fun syncSoon() {
        soon?.cancel()
        soon = scope.launch {
            delay(AfterReadingMs)
            if (settings.flag(SettingKey.SyncAfterReading, true).first()) syncAuto()
        }
    }

    // One sync. Only one runs at a time, and one asked for while another runs waits for it.
    suspend fun sync(): SyncRun.Done = lock.withLock {
        mutable.value = SyncRun.Running
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
            val done = withContext(Dispatchers.IO) { once() }
            mutable.value = done
            settings.setText(LastAtKey, done.at.toString())
            record(
                SyncLogEntry(
                    done.at,
                    ok = true,
                    changedHere = done.changedHere,
                    sent = done.sent,
                    bytes = done.bytes,
                    conflicts = done.conflicts.take(ConflictsKept),
                ),
            )
            done
        } catch (error: CancellationException) {
            mutable.value = SyncRun.Idle
            throw error
        } catch (problem: SyncProblem) {
            AppLog.warn("sync", "sync failed, ${problem.message}")
            mutable.value = SyncRun.Failed(problem)
            // A server that does not answer is shown on the page already, so it is not kept as a failed sync.
            if (problem.code !=
                SyncProblem.Unreachable
            ) {
                record(SyncLogEntry(nowMillis(), ok = false, message = problem.message.orEmpty()))
            }
            throw problem
        } finally {
            waiting.cancel()
            busy?.end()
            mutableProgress.value = null
        }
    }

    // One round: fetch the rows that changed since the last sync, merge them with this device, write the result here, and send the rows that differ from the server. A batch another device beat is merged again.
    private suspend fun once(): SyncRun.Done {
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
            )
        val rowsPath = rowBasePath(account.userId, libraryId)
        val exchange = RowExchange(client, account, libraryId, library.libraryKey) { mutableProgress.value = it }
        repeat(MostTries) {
            val fetchedBefore = client.rowBytesFetched
            var saved = readRowBase(rowsPath)
            var pulled = exchange.pull(saved?.head ?: 0)
            // The server holds fewer changes than this device saw, such as after it was set up again, so this device joins it again from the start.
            if (saved != null && pulled.serverHead < saved.head) {
                saved = null
                pulled = exchange.pull(0)
            }
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
                        readBase("$databasePath.sync-${account.userId}-$libraryId.json".toPath())
                    } else {
                        SyncState()
                    }
            val rowsServer = SyncRowCodec.overlay(saved?.state ?: SyncState(), pulled.rows.values)
            val server = legacy?.let(::stateOf) ?: rowsServer
            val insertFrom = legacy ?: SyncRowCodec.backupOf(pulled.rows.values)
            val serverExtras = pulled.rows[RowKind.Extras]?.extras ?: saved?.extras
            val localBackup = readSumizuriBackup(pack(withSources, withSettings))
            val localState = stateOf(localBackup)
            val names = (insertFrom?.titles.orEmpty() + localBackup.titles).filter { it.sourceId != null }.associate {
                syncKey(it.sourceId!!, it.url) to
                    it.name
            }
            val conflicts = ArrayList<SyncConflict>()
            val merged = SyncMerge.merge(localState, server, base, parts) { key, kind ->
                conflicts +=
                    SyncConflict(names[key] ?: key, kind)
            }
            val changed = applier.apply(merged, localState, insertFrom)
            // Sources and repos this device lacks are added. The settings came with the merge.
            if (withSources) {
                insertFrom?.extras?.let {
                    restorer.restoreExtras(BackupExtras(repos = it.repos, values = it.values), withSettings = false)
                }
            }
            val afterText = pack(withSources, withSettings)
            val after = stateOf(readSumizuriBackup(afterText))
            val send = SyncRowCodec.changed(after, rowsServer, parts, SyncRowCodec.entriesOf(afterText), serverExtras)
            if (send.isEmpty()) {
                writeRowBase(rowsPath, RowBase(after.only(parts), pulled.head, serverExtras))
                AppLog.info(
                    "sync",
                    "synced, ${pulled.rows.size} rows fetched, ${(client.rowBytesFetched - fetchedBefore) / 1024} KB, nothing to send, $changed titles changed here",
                )
                return SyncRun.Done(nowMillis(), changed, sent = false, conflicts = conflicts)
            }
            try {
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
                    "synced, ${pulled.rows.size} rows fetched, ${(client.rowBytesFetched - fetchedBefore) / 1024} KB, ${send.size} rows sent, ${bytes / 1024} KB, $changed titles changed here",
                )
                return SyncRun.Done(nowMillis(), changed, sent = true, bytes = bytes, conflicts = conflicts)
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
    val history: Flow<List<SyncLogEntry>> = settings.text(HistoryKey).map { text ->
        text
            ?.let {
                runCatching {
                    json.decodeFromString(
                        ListSerializer(SyncLogEntry.serializer()),
                        it,
                    )
                }.getOrNull()
            }.orEmpty()
    }

    // Forgets what this device and the server last agreed on, then syncs, which joins both sides again without removing anything.
    suspend fun startOver(): SyncRun.Done {
        val account = accounts?.account?.value
        val libraryId = settings.textNow(SettingKey.SyncLibraryId)?.toLongOrNull()
        if (account != null && libraryId != null) {
            FileSystem.SYSTEM.delete("$databasePath.sync-${account.userId}-$libraryId.json".toPath(), mustExist = false)
            FileSystem.SYSTEM.delete(rowBasePath(account.userId, libraryId), mustExist = false)
        }
        return sync()
    }

    private suspend fun record(entry: SyncLogEntry) {
        val now = settings
            .textNow(HistoryKey)
            ?.let {
                runCatching { json.decodeFromString(ListSerializer(SyncLogEntry.serializer()), it) }.getOrNull()
            }.orEmpty()
        settings.setText(
            HistoryKey,
            json.encodeToString(ListSerializer(SyncLogEntry.serializer()), (listOf(entry) + now).take(HistoryMost)),
        )
    }

    // This profile as a backup, with sources and settings when they sync. Sign ins never go.
    private suspend fun pack(withSources: Boolean, withSettings: Boolean): String {
        val parts = buildSet {
            if (withSources) addAll(listOf(BackupPart.Sources, BackupPart.SourceSettings))
            if (withSettings) add(BackupPart.Settings)
        }
        return Buffer().also { writer.write(it, parts, { _, _ -> }, { false }) }.readUtf8()
    }

    private fun readBase(path: okio.Path): SyncState = runCatching {
        if (!FileSystem.SYSTEM.exists(
                path,
            )
        ) {
            SyncState()
        } else {
            json.decodeFromString(
                SyncState.serializer(),
                FileSystem.SYSTEM.read(path) {
                    readUtf8()
                },
            )
        }
    }.getOrElse { SyncState() }

    companion object {
        const val NoLibrary = "no_library"
        const val KeyMismatch = "key_mismatch"

        // When this profile last synced, as epoch milliseconds.
        const val LastAtKey = "sync.lastAt"

        // The syncs of this profile, as a list kept in the settings, and how many of them are kept.
        const val HistoryKey = "sync.history"
        private const val HistoryMost = 30
    }
}
