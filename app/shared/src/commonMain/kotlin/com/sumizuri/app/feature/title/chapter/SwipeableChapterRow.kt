package com.sumizuri.app.feature.title.chapter

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.BookmarkAdd
import androidx.compose.material.icons.outlined.BookmarkRemove
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.RemoveDone
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxState
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.ui.graphics.vector.ImageVector
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.controls.ChapterRowAction
import com.sumizuri.app.feature.title.ChapterCallbacks
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.bookmark_add
import com.sumizuri.app.shared.resources.bookmark_remove
import com.sumizuri.app.shared.resources.chapter_action_select
import com.sumizuri.app.shared.resources.title_mark_read
import com.sumizuri.app.shared.resources.title_mark_unread
import com.sumizuri.app.ui.controls.LocalAppGestures
import com.sumizuri.app.ui.kit.swipe.SwipeBackdrop
import org.jetbrains.compose.resources.stringResource

// A chapter row that can be swiped. What a swipe to the right and a swipe to the left do is the person's choice, and a side set to nothing cannot be swiped. The row springs back after the action.
@Composable
internal fun SwipeableChapterRow(chapter: ChapterItem, kind: Kind, next: Boolean, calls: ChapterCallbacks, download: RowDownload? = null) {
    val gestures = LocalAppGestures.current
    val right = gestures.chapterSwipeRight
    val left = gestures.chapterSwipeLeft
    val state = rememberSwipeToDismissBoxState()
    // A swipe that goes all the way does its action and the row springs back.
    LaunchedEffect(state.currentValue, right, left, chapter) {
        when (state.currentValue) {
            SwipeToDismissBoxValue.StartToEnd -> right.perform(chapter, calls)
            SwipeToDismissBoxValue.EndToStart -> left.perform(chapter, calls)
            SwipeToDismissBoxValue.Settled -> return@LaunchedEffect
        }
        state.snapTo(SwipeToDismissBoxValue.Settled)
    }
    SwipeToDismissBox(
        state,
        backgroundContent = { SwipeBackground(state, if (state.dismissDirection == SwipeToDismissBoxValue.StartToEnd) right else left, chapter) },
        enableDismissFromStartToEnd = right != ChapterRowAction.None,
        enableDismissFromEndToStart = left != ChapterRowAction.None,
    ) {
        ChapterWideRow(chapter, kind, preview = false, next = next, calls = calls, download = download)
    }
}

@Composable
private fun SwipeBackground(state: SwipeToDismissBoxState, action: ChapterRowAction, chapter: ChapterItem) {
    val colors = MaterialTheme.colorScheme
    val direction = state.dismissDirection
    if (direction == SwipeToDismissBoxValue.Settled || action == ChapterRowAction.None) return
    val toRight = direction == SwipeToDismissBoxValue.StartToEnd
    val (icon, text) = look(action, chapter)
    val fill = if (toRight) colors.primaryContainer else colors.secondaryContainer
    val ink = if (toRight) colors.onPrimaryContainer else colors.onSecondaryContainer
    SwipeBackdrop(state, icon, text, fill, ink)
}

// The icon and the words that show what a swipe will do to this chapter.
@Composable
private fun look(action: ChapterRowAction, chapter: ChapterItem): Pair<ImageVector, String> = when (action) {
    ChapterRowAction.ToggleRead -> (if (chapter.read) Icons.Outlined.RemoveDone else Icons.Outlined.DoneAll) to
        stringResource(if (chapter.read) Res.string.title_mark_unread else Res.string.title_mark_read)

    ChapterRowAction.ToggleBookmark -> (if (chapter.bookmarked) Icons.Outlined.BookmarkRemove else Icons.Outlined.BookmarkAdd) to
        stringResource(if (chapter.bookmarked) Res.string.bookmark_remove else Res.string.bookmark_add)

    else -> Icons.Outlined.CheckCircle to stringResource(Res.string.chapter_action_select)
}

// Does what the person chose for a swipe or a long press, to one chapter.
internal fun ChapterRowAction.perform(chapter: ChapterItem, calls: ChapterCallbacks) {
    when (this) {
        ChapterRowAction.ToggleRead -> calls.onToggleRead(chapter.id, !chapter.read)
        ChapterRowAction.ToggleBookmark -> calls.onToggleBookmark(chapter.id, !chapter.bookmarked)
        ChapterRowAction.Select -> calls.onSelect(chapter.id)
        ChapterRowAction.None -> Unit
    }
}
