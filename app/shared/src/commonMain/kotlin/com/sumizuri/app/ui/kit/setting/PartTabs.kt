package com.sumizuri.app.ui.kit.setting

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.selection.selectable
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.dp
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import kotlin.math.roundToInt

// How tall the row of tabs is, the room between its track and the mark of the chosen one, and the corners of both.
private val TabsHeight = 40.dp
private val TrackInset = 3.dp
private val TrackShape = RoundedCornerShape(50)
private val MarkShape = RoundedCornerShape(50)

// How tall the row is when it picks one of a few choices in the settings.
internal val ChoiceTabsHeight = 36.dp

// The parts of a page or a sheet as plain tabs side by side on a quiet track, the open one standing out of it in a lighter gray and sliding to the next. A page that pages with a swipe gives position, how far it has got from the first part, so the mark follows the finger. The same row picks one of a few choices in the settings, lower and with an icon beside each word when one is given.
@Composable
fun <T> PartTabs(
    parts: List<T>,
    selected: T,
    label: @Composable (T) -> String,
    modifier: Modifier = Modifier,
    position: (() -> Float)? = null,
    height: Dp = TabsHeight,
    icon: ((T) -> ImageVector)? = null,
    // A choice of a setting marks the chosen one in the main color, as the panels of the reader do, and the parts of a page in a lighter gray.
    accent: Boolean = false,
    onSelect: (T) -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    // The track is the light wash of the soft cards, and the chosen one a stronger wash with its words in the accent, or the solid accent for a choice of a setting.
    val track = softFill()
    val mark = if (accent) colors.primary else softFill(strong = true)
    val chosen = parts.indexOf(selected).coerceAtLeast(0)
    val slide by animateFloatAsState(chosen.toFloat(), tween(motionMs(AppMotion.Fast)), label = "tabs")
    BoxWithConstraints(
        modifier
            .fillMaxWidth()
            .height(height)
            .background(track, TrackShape)
            .padding(TrackInset),
    ) {
        val each = maxWidth / parts.size.coerceAtLeast(1)
        val eachPx = with(LocalDensity.current) { each.toPx() }
        // The mark is moved while the page is laid out, so a swipe moves it without composing the tabs again.
        Box(
            Modifier
                .offset { IntOffset(((position?.invoke() ?: slide) * eachPx).roundToInt(), 0) }
                .width(each)
                .fillMaxHeight()
                .background(mark, MarkShape),
        )
        Row(Modifier.fillMaxSize()) {
            parts.forEachIndexed { index, part ->
                val on = index == chosen
                val ink by animateColorAsState(
                    when {
                        on && accent -> colors.onPrimary
                        on -> colors.primary
                        else -> colors.onSurfaceVariant
                    },
                    tween(motionMs(AppMotion.Fast)),
                    label = "tab ink",
                )
                Box(
                    Modifier
                        .weight(1f)
                        .fillMaxHeight()
                        .clip(MarkShape)
                        .selectable(on, role = Role.Tab) { onSelect(part) },
                    contentAlignment = Alignment.Center,
                ) {
                    Row(
                        Modifier.padding(horizontal = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        if (icon != null) Icon(icon(part), null, Modifier.size(18.dp), tint = ink)
                        Text(
                            label(part),
                            color = ink,
                            style = MaterialTheme.typography.labelLarge,
                            fontWeight = if (on) FontWeight.SemiBold else FontWeight.Medium,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                    }
                }
            }
        }
    }
}
