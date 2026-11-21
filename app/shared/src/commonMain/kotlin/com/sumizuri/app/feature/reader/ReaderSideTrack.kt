package com.sumizuri.app.feature.reader

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.KeyboardDoubleArrowDown
import androidx.compose.material.icons.outlined.KeyboardDoubleArrowUp
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.reader.controls.PageTrack
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_next_chapter
import com.sumizuri.app.shared.resources.reader_previous_chapter
import org.jetbrains.compose.resources.stringResource

// The chapter before or after, by its id and the number shown under its arrow.
internal class SideChapter(val id: Long?, val number: String?)

// The page track down the side of the screen, in a slim pill in the surface color of the theme: the chapter before at the top, then the page and the count, the track, and the chapter after at the bottom, so all the moving through the title sits in one place.
@Composable
internal fun SideTrack(
    page: Int,
    total: Int,
    previous: SideChapter,
    next: SideChapter,
    calls: ChromeCalls,
    modifier: Modifier,
) {
    if (total < 2) return
    Column(
        modifier
            .width(
                44.dp,
            ).background(MaterialTheme.colorScheme.surfaceContainer.copy(alpha = 0.95f), RoundedCornerShape(22.dp))
            .padding(vertical = 10.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        SideChapterButton(
            Icons.Outlined.KeyboardDoubleArrowUp,
            stringResource(Res.string.reader_previous_chapter),
            previous,
            numberBelow = true,
            calls.onOpenChapter,
        )
        SideRule()
        Text(
            (page + 1).toString(),
            style = MaterialTheme.typography.labelLarge,
            fontWeight = FontWeight.SemiBold,
        )
        Text(
            total.toString(),
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant,
        )
        PageTrack(page, total, vertical = true, calls.preview, calls.onJump, Modifier.weight(1f).padding(top = 6.dp))
        SideRule()
        SideChapterButton(
            Icons.Outlined.KeyboardDoubleArrowDown,
            stringResource(Res.string.reader_next_chapter),
            next,
            numberBelow = false,
            calls.onOpenChapter,
        )
    }
}

// A short line that keeps the chapter buttons apart from the page and the track, so their numbers are not read as one.
@Composable
private fun SideRule() {
    Box(
        Modifier
            .padding(vertical = 6.dp)
            .width(18.dp)
            .height(1.dp)
            .background(MaterialTheme.colorScheme.outlineVariant),
    )
}

// An arrow to the chapter before or after with its number beside it, faded when there is none.
@Composable
private fun SideChapterButton(
    icon: ImageVector,
    label: String,
    chapter: SideChapter,
    numberBelow: Boolean,
    onOpenChapter: (Long) -> Unit,
) {
    val enabled = chapter.id != null
    val tint = if (enabled) {
        MaterialTheme.colorScheme.onSurface
    } else {
        MaterialTheme.colorScheme.onSurface.copy(
            alpha = 0.3f,
        )
    }
    Column(
        Modifier
            .clip(RoundedCornerShape(16.dp))
            .clickable(enabled = enabled, role = Role.Button, onClickLabel = label) { chapter.id?.let(onOpenChapter) }
            .padding(horizontal = 6.dp, vertical = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
    ) {
        if (!numberBelow) chapter.number?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = tint) }
        Icon(icon, label, Modifier.size(22.dp), tint = tint)
        if (numberBelow) chapter.number?.let { Text(it, style = MaterialTheme.typography.labelSmall, color = tint) }
    }
}
