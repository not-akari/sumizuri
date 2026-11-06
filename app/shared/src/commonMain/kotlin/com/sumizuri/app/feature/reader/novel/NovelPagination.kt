package com.sumizuri.app.feature.reader.novel

import androidx.compose.ui.text.TextMeasurer
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Constraints
import com.sumizuri.app.feature.reader.ReaderPage
import kotlinx.coroutines.yield
import kotlin.math.roundToInt

// How many paragraphs are set before the work lets the screen draw.
private const val Batch = 10

// Fills screens with text, as many whole lines as the height allows. The lines are measured the way they are drawn, so a screen shows exactly the lines it was given. A picture among the paragraphs takes a screen of its own. All sizes are in pixels.
suspend fun paginate(
    paragraphs: List<ReaderPage>,
    measurer: TextMeasurer,
    style: TextStyle,
    width: Int,
    height: Int,
    gap: Int,
): List<NovelPage> {
    val pages = mutableListOf<NovelPage>()
    var chunks = mutableListOf<NovelChunk>()
    var used = 0

    fun flush() {
        if (chunks.isNotEmpty()) pages += NovelPage(chunks)
        chunks = mutableListOf()
        used = 0
    }

    for ((index, paragraph) in paragraphs.withIndex()) {
        if (index % Batch == 0) yield()
        val picture = paragraph.imageUrl
        if (picture != null) {
            flush()
            pages += NovelPage(listOf(NovelChunk("", index, true, picture)))
            continue
        }
        val text = paragraph.text.orEmpty()
        val layout = measurer.measure(text, style, constraints = Constraints(maxWidth = width))
        var line = 0
        while (line < layout.lineCount) {
            val before = if (line == 0 && chunks.isNotEmpty()) gap else 0
            val top = layout.getLineTop(line)
            var end = line
            while (end < layout.lineCount && layout.getLineBottom(end) - top <= height - used - before) end++
            if (end == line) {
                // A screen always takes at least one line, even when a line is taller than the screen.
                if (chunks.isNotEmpty()) {
                    flush()
                    continue
                }
                end = line + 1
            }
            val piece = text.substring(layout.getLineStart(line), layout.getLineEnd(end - 1)).trimEnd()
            chunks += NovelChunk(piece, index, line == 0)
            used += before + (layout.getLineBottom(end - 1) - top).roundToInt()
            line = end
            if (line < layout.lineCount) flush()
        }
    }
    flush()
    return pages
}

// A run of lines from one paragraph. It is the first of its paragraph when the paragraph starts there, and the rest of a paragraph that went on from the page before otherwise.
data class NovelChunk(val text: String, val paragraph: Int, val first: Boolean, val picture: String? = null)

// What fits on one screen of text, from the end of one chunk to the start of the next.
data class NovelPage(val chunks: List<NovelChunk>)
