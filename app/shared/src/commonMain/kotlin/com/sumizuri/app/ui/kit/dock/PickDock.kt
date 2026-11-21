package com.sumizuri.app.ui.kit.dock

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material.icons.outlined.Deselect
import androidx.compose.material.icons.outlined.FlipToBack
import androidx.compose.material.icons.outlined.SelectAll
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.VerticalDivider
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.selection_all
import com.sumizuri.app.shared.resources.selection_close
import com.sumizuri.app.shared.resources.selection_count
import com.sumizuri.app.shared.resources.selection_invert_short
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// How wide the dock of picked items gets, and from what width it puts everything in one row with the names of the actions.
private val PickDockMost = 1100.dp
private val OneRowFrom = 760.dp

// The dock of picked items, the same for every list that picks: how many are picked with the ways to pick all, flip the picks and stop, then the actions of the list. It floats over the foot of the page like the dock of the reader. A wide window puts it all in one row with the names of the actions, and a phone gives the actions a row of their own. The count changes with a quick fade.
@Composable
fun PickDock(
    count: Int,
    allPicked: Boolean,
    onAll: () -> Unit,
    onClose: () -> Unit,
    modifier: Modifier = Modifier,
    onInvert: (() -> Unit)? = null,
    actions: @Composable RowScope.() -> Unit,
) {
    BoxWithConstraints(modifier.fillMaxWidth().padding(DockMargin), contentAlignment = Alignment.BottomCenter) {
        val wide = maxWidth >= OneRowFrom
        DockSurface(Modifier.widthIn(max = PickDockMost).fillMaxWidth()) {
            CompositionLocalProvider(LocalDockLabels provides true) {
                if (wide) {
                    Row(
                        Modifier.padding(horizontal = 6.dp, vertical = 6.dp),
                        verticalAlignment = Alignment.CenterVertically,
                    ) {
                        PickHead(count, allPicked, onAll, onClose, onInvert, stretch = false)
                        VerticalDivider(Modifier.height(36.dp).padding(horizontal = 6.dp))
                        Row(Modifier.weight(1f), content = actions)
                    }
                } else {
                    Column(Modifier.padding(horizontal = 6.dp, vertical = 6.dp)) {
                        Row(verticalAlignment = Alignment.CenterVertically) {
                            PickHead(count, allPicked, onAll, onClose, onInvert, stretch = true)
                        }
                        DockRule()
                        Row(Modifier.fillMaxWidth(), content = actions)
                    }
                }
            }
        }
    }
}

// The left of the dock: a cross that stops picking, the count, and the buttons that pick all or none and flip the picks.
@Composable
private fun RowScope.PickHead(
    count: Int,
    allPicked: Boolean,
    onAll: () -> Unit,
    onClose: () -> Unit,
    onInvert: (() -> Unit)?,
    stretch: Boolean,
) {
    IconButton(onClose) { Icon(Icons.Outlined.Close, stringResource(Res.string.selection_close)) }
    val ms = motionMs(AppMotion.Fast)
    // On a phone the count takes the room left in its own row. In one row it keeps to its size, so the actions get the rest.
    AnimatedContent(count, if (stretch) Modifier.weight(1f) else Modifier, transitionSpec = {
        fadeIn(tween(ms)) togetherWith
            fadeOut(tween(ms))
    }, label = "count") { shown ->
        Text(
            pluralStringResource(Res.plurals.selection_count, shown, shown),
            Modifier.padding(end = 8.dp),
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold,
            maxLines = 1,
        )
    }
    Row(horizontalArrangement = Arrangement.spacedBy(2.dp)) {
        TextButton(onAll) {
            Icon(
                if (allPicked) Icons.Outlined.Deselect else Icons.Outlined.SelectAll,
                null,
                Modifier.padding(end = 6.dp),
            )
            Text(stringResource(Res.string.selection_all), maxLines = 1)
        }
        if (onInvert != null) {
            TextButton(onInvert) {
                Icon(Icons.Outlined.FlipToBack, null, Modifier.padding(end = 6.dp))
                Text(stringResource(Res.string.selection_invert_short), maxLines = 1)
            }
        }
    }
}
