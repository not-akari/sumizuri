package com.sumizuri.app.feature.title.chapter

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.numberText
import com.sumizuri.app.feature.title.ChapterCallbacks
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_volume
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.cover.MarkBar
import com.sumizuri.app.ui.kit.cover.MarkColors
import com.sumizuri.app.ui.kit.cover.rememberMarkColors
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.numberedUnit
import org.jetbrains.compose.resources.stringResource

// The size of a button on a chapter row, smaller than usual so the name of the chapter keeps its room.
internal val RowButton = 36.dp

// One chapter as a row while chapters are picked, with a pick box at the start. Every other list uses the row in ChapterWideRow.
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun ChapterListRow(
    chapter: ChapterItem,
    kind: Kind,
    preview: Boolean,
    selecting: Boolean,
    selected: Boolean,
    calls: ChapterCallbacks,
    modifier: Modifier = Modifier,
) {
    val colors = MaterialTheme.colorScheme
    val marks = rememberMarkColors()
    Row(
        modifier
            .fillMaxWidth()
            .softCard(strong = selected)
            .chapterClicks(chapter, calls, selecting, preview)
            .padding(start = 14.dp, top = 8.dp, bottom = 8.dp, end = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Box(Modifier.padding(end = 12.dp).size(22.dp), contentAlignment = Alignment.Center) {
            when {
                selecting -> PickMark(selected)
                !chapter.read && !preview -> Box(Modifier.size(7.dp).clip(CircleShape).background(marks.dot))
            }
        }
        Column(Modifier.weight(1f)) {
            Text(
                chapter.name ?: numberedUnit(kind, chapter.number),
                fontSize = 14.sp,
                fontWeight = if (chapter.read) FontWeight.Medium else FontWeight.SemiBold,
                color = if (chapter.read) colors.onSurfaceVariant else colors.onSurface,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis,
            )
            ChapterSubtitle(chapter, marks)
        }
    }
}

// The number of a named chapter, its volume, when it came out, its language, the group that put it out and any other labels, and under them the bar of how far it was read. Copies of one chapter in other languages or from other groups are told apart by these.
@Composable
internal fun ChapterSubtitle(chapter: ChapterItem, marks: MarkColors, bar: Boolean = true) {
    val parts = listOfNotNull(
        // The number is left out when the name already says it.
        chapter.name
            ?.takeUnless {
                it.contains(
                    chapter.number.numberText(),
                )
            }?.let { "#" + chapter.number.numberText() },
        // What tells copies of one chapter apart comes first, as the line is cut when it runs long.
        chapter.language?.uppercase(),
        chapter.scanlator,
    ) + chapter.tags.values + listOfNotNull(
        chapter.volume?.let { stringResource(Res.string.chapter_volume, it.numberText()) },
        chapter.at.takeIf { it > 0 }?.let { agoText(it) },
    )
    if (parts.isNotEmpty()) {
        Text(
            parts.joinToString(" · "),
            Modifier.padding(top = 2.dp),
            fontSize = 12.sp,
            color = MaterialTheme.colorScheme.outline,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
    }
    val progress = chapter.progress
    if (bar && !chapter.read && progress != null) {
        MarkBar(progress, marks.bar, Modifier.padding(top = 4.dp))
    }
}
