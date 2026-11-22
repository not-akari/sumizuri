package com.sumizuri.app.feature.profile

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Edit
import androidx.compose.material.icons.outlined.SwapHoriz
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.layout
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.model.FeedItem
import com.sumizuri.app.data.model.stats.ReadingStats
import com.sumizuri.app.data.profile.Profile
import com.sumizuri.app.data.text.monthYearText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.block_label_library
import com.sumizuri.app.shared.resources.profile_chapters_read
import com.sumizuri.app.shared.resources.profile_edit_short
import com.sumizuri.app.shared.resources.profile_reading_since
import com.sumizuri.app.shared.resources.profile_switch
import com.sumizuri.app.shared.resources.stats_current_streak
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.kit.chips.SoftActionChip
import com.sumizuri.app.ui.kit.cover.SoftCover
import com.sumizuri.app.ui.kit.cover.focus.focusAlignment
import com.sumizuri.app.ui.kit.cover.focus.rememberCoverFocus
import com.sumizuri.app.ui.kit.page.PageGutter
import com.sumizuri.app.ui.kit.text.Figure
import com.sumizuri.app.ui.text.compactCount
import org.jetbrains.compose.resources.stringResource

// How tall the banner of covers is, how big the picture is, and how far the picture reaches into the banner.
private val BannerHeight = 150.dp

// The extra height the banner takes when the bar of the page sits on its top.
private val BarRoom = 56.dp
private val AvatarSize = 104.dp
private val AvatarOverlap = 52.dp

// How far each cover of the banner reaches under the one before it, as a share of its place.
private const val Overlap = 0.6f

