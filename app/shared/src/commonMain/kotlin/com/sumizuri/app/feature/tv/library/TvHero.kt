package com.sumizuri.app.feature.tv.library

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.graphics.BlendMode
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.library.LibraryEntry
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.title.chapter.ContinueTarget
import com.sumizuri.app.feature.title.chapter.continueTargetOf
import com.sumizuri.app.feature.title.toItem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.tv_details
import com.sumizuri.app.shared.resources.tv_episodes_left
import com.sumizuri.app.shared.resources.tv_next
import com.sumizuri.app.shared.resources.tv_open
import com.sumizuri.app.shared.resources.tv_play
import com.sumizuri.app.shared.resources.tv_resume_button
import com.sumizuri.app.ui.kit.cover.CoverArt
import com.sumizuri.app.ui.kit.cover.focus.focusAlignment
import com.sumizuri.app.ui.kit.cover.focus.rememberCoverFocus
import com.sumizuri.app.ui.text.numberedUnit
import com.sumizuri.app.ui.tv.TvButton
import kotlinx.coroutines.flow.first
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// What the hero shows: a title of the library, or one a source offers.
internal sealed interface HeroItem {
    val key: String
    val title: Title

    class Owned(val entry: LibraryEntry) : HeroItem {
        override val key = "own:" + entry.title.id
        override val title = entry.title
    }

    class Offered(val found: Found) : HeroItem {
        override val key = "found:" + found.key
        override val title = found.title
    }
}

// The title in focus, large: its art on the right melting into the page, and on the left its name, the episode that comes next and how many are left, the start of its summary, and buttons to play it or open its page. A title a source offers shows its genres and source instead, and one button to open it.
@Composable
internal fun TvHero(item: HeroItem, onPlay: (Long) -> Unit, onDetails: () -> Unit) {
    val title = item.title
    val owned = (item as? HeroItem.Owned)?.entry
    val offered = (item as? HeroItem.Offered)?.found
    val library = LocalAppContainer.current.library
    // The episode to go on with is read from the chapters, the same way the page of the title works it out.
    val next by produceState<ContinueTarget?>(null, item.key) {
        if (owned == null) return@produceState
        value =
            runCatching {
                continueTargetOf(
                    library.chapters(title.id).first().map { it.toItem() },
                    nowMillis(),
                )
            }.getOrNull()
    }
    // The rows of the library leave the summary out, so it is read for the one title shown here.
    val summary by produceState(offered?.entry?.description.orEmpty(), item.key) {
        if (owned == null) return@produceState
        value = runCatching { library.title(title.id).first()?.summary }.getOrNull().orEmpty().ifBlank { title.summary }
    }
    val colors = MaterialTheme.colorScheme
    Box(Modifier.fillMaxSize()) {
        BoxWithConstraints(
            Modifier
                .align(Alignment.TopEnd)
                .fillMaxWidth(0.62f)
                .fillMaxHeight()
                .meltLeftAndDown(),
        ) {
            val art = rememberWideArt(title)
            val focus by rememberCoverFocus(art.coverUrl)
            CoverArt(
                art,
                Modifier.fillMaxSize(),
                letterSize = 48,
                aspect = maxWidth / maxHeight,
                alignment = focusAlignment(focus, maxWidth.value, maxHeight.value),
            )
        }
        Column(
            Modifier.align(Alignment.CenterStart).padding(start = 48.dp, top = 12.dp).widthIn(max = 470.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(
                title.name,
                fontSize = 32.sp,
                lineHeight = 38.sp,
                fontWeight = FontWeight.SemiBold,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            val line = if (offered != null) {
                (offered.entry.genres.take(3) + offered.source.name).joinToString("  ·  ")
            } else {
                listOfNotNull(
                    next?.let { stringResource(Res.string.tv_next, it.name ?: numberedUnit(Kind.Anime, it.number)) },
                    title.unread.takeIf { it > 0 }?.let { pluralStringResource(Res.plurals.tv_episodes_left, it, it) },
                ).joinToString("  ·  ")
            }
            if (line.isNotEmpty()) {
                Text(
                    line,
                    fontSize = 15.sp,
                    color = colors.primary,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            if (summary.isNotBlank()) {
                Text(
                    summary,
                    fontSize = 14.sp,
                    lineHeight = 20.sp,
                    color = colors.onSurfaceVariant,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            Row(Modifier.padding(top = 8.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                if (owned != null) {
                    TvButton(
                        stringResource(if (owned.lastRead > 0) Res.string.tv_resume_button else Res.string.tv_play),
                        { next?.id?.let(onPlay) ?: onDetails() },
                    )
                    TvButton(stringResource(Res.string.tv_details), onDetails, main = false)
                } else {
                    TvButton(stringResource(Res.string.tv_open), onDetails)
                }
            }
        }
    }
}

// Lets the art fade out to nothing toward its left side and its bottom, so it melts into the page behind the words.
internal fun Modifier.meltLeftAndDown(): Modifier =
    graphicsLayer(compositingStrategy = CompositingStrategy.Offscreen).drawWithContent {
        drawContent()
        drawRect(Brush.horizontalGradient(0f to Color.Transparent, 0.4f to Color.Black), blendMode = BlendMode.DstIn)
        drawRect(Brush.verticalGradient(0.6f to Color.Black, 1f to Color.Transparent), blendMode = BlendMode.DstIn)
    }
