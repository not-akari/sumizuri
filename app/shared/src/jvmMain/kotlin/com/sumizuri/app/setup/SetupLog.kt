package com.sumizuri.app.setup

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ExpandMore
import androidx.compose.material.icons.outlined.Terminal
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.rotate
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.setup_log_closing
import com.sumizuri.app.shared.resources.setup_log_desktop
import com.sumizuri.app.shared.resources.setup_log_done
import com.sumizuri.app.shared.resources.setup_log_failed
import com.sumizuri.app.shared.resources.setup_log_library
import com.sumizuri.app.shared.resources.setup_log_menu
import com.sumizuri.app.shared.resources.setup_log_old
import com.sumizuri.app.shared.resources.setup_log_register
import com.sumizuri.app.shared.resources.setup_log_scheduled
import com.sumizuri.app.shared.resources.setup_log_startup
import com.sumizuri.app.shared.resources.setup_log_title
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import org.jetbrains.compose.resources.stringResource

// What a line of the live log says. Most carry a detail, such as a file or a folder.
internal enum class NoteKind { Phase, Closing, Old, File, Menu, Desktop, Startup, Library, Register, Scheduled, Done, Failed }

internal data class SetupNote(val kind: NoteKind, val detail: String)

// A fold under the work that shows each thing it does as it happens, the newest at the bottom, kept in view while new lines come.
@Composable
internal fun LogFold(model: SetupModel, open: Boolean, onToggle: () -> Unit, modifier: Modifier = Modifier) {
    val notes by model.notes.collectAsState()
    val turn by animateFloatAsState(if (open) 180f else 0f, tween(motionMs(AppMotion.Fast)), label = "fold")
    val ms = motionMs(AppMotion.Medium)
    Column(modifier.fillMaxWidth().softCard(shape = MaterialTheme.shapes.medium)) {
        Row(
            Modifier.fillMaxWidth().clip(MaterialTheme.shapes.medium).clickable(onClick = onToggle).padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Icon(Icons.Outlined.Terminal, null, tint = MaterialTheme.colorScheme.primary)
            Text(stringResource(Res.string.setup_log_title), Modifier.weight(1f), style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.SemiBold)
            Text(notes.size.toString(), style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
            Icon(Icons.Outlined.ExpandMore, null, Modifier.rotate(turn), tint = MaterialTheme.colorScheme.onSurfaceVariant)
        }
        AnimatedVisibility(open, enter = expandVertically(tween(ms)) + fadeIn(tween(ms)), exit = shrinkVertically(tween(ms)) + fadeOut(tween(ms))) {
            val list = rememberLazyListState()
            LaunchedEffect(notes.size) { if (notes.isNotEmpty()) list.scrollToItem(notes.lastIndex) }
            LazyColumn(Modifier.fillMaxWidth().height(150.dp).padding(start = 14.dp, end = 14.dp, bottom = 10.dp), state = list) {
                items(notes) { NoteLine(it) }
            }
        }
    }
}

// One line of the log: a part of the work stands out, a file is quiet, and a failure is in the error color.
@Composable
private fun NoteLine(note: SetupNote) {
    val colors = MaterialTheme.colorScheme
    val text = when (note.kind) {
        NoteKind.Phase -> SetupPhase.entries.firstOrNull { it.name == note.detail }?.let { stringResource(it.label()) } ?: note.detail
        NoteKind.Closing -> stringResource(Res.string.setup_log_closing, note.detail)
        NoteKind.Old -> stringResource(Res.string.setup_log_old, note.detail)
        NoteKind.File -> note.detail
        NoteKind.Menu -> stringResource(Res.string.setup_log_menu)
        NoteKind.Desktop -> stringResource(Res.string.setup_log_desktop)
        NoteKind.Startup -> stringResource(Res.string.setup_log_startup)
        NoteKind.Library -> stringResource(Res.string.setup_log_library, note.detail)
        NoteKind.Register -> stringResource(Res.string.setup_log_register)
        NoteKind.Scheduled -> stringResource(Res.string.setup_log_scheduled, note.detail)
        NoteKind.Done -> stringResource(Res.string.setup_log_done)
        NoteKind.Failed -> stringResource(Res.string.setup_log_failed, note.detail)
    }
    Text(
        text,
        Modifier.padding(vertical = 1.dp, horizontal = if (note.kind == NoteKind.File) 12.dp else 0.dp),
        style = MaterialTheme.typography.bodySmall,
        fontFamily = if (note.kind == NoteKind.File) FontFamily.Monospace else null,
        fontWeight = if (note.kind == NoteKind.Phase) FontWeight.SemiBold else null,
        color = when (note.kind) {
            NoteKind.File -> colors.outline
            NoteKind.Failed -> colors.error
            NoteKind.Phase, NoteKind.Done -> colors.primary
            else -> colors.onSurfaceVariant
        },
        maxLines = 1,
        overflow = TextOverflow.MiddleEllipsis,
    )
}
