package com.sumizuri.app.data.model

data class Title(
    val id: Long,
    val name: String,
    val kind: Kind,
    val coverUrl: String?,
    val unread: Int,
    val status: Status,
    val summary: String,
    val author: String = "",
    val genres: List<String> = emptyList(),
    val inLibrary: Boolean,
    // The source it came from and whether that source can be asked now.
    val sourceId: String = "",
    val sourceState: SourceState = SourceState.Ready,
    // The rating from the source, out of ten, or null when there is none.
    val rating: Double? = null,
    // The page of the title on the website of the source, when it is known.
    val webUrl: String? = null,
    // When the title was put in the library, as epoch milliseconds.
    val addedAt: Long = 0,
    val favorite: Boolean = false,
    // How many chapters the title has, to work out how far the reader is through it.
    val chapterCount: Int = 0,
) {
    // A colour for the painted cover, taken from the name so it never changes.
    val hue: Float get() = name.fold(7) { sum, char -> sum * 31 + char.code }.mod(360).toFloat()

    // How far the reader is through the title, from 0 to 1, or null while it has no chapters.
    val readPart: Float? get() = if (chapterCount >
        0
    ) {
        (chapterCount - unread).coerceAtLeast(0).toFloat() / chapterCount
    } else {
        null
    }
}
