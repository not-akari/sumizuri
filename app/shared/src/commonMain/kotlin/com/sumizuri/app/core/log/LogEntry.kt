package com.sumizuri.app.core.log

// One line of the log. The time is epoch milliseconds.
data class LogEntry(val time: Long, val level: LogLevel, val tag: String, val message: String) {
    // The line as plain text, with the seconds since the app started. A line of an earlier run counts back from the start.
    fun line(startedAt: Long): String {
        val gap = time - startedAt
        val seconds = kotlin.math.abs(gap)
        val stamp = "${seconds / 1000}.${(seconds % 1000).toString().padStart(3, '0')}"
        return "${if (gap < 0) "-" else "+"}${stamp}s ${level.letter} $tag $message"
    }
}

enum class LogLevel(val letter: Char) {
    Debug('D'),
    Info('I'),
    Warn('W'),
    Error('E'),
}

// Where each new line goes besides the screen. A platform can swap it to write to a file or the system log.
fun interface LogSink {
    fun write(entry: LogEntry, line: String)

    // Called when the log is cleared, for a sink that keeps lines of its own.
    fun clear() {}
}

private const val Frames = 4

// The error kind, its message and the first few places it came from, on one line.
fun Throwable.briefTrace(): String {
    val where = stackTraceToString()
        .lineSequence()
        .filter { it.trimStart().startsWith("at ") }
        .take(Frames)
        .joinToString(" <- ") { it.trim().removePrefix("at ") }
    val cause = cause?.let { " cause ${it::class.simpleName}: ${it.message}" }.orEmpty()
    return "${this::class.simpleName}: $message$cause${if (where.isEmpty()) "" else " at $where"}"
}

// An address without its query, which is enough to see where a request went and keeps tokens out of the log.
fun String.withoutQuery(): String = substringBefore('?').substringBefore('#')

private val WebAddress = Regex("""https?://[^\s"'<>()]+""")
private val Bearer = Regex("""(?i)\bbearer\s+[^\s"',;]+""")
private val SecretValue = Regex(
    """(?i)\b(access_token|refresh_token|token|password|passwd|secret|api[_-]?key|apikey|authorization|cookie|signature|sig)(["']?\s*[:=]\s*["']?)([^\s"'&,;]+)""",
)

// The text with what could be private taken out: the query of every web address, and the value after a word such as token, password or key. Every line of the log passes through it, so a message that carries a whole address, such as the text of a network error, cannot leak a key.
fun String.redacted(): String {
    var text = if ("://" in this) WebAddress.replace(this) { it.value.withoutQuery() } else this
    text = Bearer.replace(text, "Bearer (hidden)")
    return SecretValue.replace(text) { "${it.groupValues[1]}${it.groupValues[2]}(hidden)" }
}
