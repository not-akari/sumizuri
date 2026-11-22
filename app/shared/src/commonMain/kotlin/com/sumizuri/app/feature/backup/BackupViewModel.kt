package com.sumizuri.app.feature.backup

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.backup.BackupApp
import com.sumizuri.app.data.backup.BackupCompression
import com.sumizuri.app.data.backup.BackupPacking
import com.sumizuri.app.data.backup.BackupPart
import com.sumizuri.app.data.backup.BackupProblem
import com.sumizuri.app.data.backup.BackupRestorer
import com.sumizuri.app.data.backup.BackupSummary
import com.sumizuri.app.data.backup.BackupUnreadable
import com.sumizuri.app.data.backup.BackupWriter
import com.sumizuri.app.data.backup.ImportedBackup
import com.sumizuri.app.data.backup.SourceMatcher
import com.sumizuri.app.data.backup.backupFileName
import com.sumizuri.app.data.backup.packedNeedsPassword
import com.sumizuri.app.data.backup.readBackupFile
import com.sumizuri.app.data.backup.readBackupText
import com.sumizuri.app.data.backup.readMangayomiBackup
import com.sumizuri.app.data.backup.readMihonBackup
import com.sumizuri.app.data.backup.sniffBackup
import com.sumizuri.app.data.backup.unpackBackup
import com.sumizuri.app.data.backup.writePackedBackup
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.enumNamed
import com.sumizuri.app.data.work.BusyKind
import com.sumizuri.app.data.work.BusyWork
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okio.FileSystem
import okio.Path
import kotlin.concurrent.Volatile

// Where the choices for a backup are kept between visits.
private const val PartsKey = "backup.parts"
private const val CompressionKey = "backup.compression"

