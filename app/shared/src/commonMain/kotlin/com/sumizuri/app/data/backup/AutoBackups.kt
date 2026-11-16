package com.sumizuri.app.data.backup

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.share.ShareEnding
import com.sumizuri.app.data.text.localOffsetMillis
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.data.work.BusyKind
import com.sumizuri.app.data.work.BusyWork
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath
import kotlin.time.Instant

// The ending of a backup file of this app, which is the ending of every file of the app.
const val BackupEnding = ShareEnding

// A name that sorts by date, such as sumizuri_backup_2026-10-06_213005.sumizuri, in the time of this device, to the second so two backups never share one.
fun backupFileName(now: Long = nowMillis()): String {
    val local = Instant.fromEpochMilliseconds(now + localOffsetMillis(now)).toString()
    return "sumizuri_backup_${local.substring(
        0,
        10,
    )}_${local.substring(11, 13)}${local.substring(14, 16)}${local.substring(17, 19)}$BackupEnding"
}

// The folder of the backups of a profile: beside its database, named after it, or in the temporary folder when there is no database file.
fun backupFolder(databasePath: String): Path {
    if (databasePath.isBlank()) return FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-backups"
    val database = databasePath.toPath()
    val parent = database.parent ?: FileSystem.SYSTEM_TEMPORARY_DIRECTORY
    return parent / "backups" / database.name.substringBeforeLast('.')
}

// A backup kept in the folder of backups, as the page lists it.
data class SavedBackup(val path: Path, val name: String, val bytes: Long, val at: Long)

// Makes a backup by itself every few days, packed small, into the folder of backups beside the library, and keeps only the newest few. The person can also make one there at any time, and each one can be restored, saved somewhere else or deleted.
class AutoBackups(private val writer: BackupWriter, private val settings: SettingsRepository, val folder: Path) {
    private val lock = Mutex()
    private val mutableSaved = MutableStateFlow<List<SavedBackup>>(emptyList())
    val saved: StateFlow<List<SavedBackup>> = mutableSaved
    private val mutableMaking = MutableStateFlow<Pair<Int, Int>?>(null)

    // How far a backup being made is, as titles done and in all.
    val making: StateFlow<Pair<Int, Int>?> = mutableMaking
    private var stopped = false

    // Reads the folder again, newest first.
    suspend fun refresh() = withContext(Dispatchers.IO) {
        val files = runCatching {
            FileSystem.SYSTEM.list(folder)
        }.getOrDefault(emptyList()).filter { it.name.endsWith(BackupEnding) }
        mutableSaved.value = files
            .mapNotNull { path ->
                val meta = runCatching { FileSystem.SYSTEM.metadata(path) }.getOrNull() ?: return@mapNotNull null
                SavedBackup(path, path.name, meta.size ?: 0, meta.lastModifiedAtMillis ?: 0)
            }.sortedByDescending { it.name }
    }

    // Makes a backup when the days the person chose have gone by since the last one. Gives true when it made one.
    suspend fun runIfDue(): Boolean {
        val days = settings.textNow(SettingKey.AutoBackupDays)?.toIntOrNull() ?: 0
        if (days <= 0) return false
        val last = settings.textNow(SettingKey.AutoBackupLast)?.toLongOrNull() ?: 0
        // A backup an hour early still counts, so one made at a slightly different time each day does not slip a day.
        if (nowMillis() - last < days * DayMs - HourMs) return false
        return makeNow() != null
    }

    // Makes a backup now, with the sources, their settings and the app settings but never the sign ins of sites. Gives null when it was stopped or failed.
    suspend fun makeNow(): SavedBackup? = lock.withLock {
        withContext(Dispatchers.IO) {
            FileSystem.SYSTEM.createDirectories(folder)
            val final = folder / backupFileName()
            val part = folder / (final.name + ".part")
            stopped = false
            mutableMaking.value = 0 to 0
            try {
                BusyWork.keep(BusyKind.Backup, { mutableMaking.value }, ::stop) {
                    writePackedBackup(part, BackupPacking(BackupCompression.Small, null)) { sink ->
                        writer.write(
                            sink,
                            setOf(
                                BackupPart.Sources,
                                BackupPart.SourceSettings,
                                BackupPart.Settings,
                            ),
                            { done, total ->
                                mutableMaking.value =
                                    done to total
                            },
                            { stopped },
                        )
                    }
                }
                // Written under another name first, so a backup cut off halfway never looks like a whole one.
                FileSystem.SYSTEM.atomicMove(part, final)
                settings.setText(SettingKey.AutoBackupLast, nowMillis().toString())
                prune()
                refresh()
                AppLog.info("backup", "made a backup in the folder of backups, ${final.name}")
                mutableSaved.value.firstOrNull { it.path == final }
            } catch (error: CancellationException) {
                runCatching { FileSystem.SYSTEM.delete(part) }
                if (!stopped) throw error
                null
            } catch (error: Exception) {
                AppLog.error("backup", "the backup could not be made", error)
                runCatching { FileSystem.SYSTEM.delete(part) }
                null
            } finally {
                mutableMaking.value = null
            }
        }
    }

    // Stops the backup being made. Nothing of it is kept.
    fun stop() {
        stopped = true
    }

    suspend fun delete(backup: SavedBackup) = withContext(Dispatchers.IO) {
        runCatching { FileSystem.SYSTEM.delete(backup.path) }
        refresh()
    }

    // Deletes all but the newest backups, as many as the person chose to keep.
    private suspend fun prune() {
        val keep = (settings.textNow(SettingKey.AutoBackupKeep)?.toIntOrNull() ?: DefaultKeep).coerceAtLeast(1)
        refresh()
        mutableSaved.value.drop(keep).forEach { runCatching { FileSystem.SYSTEM.delete(it.path) } }
    }

    companion object {
        const val DefaultKeep = 5
        private const val HourMs = 60 * 60 * 1000L
        private const val DayMs = 24 * HourMs
    }
}