// The top of the profile: when turned on in the experimental settings a banner of the covers read lately with the picture in a ring over its lower edge, or else the picture alone, the name set large with since when the reader has read, three figures of the reading, and the ways to switch or edit.
@Composable
internal fun ProfileHeader(
    profile: Profile,
    stats: ReadingStats,
    recent: List<FeedItem>,
    onSwitch: () -> Unit,
    onEdit: () -> Unit,
    banner: Boolean,
    modifier: Modifier = Modifier,
    // The bar of the page, drawn on the top of the banner so there is no gap above it.
    bar: (@Composable () -> Unit)? = null,
) {
    val colors = MaterialTheme.colorScheme
    Column(modifier.fillMaxWidth()) {
        if (banner) Banner(recent, bar)
        Row(
            Modifier.padding(start = 20.dp, end = 8.dp),
            verticalAlignment = Alignment.Bottom,
            horizontalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            ProfileAvatar(
                profile.name,
                profile.avatar,
                AvatarSize,
                Modifier
                    .then(if (banner) Modifier.offsetUp(AvatarOverlap) else Modifier)
                    .background(colors.background, CircleShape)
                    .border(3.dp, colors.primary, CircleShape)
                    .padding(5.dp)
                    .clip(CircleShape)
                    .clickable(onClick = onEdit),
            )
            Column(Modifier.weight(1f).padding(top = 10.dp)) {
                Text(
                    profile.name,
                    style = MaterialTheme.typography.headlineLarge,
                    fontSize = 30.sp,
                    fontWeight = FontWeight.ExtraBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                Text(
                    stringResource(Res.string.profile_reading_since, monthYearText(profile.createdAt)),
                    style = MaterialTheme.typography.bodySmall,
                    color = colors.onSurfaceVariant,
                )
            }
        }
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(top = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(28.dp),
        ) {
            Figure(compactCount(stats.libraryTitles), stringResource(Res.string.block_label_library))
            Figure(compactCount(stats.chaptersRead), stringResource(Res.string.profile_chapters_read))
            Figure(compactCount(stats.currentStreak), stringResource(Res.string.stats_current_streak))
        }
        Row(
            Modifier.padding(horizontal = 20.dp).padding(top = 14.dp),
            horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            SoftActionChip(onSwitch, { Text(stringResource(Res.string.profile_switch)) }, leadingIcon = {
                Icon(Icons.Outlined.SwapHoriz, null, Modifier.size(18.dp))
            })
            SoftActionChip(onEdit, { Text(stringResource(Res.string.profile_edit_short)) }, leadingIcon = {
                Icon(Icons.Outlined.Edit, null, Modifier.size(16.dp))
            })
        }
    }
}

// The covers read lately side by side and blurred, or a soft wash of the accent before anything was read. It has no edges of its own: it turns see-through toward the bottom and the sides, so it melts into whatever background the theme draws.
@Composable
private fun Banner(recent: List<FeedItem>, bar: (@Composable () -> Unit)?) {
    val height = if (bar != null) BannerHeight + BarRoom else BannerHeight
    // It reaches past the side room of the page, so it runs edge to edge with the bar on it.
    Box(Modifier.bleed(PageGutter).fillMaxWidth().height(height)) {
        Covers(recent, height)
        bar?.invoke()
    }
}

@Composable
private fun Covers(recent: List<FeedItem>, height: Dp) {
    Box(
        Modifier
            .fillMaxWidth()
            .height(height)
            .meltIntoPage()
            .background(softFill(strong = true)),
    ) {
        val titles = recent.map { it.title }.filter { !it.coverUrl.isNullOrBlank() }.take(6)
        if (titles.isNotEmpty()) {
            BoxWithConstraints(Modifier.fillMaxWidth().fillMaxHeight()) {
                // Each cover after the first reaches under the one before it and fades in from its left, so they melt into one band with no seams.
                val slot = maxWidth / titles.size
                val reach = slot * Overlap
                titles.forEachIndexed { index, title ->
                    val first = index == 0
                    val width = if (first) slot else slot + reach
                    val url = title.coverUrl.orEmpty()
                    val focus by rememberCoverFocus(url)
                    SoftCover(
                        url,
                        title.sourceId,
                        Modifier
                            .offset(x = slot * index - if (first) 0.dp else reach)
                            .width(width)
                            .fillMaxHeight()
                            .then(if (first) Modifier else Modifier.fadeIn(Overlap / (1f + Overlap))),
                        // The crop keeps the face of the cover in sight, as the backdrop of a title does.
                        // A light blur, so the covers can still be told apart.
                        width = 200,
                        height = 300,
                        alignment = focusAlignment(focus, width.value, height.value),
                        passes = 2,
                    )
                }
            }
        }
    }
}

// Lets what is drawn fade out to nothing at the bottom, and a little at the top and at each side.
private fun Modifier.meltIntoPage(): Modifier =
    graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen).drawWithContent {
        drawContent()
        drawRect(
            Brush.verticalGradient(
                0f to Color.Transparent,
                0.18f to Color.Black,
                0.45f to Color.Black,
                1f to Color.Transparent,
            ),
            blendMode = BlendMode.DstIn,
        )
        drawRect(
            Brush.horizontalGradient(
                0f to Color.Transparent,
                0.08f to Color.Black,
                0.92f to Color.Black,
                1f to Color.Transparent,
            ),
            blendMode = BlendMode.DstIn,
        )
    }

// Lets a part reach past the side room of what holds it by the given amount on each side.
private fun Modifier.bleed(by: Dp): Modifier = layout { measurable, constraints ->
    val extra = by.roundToPx() * 2
    val placeable = measurable.measure(
        constraints.copy(
            maxWidth = constraints.maxWidth + extra,
            minWidth =
            constraints.minWidth + extra,
        ),
    )
    layout(constraints.maxWidth, placeable.height) { placeable.place(-extra / 2, 0) }
}

// Draws a part higher by the given room and gives back that room below it, so it reaches over what is above.
private fun Modifier.offsetUp(by: Dp): Modifier = layout { measurable, constraints ->
    val placeable = measurable.measure(constraints)
    val up = by.roundToPx()
    layout(placeable.width, (placeable.height - up).coerceAtLeast(0)) { placeable.place(0, -up) }
}

// Fades a part in from its left edge over the given share of its width.
private fun Modifier.fadeIn(share: Float): Modifier =
    graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen).drawWithContent {
        drawContent()
        drawRect(Brush.horizontalGradient(0f to Color.Transparent, share to Color.Black), blendMode = BlendMode.DstIn)
    }
