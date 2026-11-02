package com.sumizuri.app.feature.title.info

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Star
import androidx.compose.material.icons.outlined.Extension
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.feature.title.TitleState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.copied
import com.sumizuri.app.shared.resources.title_from_source
import com.sumizuri.app.ui.kit.cover.sourceName
import com.sumizuri.app.ui.kit.input.rememberCopyText
import com.sumizuri.app.ui.text.displayName
import com.sumizuri.app.ui.text.unitCount
import com.sumizuri.app.ui.theme.FixedColors
import kotlinx.coroutines.delay
import org.jetbrains.compose.resources.stringResource

// How long the note that the name was copied stays.
private const val CopiedMs = 1500L

// The name, the author, a line of facts and where it comes from, and on the phone only the name and the facts. On the phone it sits over the faded cover, so the name gets a glow of the page colour to be read on any picture. The wide page also puts the genres here.
@OptIn(ExperimentalLayoutApi::class, ExperimentalFoundationApi::class)
@Composable
internal fun TitleHeading(
    state: TitleState,
    title: Title,
    wide: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit = {},
) {
    val colors = MaterialTheme.colorScheme
    val copy = rememberCopyText()
    val name = title.displayName()
    var copied by remember { mutableStateOf(false) }
    // The note that the name was copied goes away by itself.
    LaunchedEffect(copied) {
        if (copied) {
            delay(CopiedMs)
            copied = false
        }
    }
    val glow = if (wide) null else Shadow(colors.background, blurRadius = 32f)
    Column(modifier, verticalArrangement = Arrangement.spacedBy(6.dp)) {
        // A tap does what the page does with it, and a press and hold copies the name.
        Text(
            title.displayName(),
            Modifier.combinedClickable(
                interactionSource = remember {
                    MutableInteractionSource()
                },
                indication = null,
                onClick = onClick,
                onLongClick = {
                    copy(name)
                    copied = true
                },
            ),
            style = (if (wide) MaterialTheme.typography.headlineMedium else MaterialTheme.typography.headlineSmall)
                .copy(
                    shadow = glow,
                ),
            fontWeight = FontWeight.Bold,
            maxLines = 4,
            overflow = TextOverflow.Ellipsis,
        )
        if (copied) {
            Text(
                stringResource(Res.string.copied),
                style = MaterialTheme.typography.labelSmall,
                color = colors.primary,
            )
        }
        // Over the cover on the phone the small lines are a step brighter and get the same glow as the name, so a busy picture does not swallow them.
        val quiet = if (wide) colors.onSurfaceVariant else colors.onSurface.copy(alpha = 0.86f)
        // The phone keeps the top for the name and the story, so the creators and the source wait in About.
        if (wide && title.author.isNotBlank()) {
            Text(
                title.author,
                style = MaterialTheme.typography.bodyMedium.copy(shadow = glow),
                color = quiet,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
        }
        FactLine(title, state.counted.size, quiet, glow)
        state.sourceName?.takeIf { wide }?.let { name ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Outlined.Extension, null, Modifier.size(14.dp), tint = quiet)
                Text(
                    stringResource(Res.string.title_from_source, sourceName(title.sourceId, name)),
                    Modifier.padding(start = 4.dp),
                    style = MaterialTheme.typography.bodySmall.copy(shadow = glow),
                    color = quiet,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
        if (wide && title.genres.isNotEmpty()) {
            Box(Modifier.padding(top = 6.dp)) { GenreChips(title.genres.take(8)) }
        }
    }
}

// The status as a small chip, the rating with a star, and how many chapters there are.
@OptIn(ExperimentalLayoutApi::class)
@Composable
private fun FactLine(title: Title, count: Int, quiet: Color, glow: Shadow?) {
    val colors = MaterialTheme.colorScheme
    val style = MaterialTheme.typography.labelMedium.copy(shadow = glow)
    FlowRow(
        horizontalArrangement = Arrangement.spacedBy(8.dp),
        verticalArrangement = Arrangement.spacedBy(6.dp),
        itemVerticalAlignment = Alignment.CenterVertically,
    ) {
        if (title.status != Status.Unknown) {
            val fill = when (title.status) {
                Status.Hiatus -> FixedColors.Hiatus.copy(alpha = 0.24f)
                Status.Completed -> FixedColors.Completed.copy(alpha = 0.24f)
                else -> colors.surfaceContainerHighest
            }
            Text(
                stringResource(title.status.label),
                Modifier
                    .clip(
                        MaterialTheme.shapes.extraSmall,
                    ).background(fill)
                    .padding(horizontal = 8.dp, vertical = 3.dp),
                style = style,
                color = colors.onSurface,
            )
        }
        title.rating?.let { rating ->
            Row(verticalAlignment = Alignment.CenterVertically) {
                Icon(Icons.Filled.Star, null, Modifier.size(16.dp), tint = FixedColors.Rating)
                Text(
                    ((rating * 10).toInt() / 10.0).toString(),
                    Modifier.padding(start = 2.dp),
                    style = style,
                    color = quiet,
                )
            }
        }
        if (count > 0) Text(unitCount(title.kind, count), style = style, color = quiet)
    }
}
