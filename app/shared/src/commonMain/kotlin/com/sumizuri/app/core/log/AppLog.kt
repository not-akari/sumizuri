package com.sumizuri.app.core.log

import com.sumizuri.app.core.Lock
import com.sumizuri.app.data.text.nowMillis
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlin.concurrent.Volatile

private const val MaxLines = 2000

// The pages that show the log get its lines at most this often, however fast lines are written.
private const val PublishEveryMs = 250L

// The one log of the app. It keeps the latest lines for the Logs page and hands each line to the sinks. The lines are kept in a ring that drops the oldest, and the pages that show them get a copy now and then, so writing a line costs the same whether the log is long or short.
object AppLog {
    val startedAt: Long = nowMillis()

    private val ring = ArrayDeque<LogEntry>(MaxLines)
    private val lock = Lock()

    private val mutableEntries = MutableStateFlow<List<LogEntry>>(emptyList())
    val entries: StateFlow<List<LogEntry>> = mutableEntries

    // Set when lines came in since the pages last got a copy.
    @Volatile
    private var dirty = false

    @Volatile
    private var publishing = false
    private val publisher = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    // Prints by default. The desktop app swaps it for one that also writes a file.
    @Volatile
    var sink: LogSink = LogSink { _, line -> println("Sumizuri $line") }

    // Sinks added next to the main one, such as the one that saves lines in the database.
    private val extraSinks = MutableStateFlow<List<LogSink>>(emptyList())

    fun addSink(sink: LogSink) = extraSinks.update { it + sink }

    fun removeSink(sink: LogSink) = extraSinks.update { it - sink }

    fun debug(tag: String, message: String) = add(LogLevel.Debug, tag, message)
    fun info(tag: String, message: String) = add(LogLevel.Info, tag, message)
    fun warn(tag: String, message: String) = add(LogLevel.Warn, tag, message)
    fun error(tag: String, message: String, cause: Throwable? = null) = add(
        LogLevel.Error,
        tag,
        if (cause ==
            null
        ) {
            message
        } else {
            "$message, ${cause.briefTrace()}"
        },
    )

    // Puts the lines of earlier runs in front of the ones written since this run began.
    fun restore(earlier: List<LogEntry>) {
        withRing {
            val now = ring.toList()
            ring.clear()
            (earlier + now).takeLast(MaxLines).forEach { ring.addLast(it) }
        }
        publishNow()
    }

    fun clear() {
        withRing { ring.clear() }
        publishNow()
        (listOf(sink) + extraSinks.value).forEach { runCatching { it.clear() } }
    }

    // The lines as text, only the last ones when a number is given.
    fun text(last: Int = MaxLines): String = withRing { ring.takeLast(last) }.joinToString("\n") { it.line(startedAt) }

    private fun add(level: LogLevel, tag: String, message: String) {
        val entry = LogEntry(nowMillis(), level, tag, message.redacted())
        withRing {
            if (ring.size >= MaxLines) ring.removeFirst()
            ring.addLast(entry)
        }
        schedulePublish()
        val line = entry.line(startedAt)
        // A sink that fails must never break the work that was being logged.
        runCatching { sink.write(entry, line) }
        for (extra in extraSinks.value) runCatching { extra.write(entry, line) }
    }

    // The ring is only touched under the lock, since lines come from many threads. A thread that waits sleeps instead of spinning, and the thread that holds the lock may take it again, as a crash report does.
    private fun <T> withRing(block: () -> T): T = lock.withLock(block)

    private fun publishNow() {
        mutableEntries.value = withRing { ring.toList() }
    }

    // Gives the pages a copy soon, once for all the lines written meanwhile.
    private fun schedulePublish() {
        dirty = true
        if (publishing) return
        publishing = true
        publisher.launch {
            delay(PublishEveryMs)
            publishing = false
            if (dirty) {
                dirty = false
                publishNow()
            }
        }
    }
}
