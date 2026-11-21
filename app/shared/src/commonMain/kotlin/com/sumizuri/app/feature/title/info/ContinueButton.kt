package com.sumizuri.app.feature.title.info

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.hoverable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.History
import androidx.compose.material.icons.outlined.PlayArrow
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.library.ChapterLock
import com.sumizuri.app.data.library.chapterLock
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.feature.title.chapter.ContinueTarget
import com.sumizuri.app.feature.title.chapter.spotText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.title_continue_all_read
import com.sumizuri.app.shared.resources.title_continue_left
import com.sumizuri.app.shared.resources.title_continue_locked
import com.sumizuri.app.shared.resources.title_continue_locked_left
import com.sumizuri.app.shared.resources.title_continue_next
import com.sumizuri.app.shared.resources.title_continue_read
import com.sumizuri.app.shared.resources.title_continue_resume
import com.sumizuri.app.shared.resources.title_continue_watched
import com.sumizuri.app.ui.kit.card.cardFill
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// How far through a title the person is: the chapters read and all of them, each number counted once however many copies it has.
private class ReadSoFar(val read: Int, val total: Int) {
    val share: Float get() = if (total == 0) 0f else read.toFloat() / total
}

private fun readSoFar(chapters: List<ChapterItem>): ReadSoFar {
    val byNumber = chapters.groupBy { it.number }
    return ReadSoFar(byNumber.count { (_, copies) -> copies.any { it.read } }, byNumber.size)
}

