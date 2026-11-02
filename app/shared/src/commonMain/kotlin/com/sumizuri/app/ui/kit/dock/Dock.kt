package com.sumizuri.app.ui.kit.dock

import androidx.compose.animation.animateColorAsState
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.RowScope
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicText
import androidx.compose.foundation.text.TextAutoSize
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Close
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.compositionLocalOf
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.close
import org.jetbrains.compose.resources.stringResource

// The round corners of a dock and of a capsule over a page or a video, and how far they float from the edges of the screen.
val DockShape = RoundedCornerShape(28.dp)
val DockMargin = 12.dp

// The surface of a dock or a capsule: the container color of the theme, as solid as the person chose or fully solid while a panel is open, with a thin edge.
@Composable
fun DockSurface(
    modifier: Modifier = Modifier,
    shade: Float = 0.92f,
    solid: Boolean = false,
    content: @Composable () -> Unit,
) {
    val colors = MaterialTheme.colorScheme
    Surface(
        modifier.keepTaps(),
        shape = DockShape,
        color = colors.surfaceContainerHigh.copy(alpha = if (solid) 1f else shade),
        border = BorderStroke(1.dp, colors.outlineVariant.copy(alpha = 0.5f)),
        content = content,
    )
}

// The head of a panel in a dock: its title, a control of its own at the right when it has one, and a cross that closes it.
@Composable
fun PanelHead(title: String, onClose: () -> Unit, trailing: (@Composable () -> Unit)? = null) {
    Row(Modifier.fillMaxWidth().padding(start = 10.dp), verticalAlignment = Alignment.CenterVertically) {
        Text(
            title,
            Modifier.weight(1f),
            style = MaterialTheme.typography.titleMedium,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        trailing?.invoke()
        IconButton(onClose) { Icon(Icons.Outlined.Close, stringResource(Res.string.close)) }
    }
}

// The hairline that parts the rows of a dock.
@Composable
fun DockRule() {
    HorizontalDivider(
        Modifier.padding(horizontal = 8.dp, vertical = 2.dp),
        color = MaterialTheme.colorScheme.outlineVariant.copy(alpha = 0.6f),
    )
}

// Whether the actions of a dock show their names under their icons, which a dock turns on when it has the room.
val LocalDockLabels = compositionLocalOf { false }

// The smallest a name under a button gets before it is cut.
private val SmallestName = 8.sp

// One action of a dock: an icon in a pill that fills while its panel is open or its feature is on. The name is read out to screen readers.
@Composable
fun RowScope.DockAction(
    icon: ImageVector,
    label: String,
    active: Boolean,
    onClick: () -> Unit,
    enabled: Boolean = true,
) {
    val colors = MaterialTheme.colorScheme
    val pill by animateColorAsState(if (active) colors.secondaryContainer else Color.Transparent)
    val tint = when {
        !enabled -> colors.onSurface.copy(alpha = 0.3f)
        active -> colors.onSecondaryContainer
        else -> colors.onSurfaceVariant
    }
    val named = LocalDockLabels.current
    Box(Modifier.weight(1f), contentAlignment = Alignment.Center) {
        Column(
            Modifier
                .clip(MaterialTheme.shapes.medium)
                .clickable(enabled = enabled, onClickLabel = label, onClick = onClick)
                .padding(horizontal = 4.dp, vertical = if (named) 4.dp else 0.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
        ) {
            Box(
                Modifier
                    .width(56.dp)
                    .height(if (named) 32.dp else 38.dp)
                    .clip(CircleShape)
                    .background(pill),
                contentAlignment = Alignment.Center,
            ) {
                Icon(icon, label, Modifier.size(22.dp), tint = tint)
            }
            // A wide dock has room for the name under the icon, which makes every button clear without a guess. The name keeps to one line and gets a little smaller where the room is tight.
            if (named) {
                val style = MaterialTheme.typography.labelSmall
                BasicText(
                    label,
                    Modifier.padding(top = 2.dp),
                    style = style.copy(color = tint, textAlign = TextAlign.Center),
                    maxLines = 1,
                    autoSize = TextAutoSize.StepBased(minFontSize = SmallestName, maxFontSize = style.fontSize),
                )
            }
        }
    }
}

// Taps on a dock stay on it, so a tap on its edge does not reach the page or the video under it.
fun Modifier.keepTaps(): Modifier = pointerInput(Unit) { detectTapGestures { } }
