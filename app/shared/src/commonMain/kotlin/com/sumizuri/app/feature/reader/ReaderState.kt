package com.sumizuri.app.feature.reader

import androidx.compose.ui.graphics.ImageBitmap
import com.sumizuri.app.data.model.Chapter
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.data.model.reader.ReaderSettings
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.feature.reader.novel.hasWords
import com.sumizuri.app.source.model.Descramble
import org.jetbrains.compose.resources.StringResource

data class ReaderState(
    val loading: Boolean = true,
    val titleName: String = "",
    // The cover of the title, shown while the chapter comes in.
    val coverUrl: String? = null,
    val sourceId: String? = null,
    val chapterId: Long = 0,
    val titleId: Long = 0,
    val kind: Kind = Kind.Manga,
    val chapterName: String? = null,
    val chapterNumber: Double = 0.0,
    val pages: List<ReaderPage> = emptyList(),
    // Which pages belong to which chapter. There is more than one when the scroll has gone on into the next chapter.
    val segments: List<ReaderSegment> = emptyList(),
    // The headers the source wants on its pictures, including the referrer.
    val imageHeaders: Map<String, String> = emptyMap(),
    // The page to scroll to when the chapter opens, taken from where the reader stopped last time.
    val startIndex: Int = 0,
    // The same place as a fraction of the chapter, for a viewer that makes its own pages.
    val startFraction: Double = 0.0,
    // How many words the text of the chapter holds, or 0 for a chapter of pictures.
    val words: Int = 0,
    val previousId: Long? = null,
    val nextId: Long? = null,
    // Every chapter of the title, with the read marks kept up to date while the reader is open.
    val chapters: List<Chapter> = emptyList(),
    val message: ReaderMessage? = null,
    // The address of the site when a bot check stopped the chapter, so a person can be sent there to pass it.
    val challengeUrl: String? = null,
    // The address of the chapter on the website of its source, or null when it cannot be worked out.
    val webUrl: String? = null,
    // The comments of this chapter, when its source has them.
    val comments: CommentsTarget? = null,
    val settings: ReaderSettings = ReaderSettings(),
    // False while the shape of the first page is still being looked at to choose the mode.
    val modeKnown: Boolean = true,
) {
    // The mode of the title wins, then the default of the reader. Words have two ways to read, scrolled or in pages.
    val mode: ReaderMode
        get() = when {
            isText -> if ((settings.titleMode ?: settings.mode) ==
                ReaderMode.Continuous
            ) {
                ReaderMode.Continuous
            } else {
                ReaderMode.LeftToRight
            }

            settings.titleMode != null -> settings.titleMode

            else -> settings.mode
        }

    // Whether this chapter has a bookmark, kept up to date with the chapter list.
    val bookmarked: Boolean get() = chapters.firstOrNull { it.id == chapterId }?.bookmarked == true

    // A chapter of words, which is either one scroll or turned pages.
    val isText: Boolean get() = hasWords(pages)
}

// One page of the reader, a picture or a block of text. A picture that was cut into tiles and shuffled carries the way to put it back.
data class ReaderPage(val imageUrl: String?, val text: String?, val descramble: Descramble? = null)

// Why a chapter cannot be shown, either one of the fixed sentences or the words a source gave.
sealed interface ReaderMessage {
    data class Fixed(val text: StringResource) : ReaderMessage
    data class Detail(val text: String) : ReaderMessage
}

// Where one page of a chapter is, still coming in, failed, or in hand and cut into pieces.
sealed interface PageLoad {
    data object Loading : PageLoad
    data object Failed : PageLoad
    data class Ready(val slices: List<ImageBitmap>) : PageLoad
}

// What the bottom bar shows besides the page, the mode, whether the auto scroll runs and can run here, and how dark and warm the light is.
class BarState(
    val mode: ReaderMode,
    val auto: Boolean,
    val canAuto: Boolean,
    val dim: Float,
    val warmth: Float,
    // True for a chapter of words, which has two ways to read and not four.
    val textual: Boolean,
)
