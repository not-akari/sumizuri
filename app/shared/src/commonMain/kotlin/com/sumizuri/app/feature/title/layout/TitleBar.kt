package com.sumizuri.app.feature.title.layout

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.asPaddingValues
import androidx.compose.foundation.layout.calculateEndPadding
import androidx.compose.foundation.layout.calculateStartPadding
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.ArrowBack
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.lerp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.back
import com.sumizuri.app.ui.kit.page.PageGutter
import org.jetbrains.compose.resources.stringResource

// How tall the bar is without the room the system takes at the top.
private val BarHeight = 56.dp

// The room the bar takes over the top of the page, with the room the status bar takes above it. A title page runs under the bars of the system, so its cover shows behind the status bar, and only its own pieces keep clear of them.
@Composable
internal fun titleBarRoom(): Dp = BarHeight + WindowInsets.safeDrawing.asPaddingValues().calculateTopPadding()

// The room around the list of a title page: the gutters at the sides, the bar at the top and a margin at the bottom, each with the room the system takes at that edge.
@Composable
internal fun titleListPadding(): PaddingValues {
    val safe = WindowInsets.safeDrawing.asPaddingValues()
    val direction = LocalLayoutDirection.current
    return PaddingValues(
        start = PageGutter + safe.calculateStartPadding(direction),
        end = PageGutter + safe.calculateEndPadding(direction),
        top = titleBarRoom(),
        bottom = 24.dp + safe.calculateBottomPadding(),
    )
}

// The back arrow over the top of the page. Over the cover it sits on a round shade, and as the page scrolls up the bar turns into a plain strip and the name of the title shows in it. A soft bar has no strip, as the list fades out under it. Progress from 0 to 1 tells how far.
@Composable
internal fun TitleBar(
    title: String,
    progress: Float,
    onBack: () -> Unit,
    modifier: Modifier = Modifier,
    soft: Boolean = false,
) {
    val page = MaterialTheme.colorScheme.background
    // A soft bar keeps the shade of its button, since no strip comes in behind it.
    val shade = IconButtonDefaults.iconButtonColors(
        containerColor = page.copy(
            alpha =
            0.55f * (if (soft) 1f else 1f - progress),
        ),
    )
    Row(
        modifier
            .fillMaxWidth()
            .then(if (soft) Modifier else Modifier.background(page.copy(alpha = progress)))
            .windowInsetsPadding(WindowInsets.safeDrawing.only(WindowInsetsSides.Top + WindowInsetsSides.Horizontal))
            .padding(horizontal = 8.dp, vertical = 4.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        IconButton(
            onBack,
            colors = shade,
        ) { Icon(Icons.AutoMirrored.Outlined.ArrowBack, stringResource(Res.string.back)) }
        Text(
            title,
            Modifier.weight(1f).padding(horizontal = 8.dp).alpha(progress),
            style = MaterialTheme.typography.titleMedium,
            fontWeight = FontWeight.Bold,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
}

// How far above the bottom of the bar the list starts to fade and how far below it the list is whole again, at rest and once scrolled.
private val FadeAbove = 28.dp
private val FadeBelow = 4.dp
private val ScrolledAbove = 0.dp
private val ScrolledBelow = 28.dp

// Fades a list out as it slides up under a soft bar, so the art behind the page shows through and the bar needs no strip of its own. Once scrolled, the list is clear under the whole bar, and at rest the heading stays sharp.
internal fun Modifier.fadeUnderBar(room: Dp, progress: () -> Float): Modifier = this
    .graphicsLayer { compositingStrategy = CompositingStrategy.Offscreen }
    .drawWithContent {
        drawContent()
        drawRect(
            Brush.verticalGradient(
                0f to Color.Transparent,
                0.5f to Color.Black.copy(alpha = 0.4f),
                1f to Color.Black,
                startY = (room - lerp(FadeAbove, ScrolledAbove, progress())).toPx(),
                endY = (room + lerp(FadeBelow, ScrolledBelow, progress())).toPx(),
            ),
            blendMode = BlendMode.DstIn,
        )
    }
