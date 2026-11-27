package com.sumizuri.app.data.lists

import com.sumizuri.app.data.migration.MatchScoring
import com.sumizuri.app.data.model.Kind

// The longest name of a title a list keeps.
const val TitleNameLimit = 200

// A list of titles the person made, with how many it holds.
data class ReadingList(val id: Long, val name: String, val about: String, val size: Int, val changed: Long)

// One title on a list. It is only a name and a kind, so opening it looks the name up in the library or the sources.
data class ListItem(val id: Long, val title: String, val kind: Kind, val note: String, val key: String)

// A title to put on a list, by its name and kind. The name is cleaned the way a name of a list is.
class ListTitle(name: String, val kind: Kind) {
    val name: String = cleanLine(name, TitleNameLimit)

    // The same title written a little differently counts as one, so a list never holds it twice.
    val key: String = keyOf(this.name, kind.code)
}

// The name folded the way matching folds it, with the kind, and the plain name when folding leaves nothing.
internal fun keyOf(name: String, kind: Int): String {
    val folded = MatchScoring.normalize(name).ifEmpty { name.trim().lowercase() }
    return "$kind:$folded"
}

private val Spaces = Regex("[ \\t]+")
private val ManyBreaks = Regex("\n{3,}")

// One line of text with breaks, tabs and hidden marks made into single spaces, cut to the limit without splitting a letter.
fun cleanLine(text: String, limit: Int): String {
    val flat = buildString(text.length) { for (c in text) append(if (c.isISOControl() || c.isWhitespace()) ' ' else c) }
    return cut(flat.replace(Spaces, " ").trim(), limit)
}

// Text that may have lines, with hidden marks taken out, each line trimmed and no more than one empty line in a row.
fun cleanNote(text: String, limit: Int): String {
    val plain = text.replace("\r\n", "\n").filter { it == '\n' || !it.isISOControl() }
    val lines = plain.lines().joinToString("\n") { it.replace(Spaces, " ").trim() }
    return cut(lines.replace(ManyBreaks, "\n\n").trim(), limit)
}

// Cuts text to a length, stepping back when the cut would fall inside a letter made of two parts.
private fun cut(text: String, limit: Int): String {
    if (text.length <= limit) return text
    val end = if (text[limit - 1].isHighSurrogate()) limit - 1 else limit
    return text.substring(0, end).trimEnd()
}
