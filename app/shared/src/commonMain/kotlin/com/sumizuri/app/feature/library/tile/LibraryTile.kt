package com.sumizuri.app.feature.library.tile

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.library.LibraryDisplayStyle
import com.sumizuri.app.ui.kit.cover.CoverPick
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.text.displayName

// One title of the library in the layout the person chose.
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun LibraryTile(
    title: Title,
    style: LibraryDisplayStyle,
    context: TileContext,
    pick: CoverPick,
    calls: TileCalls,
    modifier: Modifier = Modifier,
) {
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val tap = modifier
        .entrance()
        .feedbackScale(
            source,
        ).combinedClickable(
            interactionSource = source,
            indication = null,
            onClick = calls.onClick,
            onLongClick = calls.onLongClick,
            onDoubleClick = calls.onDoubleClick,
        )
    when (style) {
        LibraryDisplayStyle.ComfortableGrid -> Column(tap) {
            HoverCover(title, hovered, calls.onContinue) { TileCover(title, context, pick, nameOver = false) }
            Text(
                title.displayName(),
                Modifier.padding(top = 6.dp),
                style = MaterialTheme.typography.bodySmall.scaled(context.nameScale),
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }

        LibraryDisplayStyle.CompactGrid -> Box(tap) {
            HoverCover(title, hovered, calls.onContinue) { TileCover(title, context, pick, nameOver = true) }
        }

        LibraryDisplayStyle.CoverGrid -> Box(tap) {
            HoverCover(title, hovered, calls.onContinue) { TileCover(title, context, pick, nameOver = false) }
        }

        LibraryDisplayStyle.PanoramaGrid -> Box(tap) {
            HoverCover(title, hovered, calls.onContinue) {
                TileCover(title, context, pick, nameOver = true, aspect = context.panoramaAspect)
            }
        }

        LibraryDisplayStyle.List -> ListRow(title, context, pick, tap, hovered, compact = false)

        LibraryDisplayStyle.CompactList -> ListRow(title, context, pick, tap, hovered, compact = true)
    }
}
