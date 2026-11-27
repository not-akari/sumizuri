package com.sumizuri.app.feature.lists

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.FormatListBulleted
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.lists.FrontCount
import com.sumizuri.app.data.lists.ReadingList
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.titles_count
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.motion.entrance
import com.sumizuri.app.ui.motion.feedbackScale
import com.sumizuri.app.ui.theme.LocalThemeSpec
import org.jetbrains.compose.resources.pluralStringResource

// A list on the page of the lists, with the covers of its first titles that stand for it.
data class ListFace(val list: ReadingList, val covers: List<Title>)

// How wide the front cover is next to the cell, which leaves room for the ones behind it to show.
private const val FrontShare = 0.8f

// One list in the grid of lists: its first covers stacked, the front one whole and the ones behind it peeking out above and to the side and a little darker, with the name and how many titles under them, in the way a cover tile of the library is.
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun ListStack(face: ListFace, onOpen: () -> Unit) {
    val source = remember { MutableInteractionSource() }
    val aspect = LocalThemeSpec.current.options.covers.aspect.ratio
    Column(
        Modifier
            .entrance()
            .feedbackScale(source)
            .combinedClickable(interactionSource = source, indication = null, onClick = onOpen),
    ) {
        BoxWithConstraints(Modifier.fillMaxWidth().aspectRatio(aspect)) {
            val front = maxWidth * FrontShare
            val stepX = (maxWidth - front) / 2
            val stepY = (maxHeight - front / aspect) / 2
            // A stack of fewer covers is moved in by the steps it does not use, so every stack sits in the middle of its cell.
            val unused = (FrontCount - face.covers.size.coerceAtLeast(1)).toFloat() / 2
            val startX = stepX * unused
            val startY = stepY * unused
            if (face.covers.isEmpty()) {
                EmptyStack(
                    Modifier
                        .align(
                            Alignment.BottomStart,
                        ).offset(x = startX, y = -startY)
                        .width(front)
                        .aspectRatio(aspect),
                )
            }
            // The ones behind are drawn first, so the front cover lies on top.
            face.covers.withIndex().reversed().forEach { (place, title) ->
                CoverArt(
                    title,
                    Modifier
                        .align(Alignment.BottomStart)
                        .offset(x = startX + stepX * place, y = -(startY + stepY * place))
                        .width(front)
                        .drawWithContent {
                            drawContent()
                            if (place > 0) drawRect(Color.Black.copy(alpha = 0.18f * place))
                        },
                    letterSize = 22,
                    aspect = aspect,
                )
            }
        }
        Text(
            face.list.name,
            Modifier.padding(top = 6.dp),
            style = MaterialTheme.typography.bodySmall,
            maxLines = 2,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            pluralStringResource(Res.plurals.titles_count, face.list.size, face.list.size),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.outline,
        )
    }
}

// The place of the covers of a list that has no titles yet.
@Composable
private fun EmptyStack(modifier: Modifier) {
    Box(
        modifier
            .clip(MaterialTheme.shapes.medium)
            .background(MaterialTheme.colorScheme.surfaceContainerHigh),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.AutoMirrored.Outlined.FormatListBulleted,
            null,
            Modifier.size(28.dp),
            tint = MaterialTheme.colorScheme.outline,
        )
    }
}