// The one card that goes on with a title, the same on a phone and a computer: a play button, the chapter after the furthest read, how far the person is with a bar along its foot, and the chapter begun or read lately to pick up again. A wash of the accent from the play button sets it apart from the chapters. The whole card opens the next chapter, the bar fills in when the page opens, and a glow around the play button breathes under the mouse.
@Composable
internal fun ContinueButton(
    target: ContinueTarget?,
    kind: Kind,
    chapters: List<ChapterItem>,
    onContinue: (Long) -> Unit,
    modifier: Modifier = Modifier,
) {
    if (target == null) return
    val colors = MaterialTheme.colorScheme
    val shape = MaterialTheme.shapes.large
    val hover = remember { MutableInteractionSource() }
    val hovered by hover.collectIsHoveredAsState()
    val so = remember(chapters) { readSoFar(chapters) }
    // When the next chapter is one the site holds back, the card still names it, with a lock and the time left.
    val lock = remember(target.name) { chapterLock(target.name) }
    val ms = motionMs(AppMotion.Page)
    // The bar grows from empty to where the person is once, and follows later changes smoothly.
    val filled = remember { Animatable(0f) }
    LaunchedEffect(so.share, ms) { filled.animateTo(so.share, tween(ms * 2, easing = AppMotion.Entrance)) }
    // A plain card with a wash of the accent that fades out from the play button, a little stronger under the mouse.
    val fast = motionMs(AppMotion.Fast)
    val lift by animateColorAsState(cardFill(lit = hovered), tween(fast), label = "lift")
    val wash by animateFloatAsState(if (hovered) 0.22f else 0.14f, tween(fast), label = "wash")
    val accent = colors.primary
    Column(modifier.fillMaxWidth().clip(shape)) {
        Column(
            Modifier
                .fillMaxWidth()
                .background(lift)
                .drawBehind {
                    drawRect(Brush.horizontalGradient(0f to accent.copy(alpha = wash), 0.75f to Color.Transparent))
                }.hoverable(hover)
                .clickable { onContinue(target.id) },
        ) {
            Row(
                Modifier.padding(start = 10.dp, end = 12.dp, top = 8.dp, bottom = 6.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                PlayMark(hovered, lock != null)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    // The chapter is named as the list names it, which for a site that numbers in two ways is not its number.
                    Text(
                        stringResource(
                            Res.string.title_continue_next,
                            lock?.name ?: target.name ?: spotText(kind, target.number, target.season),
                        ),
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold,
                        color = colors.onSurface,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                    Text(
                        lock?.let { lockedLine(it) } ?: progressLine(so, kind),
                        style = MaterialTheme.typography.bodySmall,
                        color = colors.onSurfaceVariant,
                        maxLines = 1,
                        overflow = TextOverflow.Ellipsis,
                    )
                }
                val otherId = target.otherId
                val otherNumber = target.otherNumber
                if (otherId != null && otherNumber != null) {
                    Box(
                        Modifier
                            .clip(MaterialTheme.shapes.small)
                            .background(softFill())
                            .clickable { onContinue(otherId) },
                    ) {
                        Row(
                            Modifier.padding(horizontal = 10.dp, vertical = 8.dp),
                            verticalAlignment = Alignment.CenterVertically,
                        ) {
                            Icon(Icons.Outlined.History, null, Modifier.size(16.dp), tint = colors.primary)
                            Text(
                                stringResource(
                                    Res.string.title_continue_resume,
                                    target.otherName ?: spotText(kind, otherNumber, target.otherSeason),
                                ),
                                Modifier.padding(start = 6.dp),
                                style = MaterialTheme.typography.labelLarge,
                                color = colors.onSurface,
                                maxLines = 1,
                                overflow = TextOverflow.Ellipsis,
                            )
                        }
                    }
                }
            }
            // The bar of how far the person is, along the foot of the card.
            // It is drawn at each frame without building the card again.
            // The filled part runs from a lighter accent to the full one and ends round.
            val track = colors.onSurface.copy(alpha = 0.08f)
            Box(
                Modifier.fillMaxWidth().height(4.dp).drawBehind {
                    drawRect(track)
                    val reach = size.width * filled.value
                    if (reach <= 0f) return@drawBehind
                    drawRoundRect(
                        Brush.horizontalGradient(listOf(accent.copy(alpha = 0.55f), accent), endX = reach),
                        size = Size(reach, size.height),
                        cornerRadius = CornerRadius(size.height / 2),
                    )
                },
            )
        }
    }
}

// The round play button in a soft glow, which brightens and breathes while the mouse is over the card. It never changes size, and with less motion the glow only brightens.
@Composable
private fun PlayMark(hovered: Boolean, locked: Boolean) {
    val colors = MaterialTheme.colorScheme
    val ms = motionMs(AppMotion.Page * 3)
    val back = motionMs(AppMotion.Fast)
    val glow = remember { Animatable(0f) }
    LaunchedEffect(hovered, ms, back) {
        when {
            hovered && ms > 0 -> {
                glow.animateTo(1f, tween(back))
                glow.animateTo(0.45f, infiniteRepeatable(tween(ms), RepeatMode.Reverse))
            }

            else -> glow.animateTo(if (hovered) 1f else 0f, tween(back))
        }
    }
    val halo = colors.primary
    Box(
        Modifier.size(52.dp).drawBehind { drawCircle(halo.copy(alpha = 0.12f + 0.16f * glow.value)) },
        contentAlignment = Alignment.Center,
    ) {
        Box(Modifier.size(42.dp).clip(CircleShape).background(colors.primary), contentAlignment = Alignment.Center) {
            Icon(if (locked) Icons.Rounded.Lock else Icons.Outlined.PlayArrow, null, tint = colors.onPrimary)
        }
    }
}

// How far the person is in words: the chapters or episodes read out of all, and how many are left, or that all are read.
@Composable
private fun progressLine(so: ReadSoFar, kind: Kind): String {
    val left = so.total - so.read
    if (so.total > 0 && left == 0) return stringResource(Res.string.title_continue_all_read)
    val done = stringResource(
        if (kind ==
            Kind.Anime
        ) {
            Res.string.title_continue_watched
        } else {
            Res.string.title_continue_read
        },
        so.read,
        so.total,
    )
    return done + " · " + pluralStringResource(Res.plurals.title_continue_left, left, left)
}

// What the card says under a locked chapter: the time the site said was left, or only that it is locked for now.
@Composable
private fun lockedLine(lock: ChapterLock): String =
    lock.left?.let { stringResource(Res.string.title_continue_locked_left, it) }
        ?: stringResource(Res.string.title_continue_locked)
