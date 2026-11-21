package com.sumizuri.app.feature.updates.row

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.snap
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.history_remove
import com.sumizuri.app.shared.resources.selection_mark_read
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.stringResource

// The button at the end of a feed row, which is there as well as the swipe since a mouse cannot swipe easily. Taking a row out of the history is drawn quieter than marking read, since it is not what the page is for and a row should not look like it asks to be closed. Under the mouse the icon takes its color and pops a little.
@Composable
internal fun FeedActionButton(action: FeedAction, onClick: () -> Unit) {
    val colors = MaterialTheme.colorScheme
    val source = remember { MutableInteractionSource() }
    val hovered by source.collectIsHoveredAsState()
    val remove = action == FeedAction.Remove
    val ms = motionMs(AppMotion.Fast)
    val pop by animateFloatAsState(
        if (hovered) 1.15f else 1f,
        if (ms == 0) snap() else spring(0.45f, Spring.StiffnessMedium),
        label = "pop",
    )
    val tint by animateColorAsState(
        when {
            hovered && remove -> colors.error
            hovered -> colors.primary
            remove -> colors.outline
            else -> colors.onSurfaceVariant
        },
        tween(ms),
        label = "tint",
    )
    IconButton(onClick, interactionSource = source) {
        Icon(
            if (remove) Icons.Outlined.Close else Icons.Outlined.DoneAll,
            stringResource(if (remove) Res.string.history_remove else Res.string.selection_mark_read),
            Modifier
                .size(if (remove) 18.dp else 20.dp)
                .graphicsLayer {
                    scaleX = pop
                    scaleY = pop
                },
            tint = tint,
        )
    }
}

// What the button at the end of a feed row does: marks it read on the updates page, takes it out of the list on the history page.
enum class FeedAction { MarkRead, Remove }
