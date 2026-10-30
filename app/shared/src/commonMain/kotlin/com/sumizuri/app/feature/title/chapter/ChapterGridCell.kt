package com.sumizuri.app.feature.title.chapter

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.numberText
import com.sumizuri.app.feature.title.ChapterCallbacks
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.kit.cover.MarkBar
import com.sumizuri.app.ui.kit.cover.rememberMarkColors
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.numberedUnit

// One chapter as a cell of the grid. The number is big, with the name under it, when it came out at the bottom and a bar for how far it was read, and the button that saves it in the corner as in a row.
@OptIn(ExperimentalFoundationApi::class)
@Composable
internal fun ChapterGridCell(
    chapter: ChapterItem,
    kind: Kind,
    preview: Boolean,
    selecting: Boolean,
    selected: Boolean,
    calls: ChapterCallbacks,
    modifier: Modifier = Modifier,
    download: RowDownload? = null,
) {
    val colors = MaterialTheme.colorScheme
    val marks = rememberMarkColors()
    Surface(
        modifier.height(CellHeight),
        shape = MaterialTheme.shapes.small,
        color = if (selected) colors.primaryContainer.copy(alpha = 0.5f) else colors.surfaceContainerHigh,
        border = if (selected) BorderStroke(2.dp, colors.primary) else null,
    ) {
        Box(
            Modifier
                .chapterClicks(chapter, calls, selecting, preview)
                .padding(horizontal = 10.dp, vertical = 8.dp),
        ) {
            Column(Modifier.fillMaxWidth()) {
                Text(
                    chapter.number.numberText(),
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold,
                    color = if (chapter.read) colors.outline else marks.dot,
                )
                Text(
                    chapter.name ?: numberedUnit(kind, chapter.number),
                    Modifier.padding(top = 4.dp),
                    style = MaterialTheme.typography.bodyMedium,
                    color = if (chapter.read) colors.onSurfaceVariant else colors.onSurface,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
                Spacer(Modifier.weight(1f))
                chapter.progress?.takeIf { !chapter.read }?.let { progress ->
                    MarkBar(progress, marks.bar, Modifier.padding(bottom = 6.dp))
                }
                chapter.at
                    .takeIf {
                        it > 0
                    }?.let {
                        Text(
                            agoText(it),
                            style = MaterialTheme.typography.bodySmall,
                            color = colors.onSurfaceVariant,
                            maxLines = 1,
                        )
                    }
            }
            if (selecting) {
                PickMark(selected, Modifier.align(Alignment.TopEnd).size(20.dp))
            } else if (chapter.bookmarked) {
                Icon(Icons.Filled.Bookmark, null, Modifier.align(Alignment.TopEnd).size(18.dp), tint = marks.bookmark)
            }
            if (!selecting && !preview && download != null) {
                Box(Modifier.align(Alignment.BottomEnd)) { ChapterDownloadButton(chapter.id, download) }
            }
        }
    }
}

private val CellHeight = 120.dp
