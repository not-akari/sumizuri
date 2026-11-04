package com.sumizuri.app.feature.reader.novel

import com.sumizuri.app.feature.reader.ReaderPage

// Text a source gives as one block is cut at blank lines. A block with hardly any blank lines but many line breaks is cut at the line breaks instead.
fun splitParagraphs(text: String): List<String> {
    val byBlankLine = text.split(Regex("\\n\\s*\\n")).map { it.trim() }.filter { it.isNotEmpty() }
    if (byBlankLine.size > 2 || text.count { it == '\n' } < 6) return byBlankLine
    return text.split('\n').map { it.trim() }.filter { it.isNotEmpty() }
}

// The pages of a text chapter as one page for each paragraph, so a long block becomes something that can be scrolled, paged and counted. A paragraph that is only a picture written as ![](address), such as the art of a light novel, becomes a page of that picture.
fun paragraphsOf(pages: List<ReaderPage>): List<ReaderPage> = pages.flatMap { page ->
    if (page.imageUrl !=
        null
    ) {
        listOf(page)
    } else {
        splitParagraphs(page.text.orEmpty()).map(::paragraphPage)
    }
}

private val PictureParagraph = Regex("""^!\[[^\]]*]\((https?://[^\s)]+)\)$""")

private fun paragraphPage(text: String): ReaderPage =
    PictureParagraph.matchEntire(text)?.let { ReaderPage(it.groupValues[1], null) } ?: ReaderPage(null, text)

// A chapter of words, which may have pictures among its paragraphs, as against a chapter of pictures only.
fun hasWords(pages: List<ReaderPage>): Boolean = pages.isEmpty() || pages.any { it.imageUrl == null }

// How many words a text holds. Languages written without spaces count about two characters to a word.
fun wordCount(pages: List<ReaderPage>): Int {
    var words = 0
    var characters = 0
    for (page in pages) {
        val text = page.text.orEmpty()
        words += text.trim().split(Regex("\\s+")).count { it.isNotEmpty() }
        characters += text.length
    }
    return if (words * 8 < characters) characters / 2 else words
}