// Makes backups of this app, and reads a backup file of one of the three apps, asks what it needs to (a password, a yes), puts the titles in, and then looks for sources for the titles that have none.
class BackupViewModel(
    private val restorer: BackupRestorer,
    private val matcher: SourceMatcher,
    private val writer: BackupWriter,
    private val settings: SettingsRepository,
) : ViewModel() {
    private val mutable = MutableStateFlow<BackupState>(BackupState.Idle)
    val state: StateFlow<BackupState> = mutable

    private val making = MutableStateFlow<MakeState>(MakeState.Idle)
    val make: StateFlow<MakeState> = making

    private val mutableChoices = MutableStateFlow(MakeChoices())
    val choices: StateFlow<MakeChoices> = mutableChoices

    // What is waiting for the person: the packed file of a backup with a password, or a backup that is read.
    private var sealed: Path? = null
    private var ready: ImportedBackup? = null
    private var cancelled = false

    @Volatile
    private var stopMaking = false

    init {
        viewModelScope.launch {
            val parts = settings
                .textNow(PartsKey)
                ?.split(",")
                ?.mapNotNull { name -> enumNamed<BackupPart>(name) }
                ?.toSet()
            val compression = settings.textNow(CompressionKey)?.let { name -> enumNamed<BackupCompression>(name) }
            mutableChoices.update { MakeChoices(parts ?: it.parts, compression ?: it.compression) }
        }
    }

    // A file was chosen. Its first bytes say what kind of backup it is, and a file that is none of the kinds is said so.
    fun onPicked(file: Path) {
        mutable.value = BackupState.Reading
        viewModelScope.launch {
            try {
                val app =
                    withContext(Dispatchers.IO) { sniffBackup(file) } ?: throw BackupUnreadable(BackupProblem.NotBackup)
                when (app) {
                    BackupApp.Sumizuri -> when (withContext(Dispatchers.IO) { packedNeedsPassword(file) }) {
                        true -> {
                            sealed = file
                            mutable.value = BackupState.Password(wrong = false)
                        }

                        false -> offer(withContext(Dispatchers.IO) { unpacked(file, null) })

                        null -> offer(withContext(Dispatchers.IO) { readBackupFile(readBackupText(file)) })
                    }

                    BackupApp.Mihon -> run(withContext(Dispatchers.IO) { readMihonBackup(file) }, withSettings = false)

                    BackupApp.Mangayomi -> run(
                        withContext(Dispatchers.IO) { readMangayomiBackup(file) },
                        withSettings = false,
                    )
                }
            } catch (error: CancellationException) {
                throw error
            } catch (error: BackupUnreadable) {
                AppLog.warn(
                    "backup",
                    "could not read the file, ${error.problem.name} ${error.cause?.message.orEmpty()}",
                )
                mutable.value = BackupState.Failed(error.problem)
            }
        }
    }

    fun onPassword(password: String) {
        val file = sealed ?: return
        mutable.value = BackupState.Reading
        viewModelScope.launch {
            try {
                val backup = withContext(Dispatchers.IO) { unpacked(file, password) }
                sealed = null
                offer(backup)
            } catch (error: CancellationException) {
                throw error
            } catch (error: BackupUnreadable) {
                mutable.value =
                    if (error.problem ==
                        BackupProblem.WrongPassword
                    ) {
                        BackupState.Password(wrong = true)
                    } else {
                        BackupState.Failed(error.problem)
                    }
            }
        }
    }

    // Opens a packed backup into a plain file next to the temporary files, reads it and lets the plain file go.
    private suspend fun unpacked(file: Path, password: String?): ImportedBackup {
        val plain = FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-restore.json"
        try {
            unpackBackup(file, plain, password)
            return readBackupFile(readBackupText(plain))
        } finally {
            runCatching { FileSystem.SYSTEM.delete(plain) }
        }
    }

    fun onConfirm(withSettings: Boolean) {
        ready?.let { run(it, withSettings) }
    }

    fun onCancel() {
        cancelled = true
        mutable.update { if (it is BackupState.Running) it.copy(cancelling = true) else it }
    }

    // Closes a window, or gives up on a file that waits.
    fun onDismiss() {
        sealed = null
        ready = null
        mutable.value = BackupState.Idle
    }

    private fun offer(backup: ImportedBackup) {
        ready = backup
        mutable.value =
            BackupState.Confirm(backup.app, backup.titles.size, backup.shelves.size, backup.extras?.settings?.size ?: 0)
    }

    private fun run(backup: ImportedBackup, withSettings: Boolean) {
        ready = null
        cancelled = false
        mutable.value = BackupState.Running(matching = false, done = 0, total = backup.titles.size, cancelling = false)
        viewModelScope.launch {
            // The restore goes on while the app is out of sight, with a notice that shows how far it got and can cancel it.
            BusyWork.keep(
                BusyKind.Restore,
                { (mutable.value as? BackupState.Running)?.let { it.done to it.total } },
                ::onCancel,
            ) {
                val result = restorer.restore(backup, { done, total ->
                    mutable.update { current ->
                        (current as? BackupState.Running)?.copy(done = done, total = total)
                            ?: current
                    }
                }, { cancelled }, withSettings)
                // Titles whose own source is installed here are linked to it. The rest wait for the page that moves titles, which the end of the restore offers.
                var matched: Int? = null
                if (result.candidates.isNotEmpty() && !cancelled) {
                    mutable.value =
                        BackupState.Running(
                            matching = true,
                            done = 0,
                            total = result.candidates.size,
                            cancelling = false,
                        )
                    matched =
                        matcher.match(result.candidates, { done, total ->
                            mutable.update { current ->
                                (current as? BackupState.Running)?.copy(done = done, total = total)
                                    ?: current
                            }
                        }, { cancelled })
                }
                mutable.value = BackupState.Done(result, matched, matcher.waiting(result.candidates))
            }
        }
    }

    // Writes a backup with these choices into a temporary file, which the page then offers to save where the person wants.
    fun onMake(choices: MakeChoices, password: String?) {
        if (making.value is MakeState.Writing) return
        mutableChoices.value = choices
        making.value = MakeState.Writing(0, 0)
        stopMaking = false
        viewModelScope.launch {
            settings.setText(PartsKey, choices.parts.joinToString(",") { it.name })
            settings.setText(CompressionKey, choices.compression.name)
            val file = FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-backup.tmp"
            try {
                var summary: BackupSummary? = null
                BusyWork.keep(
                    BusyKind.Backup,
                    { (making.value as? MakeState.Writing)?.let { it.done to it.total } },
                    ::onStopMaking,
                ) {
                    withContext(Dispatchers.IO) {
                        writePackedBackup(file, BackupPacking(choices.compression, password)) { sink ->
                            summary =
                                writer.write(sink, choices.parts, { done, total ->
                                    making.value =
                                        MakeState.Writing(done, total)
                                }, { stopMaking })
                        }
                    }
                }
                making.value = MakeState.Ready(file, backupFileName(), summary!!)
                AppLog.info(
                    "backup",
                    "made a backup, $summary, ${choices.compression.name}, ${if (password.isNullOrEmpty()) "no password" else "with a password"}",
                )
            } catch (error: CancellationException) {
                // The person stopped it, so the part made so far goes and the page is as before.
                if (!stopMaking) throw error
                runCatching { FileSystem.SYSTEM.delete(file) }
                making.value = MakeState.Idle
            } catch (error: Exception) {
                AppLog.error("backup", "could not make the backup", error)
                runCatching { FileSystem.SYSTEM.delete(file) }
                making.value = MakeState.Failed
            }
        }
    }

    // Stops the backup being made, from its window or its notice.
    fun onStopMaking() {
        stopMaking = true
    }

    // The person picked where the backup goes, or gave up. The temporary file goes either way.
    fun onSaved(saved: Boolean) {
        val ready = making.value as? MakeState.Ready ?: return
        runCatching { FileSystem.SYSTEM.delete(ready.file) }
        making.value = if (saved) MakeState.Saved(ready.summary) else MakeState.NotSaved
    }

    fun onMakeDismiss() {
        (making.value as? MakeState.Ready)?.let { runCatching { FileSystem.SYSTEM.delete(it.file) } }
        making.value = MakeState.Idle
    }

    override fun onCleared() {
        (making.value as? MakeState.Ready)?.let { runCatching { FileSystem.SYSTEM.delete(it.file) } }
    }
}
