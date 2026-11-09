package com.sumizuri.app.feature.title.chapter

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
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
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Shadow
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import coil3.compose.AsyncImage
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.numberText
import com.sumizuri.app.feature.title.ChapterCallbacks
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.ui.kit.art.InkLinearProgressIndicator
import com.sumizuri.app.ui.kit.cover.MarkBar
import com.sumizuri.app.ui.kit.cover.rememberMarkColors
import com.sumizuri.app.ui.kit.image.ImageFilter
import com.sumizuri.app.ui.kit.image.imageRequest
import com.sumizuri.app.ui.text.agoText
import com.sumizuri.app.ui.text.numberedUnit

// One chapter as a cell of the grid. The number is big, with the name under it, when it came out at the bottom and a bar for how far it was read, and the button that saves it in the corner as in a row. With pictures on, a page from inside the chapter fills the cell behind them, dimmed once it is read.
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
    pictures: Boolean = false,
) {
    val colors = MaterialTheme.colorScheme
    val marks = rememberMarkColors()
    val container = LocalAppContainer.current
    // Asked only while the cell is on the screen, so a long list fetches the pages of what is seen.
    val picture by produceState<ChapterPicture?>(null, chapter.id, pictures) {
        value = if (pictures) container.chapterPictures.of(chapter.id) else null
    }
    val over = picture != null
    Surface(
        modifier.height(if (pictures) PictureCellHeight else CellHeight),
        shape = MaterialTheme.shapes.small,
        color = if (selected) colors.primaryContainer.copy(alpha = 0.5f) else colors.surfaceContainerHigh,
        border = if (selected) BorderStroke(2.dp, colors.primary) else null,
    ) {
        Box {
            picture?.let { shown ->
                AsyncImage(
                    imageRequest(shown.url, shown.headers, maxWidth = PictureWidth, sourceId = shown.sourceId),
                    null,
                    Modifier.matchParentSize().graphicsLayer { alpha = if (chapter.read) 0.45f else 1f },
                    contentScale = ContentScale.Crop,
                    filterQuality = ImageFilter,
                )
                Box(Modifier.matchParentSize().background(Shade))
            }
            Box(
                Modifier
                    .matchParentSize()
                    .chapterClicks(chapter, calls, selecting, preview)
                    .padding(horizontal = 10.dp, vertical = 8.dp),
            ) {
                Column(Modifier.fillMaxWidth()) {
                    Text(
                        chapter.number.numberText(),
                        style = MaterialTheme.typography.titleLarge.shadowedIf(over),
                        fontWeight = FontWeight.Bold,
                        color = when {
                            over -> Color.White.copy(alpha = if (chapter.read) 0.6f else 1f)
                            chapter.read -> colors.outline
                            else -> marks.dot
                        },
                    )
                    Text(
                        chapter.name ?: numberedUnit(kind, chapter.number),
                        Modifier.padding(top = 4.dp),
                        style = MaterialTheme.typography.bodyMedium.shadowedIf(over),
                        color = when {
                            over -> Color.White.copy(alpha = 0.85f)
                            chapter.read -> colors.onSurfaceVariant
                            else -> colors.onSurface
                        },
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
                                style = MaterialTheme.typography.bodySmall.shadowedIf(over),
                                color = if (over) Color.White.copy(alpha = 0.75f) else colors.onSurfaceVariant,
                                maxLines = 1,
                            )
                        }
                }
                if (selecting) {
                    PickMark(selected, Modifier.align(Alignment.TopEnd).size(20.dp))
                } else if (chapter.bookmarked) {
                    Icon(
                        Icons.Filled.Bookmark,
                        null,
                        Modifier.align(Alignment.TopEnd).size(18.dp),
                        tint = marks.bookmark,
                    )
                }
                if (!selecting && !preview && download != null) {
                    Box(Modifier.align(Alignment.BottomEnd)) { ChapterDownloadButton(chapter.id, download) }
                }
            }
        }
    }
}

private val CellHeight = 120.dp

// A soft dark edge round the words, so a bright page under them does not wash them out.
private val WordShadow = Shadow(Color.Black.copy(alpha = 0.8f), blurRadius = 6f)

// A cell with a page in it is taller, so the page shows more than a strip.
private val PictureCellHeight = 168.dp

// The page is asked for small, as a cell is only a few hundred pixels wide.
private const val PictureWidth = 480

// Dark at the top and the bottom where the words sit, so they read over any page.
private val Shade = Brush.verticalGradient(
    0f to Color.Black.copy(alpha = 0.72f),
    0.5f to Color.Black.copy(alpha = 0.3f),
    1f to Color.Black.copy(alpha = 0.85f),
)

private fun TextStyle.shadowedIf(over: Boolean): TextStyle = if (over) copy(shadow = WordShadow) else this
