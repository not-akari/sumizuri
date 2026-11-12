package com.sumizuri.app.core.log

import com.sumizuri.app.BuildInfo
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import okio.FileSystem
import okio.Path
import kotlin.time.Instant

// How many of the last lines of the log go into a report.
private const val ReportLines = 200

// The report written as the app stops, and the one kept after the next start until it is dismissed.
private const val FreshName = "crash.txt"
private const val KeptName = "crash-last.txt"

// The line of a report that names the error, which the log shows on the next start.
private const val ErrorLine = "Error: "

// Keeps what made the app stop. The report is written at once while the app stops, since nothing that waits would still run. On the next start it goes into the log, and the Logs page shows it until it is dismissed.
object CrashReport {
    private var folder: Path? = null

    private val mutableLast = MutableStateFlow<String?>(null)
    val last: StateFlow<String?> = mutableLast

    // Called once by each platform as it starts, with the folder of the app.
    fun install(folder: Path) {
        if (this.folder != null) return
        this.folder = folder
        val fs = FileSystem.SYSTEM
        runCatching {
            val fresh = folder / FreshName
            val kept = folder / KeptName
            if (fs.exists(fresh)) {
                fs.atomicMove(fresh, kept)
                val error = fs.read(kept) { readUtf8() }.lineSequence().firstOrNull { it.startsWith(ErrorLine) }
                AppLog.error(
                    "crash",
                    "the app stopped on its last run, ${error?.removePrefix(ErrorLine) ?: "no error was named"}",
                )
            }
            if (fs.exists(kept)) mutableLast.value = fs.read(kept) { readUtf8() }
        }.onFailure { AppLog.warn("crash", "the report of the last run could not be read, ${it.message}") }
        installCrashHook(::write)
    }

    fun dismiss() {
        mutableLast.value = null
        folder?.let { runCatching { FileSystem.SYSTEM.delete(it / KeptName) } }
    }

    private fun write(error: Throwable) {
        val folder = folder ?: return
        AppLog.error("crash", "the app hit an error it could not handle", error)
        val report = buildString {
            appendLine("Sumizuri ${BuildInfo.Version}, ${Instant.fromEpochMilliseconds(nowMillis())}")
            appendLine("$ErrorLine${error::class.simpleName}: ${error.message}")
            appendLine()
            appendLine(error.stackTraceToString())
            appendLine("The last lines of the log:")
            append(AppLog.text(ReportLines))
        }.redacted()
        runCatching { FileSystem.SYSTEM.write(folder / FreshName) { writeUtf8(report) } }
    }
}

// Calls back with an error nothing caught, before the app stops as it would have.
internal expect fun installCrashHook(onCrash: (Throwable) -> Unit)
