package com.sumizuri.app.feature.player

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.feature.reader.ReaderRoute

// Opens a chapter in what suits it: an episode in the player, and pages or words in the reader. It looks at the kind of the title first, and shows nothing until it knows.
@Composable
fun ChapterRoute(
    chapterId: Long,
    onBack: () -> Unit,
    onOpenChapter: (Long) -> Unit,
    onOpenComments: (CommentsTarget) -> Unit,
) {
    val library = LocalAppContainer.current.library
    // What is known of the chapter is read once, to tell a video from a book and to give the reader its names and cover at once, and a chapter that is gone is left to the reader to say so.
    val looked by produceState<Looked?>(null, chapterId) { value = Looked(library.chapterPlace(chapterId)) }
    val place = looked?.place
    when {
        // Nothing is drawn for the moment it takes to tell a video from a book, so the page under it shows through and no black flashes.
        looked == null -> Box(Modifier.fillMaxSize())

        place?.kind == Kind.Anime -> PlayerRoute(chapterId, onBack, opening = place)

        else -> ReaderRoute(chapterId, onBack, onOpenChapter, onOpenComments, opening = place)
    }
}

// What the look up of a chapter found, which is nothing for a chapter that is gone.
private class Looked(val place: ChapterPlace?)
