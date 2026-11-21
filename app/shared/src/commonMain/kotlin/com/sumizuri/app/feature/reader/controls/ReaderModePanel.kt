package com.sumizuri.app.feature.reader.controls

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.Check
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.reader.ReaderMode
import com.sumizuri.app.feature.reader.BarState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.manga_group_mode
import com.sumizuri.app.shared.resources.reader_mode_default
import com.sumizuri.app.shared.resources.reader_mode_make_default
import com.sumizuri.app.shared.resources.reader_mode_this_title
import com.sumizuri.app.ui.kit.dock.PanelHead
import org.jetbrains.compose.resources.stringResource

// How big the button to the chapter before or after is at an end of the row.
private val ChapterEndWidth = 44.dp

// The arrow to the chapter before or after at an end of the row of actions, centered in the row with no number under it. Its number is read out with its name. Faded when there is none.
@Composable
internal fun ChapterEnd(
    icon: ImageVector,
    label: String,
    number: String?,
    target: Long?,
    onOpenChapter: (Long) -> Unit,
) {
    val enabled = target != null
    val tint = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = if (enabled) 1f else 0.3f)
    val said = if (number == null) label else "$label $number"
    Box(
        Modifier
            .size(ChapterEndWidth)
            .clip(CircleShape)
            .clickable(enabled = enabled, role = Role.Button, onClickLabel = said) { target?.let(onOpenChapter) },
        contentAlignment = Alignment.Center,
    ) {
        Icon(icon, said, Modifier.size(22.dp), tint = tint)
    }
}

// The ways to read as a panel of the dock. A mode picked here is kept for this title, which the line under the head says. The mode every other title opens in carries a small tag, and a button makes the mode of this title that default too, so the mode has one place and not two.
@Composable
internal fun ModePanel(
    bar: BarState,
    defaultMode: ReaderMode,
    onDefaultMode: (ReaderMode) -> Unit,
    onClose: () -> Unit,
    onMode: (ReaderMode) -> Unit,
) {
    val colors = MaterialTheme.colorScheme

    // Words read in pages under every mode but the scroll, so a mode stands for the row it falls under.
    fun row(mode: ReaderMode) = if (bar.textual && mode != ReaderMode.Continuous) ReaderMode.LeftToRight else mode
    Column {
        PanelHead(stringResource(Res.string.manga_group_mode), onClose)
        Text(
            stringResource(Res.string.reader_mode_this_title),
            Modifier.padding(start = 10.dp, bottom = 4.dp),
            style = MaterialTheme.typography.bodySmall,
            color = colors.onSurfaceVariant,
        )
        val modes = if (bar.textual) listOf(ReaderMode.LeftToRight, ReaderMode.Continuous) else ReaderMode.entries
        for (mode in modes) {
            val chosen = mode == row(bar.mode)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(16.dp))
                    .background(if (chosen) colors.secondaryContainer else Color.Transparent)
                    .clickable(role = Role.RadioButton) { onMode(mode) }
                    .padding(horizontal = 14.dp, vertical = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp),
            ) {
                Icon(mode.icon(), null, tint = if (chosen) colors.onSecondaryContainer else colors.onSurfaceVariant)
                Text(
                    stringResource(mode.labelFor(bar.textual)),
                    Modifier.weight(1f),
                    color = if (chosen) colors.onSecondaryContainer else colors.onSurface,
                    fontWeight = if (chosen) FontWeight.SemiBold else FontWeight.Normal,
                )
                if (mode == row(defaultMode)) {
                    Text(
                        stringResource(Res.string.reader_mode_default),
                        Modifier
                            .background(
                                colors.surfaceContainerHighest,
                                CircleShape,
                            ).padding(horizontal = 8.dp, vertical = 2.dp),
                        style = MaterialTheme.typography.labelSmall,
                        color = colors.onSurfaceVariant,
                    )
                }
                if (chosen) Icon(Icons.Outlined.Check, null, tint = colors.primary)
            }
        }
        if (row(bar.mode) != row(defaultMode)) {
            TextButton({ onDefaultMode(bar.mode) }, Modifier.align(Alignment.End)) {
                Text(stringResource(Res.string.reader_mode_make_default))
            }
        }
    }
}
