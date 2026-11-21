package com.sumizuri.app.feature.updates.row

import androidx.compose.animation.Crossfade
import androidx.compose.animation.core.tween
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.lazy.grid.GridItemSpan
import androidx.compose.foundation.lazy.grid.LazyGridScope
import androidx.compose.foundation.lazy.grid.itemsIndexed
import androidx.compose.ui.Modifier
import com.sumizuri.app.data.model.feed.FeedHeading
import com.sumizuri.app.data.model.feed.FeedRowStyle
import com.sumizuri.app.data.model.feed.UpdateItem
import com.sumizuri.app.data.model.library.LibraryDisplayStyle
import com.sumizuri.app.ui.kit.card.Hairline
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.motion.motionMs

// The titles of one stretch of time, as cells of a grid or as rows in the style the person chose. The action is what the button and the swipe of a row do, and onAction gets the item they were on.
internal fun LazyGridScope.feed(
    group: List<UpdateItem>,
    style: LibraryDisplayStyle,
    rowStyle: FeedRowStyle,
    rowSwipe: Boolean,
    action: FeedAction,
    onOpenTitle: (Long) -> Unit,
    onAction: (List<UpdateItem>) -> Unit,
) {
    if (style.isGrid) {
        itemsIndexed(group, key = { _, item -> "${item.title.id}_${item.chapterIds.first()}" }) { _, item ->
            UpdateGridTile(item, style, {
                onOpenTitle(item.title.id)
            }, { onAction(listOf(item)) }, Modifier.animateItem().entrance())
        }
        return
    }
    itemsIndexed(
        group,
        key = { _, item -> "${item.title.id}_${item.chapterIds.first()}" },
        span = { _, _ -> GridItemSpan(maxLineSpan) },
    ) { index, item ->
        val open = { onOpenTitle(item.title.id) }
        val act = { onAction(listOf(item)) }
        Readable(true, Modifier.animateItem().entrance()) {
            FeedSwipe(rowSwipe, action, act) {
                // A change of style fades each row from the old look to the new one.
                Crossfade(rowStyle, animationSpec = tween(motionMs(AppMotion.Medium)), label = "rowStyle") { shown ->
                    when (shown) {
                        FeedRowStyle.Cards -> UpdateCardRow(
                            item,
                            style == LibraryDisplayStyle.CompactList,
                            open,
                            act,
                            action,
                        )

                        FeedRowStyle.Timeline -> UpdateTimelineRow(item, index == group.lastIndex, open, act, action)

                        FeedRowStyle.Inbox -> Column {
                            if (index >
                                0
                            ) {
                                Hairline()
                            }
                            UpdateInboxRow(item, open, act, action)
                        }
                    }
                }
            }
        }
    }
}

// The heading of one stretch of time as a whole row, kept by its own key so it slides along with the rows when some above it go.
internal fun LazyGridScope.feedHeading(
    heading: FeedHeading,
    group: List<UpdateItem>,
    readable: Boolean,
    onMarkAllRead: (() -> Unit)?,
) {
    item(key = "day_${heading.kind}_${heading.stamp}", span = { GridItemSpan(maxLineSpan) }) {
        Readable(readable, Modifier.animateItem().entrance()) {
            FeedDayHeading(heading, group.first().at, group.size, onMarkAllRead)
        }
    }
}
