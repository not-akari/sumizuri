package com.sumizuri.app.feature.title.chapter

import androidx.compose.animation.animateContentSize
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.hoverable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.interaction.collectIsHoveredAsState
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.DoneAll
import androidx.compose.material.icons.outlined.RemoveDone
import androidx.compose.material.icons.rounded.Check
import androidx.compose.material.icons.rounded.Lock
import androidx.compose.material.icons.rounded.PlayArrow
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.alpha
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.library.ChapterLock
import com.sumizuri.app.data.library.chapterLock
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.numberText
import com.sumizuri.app.feature.title.ChapterCallbacks
import com.sumizuri.app.feature.title.ChapterItem
import com.sumizuri.app.playback.touchPlayer
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.bookmark_add
import com.sumizuri.app.shared.resources.bookmark_remove
import com.sumizuri.app.shared.resources.chapter_locked
import com.sumizuri.app.shared.resources.chapter_locked_left
import com.sumizuri.app.shared.resources.title_mark_read
import com.sumizuri.app.shared.resources.title_mark_unread
import com.sumizuri.app.shared.resources.title_up_next
import com.sumizuri.app.ui.kit.card.softCard
import com.sumizuri.app.ui.kit.card.softFill
import com.sumizuri.app.ui.kit.cover.MarkColors
import com.sumizuri.app.ui.kit.cover.rememberMarkColors
import com.sumizuri.app.ui.motion.AppMotion
import com.sumizuri.app.ui.motion.motionMs
import com.sumizuri.app.ui.text.numberedUnit
import org.jetbrains.compose.resources.stringResource

// The room the buttons at the end of a row keep under a mouse, so the row does not shift when they show.

// One chapter as a row, the same on a phone and on a computer. A round mark at the start tells its state: next to read, part read with a ring, read with a tick, or new with a dot. The next one is tinted and tagged. Under a mouse its buttons show while the pointer is over it. A touch screen has no pointer to rest, so there the download button always shows, and reading and bookmarks are a swipe away.
@Composable
internal fun ChapterWideRow(
    chapter: ChapterItem,
    kind: Kind,
    preview: Boolean,
    next: Boolean,
    calls: ChapterCallbacks,
    download: RowDownload?,
) {
    val colors = MaterialTheme.colorScheme
    val marks = rememberMarkColors()
    val hover = remember { MutableInteractionSource() }
    val hovered by hover.collectIsHoveredAsState()
    // A chapter the site holds back shows a lock and the time left, and its row is dimmed.
    val lock = remember(chapter.name) { chapterLock(chapter.name) }
    Row(
        Modifier
            .fillMaxWidth()
            .alpha(if (lock != null) LockedAlpha else 1f)
            // Each chapter is a soft card of its own, like the tracker rows above it, and the next one stands out.
            .softCard(lit = hovered, strong = next)
            .hoverable(hover)
            .chapterClicks(chapter, calls, selecting = false, preview = preview)
            .padding(start = 14.dp, top = 10.dp, bottom = 10.dp, end = 6.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        StateMark(chapter, next, marks, preview, lock != null)
        Column(Modifier.weight(1f).padding(start = 14.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    rowName(lock?.name ?: chapter.name, chapter.number, kind),
                    Modifier.weight(1f, fill = false),
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = if (chapter.read) FontWeight.Normal else FontWeight.SemiBold,
                    color = if (chapter.read) colors.onSurfaceVariant else colors.onSurface,
                    // A phone has less room across, so a long name takes a second line there.
                    maxLines = if (touchPlayer) 2 else 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (lock != null) {
                    LockPill(lock)
                } else if (next) {
                    Text(
                        stringResource(Res.string.title_up_next),
                        Modifier
                            .clip(RoundedCornerShape(50))
                            .background(colors.primary)
                            .padding(horizontal = 8.dp, vertical = 2.dp),
                        style = MaterialTheme.typography.labelSmall,
                        fontWeight = FontWeight.SemiBold,
                        color = colors.onPrimary,
                    )
                }
            }
            ChapterSubtitle(chapter, marks, bar = false)
        }
        if (!preview) RowActions(chapter, hovered, calls, download, marks)
    }
}

// The buttons at the end of a row, which show while the pointer is over it, and a bookmark or a download stays shown.
@Composable
private fun RowActions(
    chapter: ChapterItem,
    hovered: Boolean,
    calls: ChapterCallbacks,
    download: RowDownload?,
    marks: MarkColors,
) {
    val colors = MaterialTheme.colorScheme
    // The room for the buttons opens only while they show, smoothly, so a long name is not cut short for buttons that are not there.
    Row(Modifier.animateContentSize(tween(motionMs(AppMotion.Fast))), horizontalArrangement = Arrangement.End) {
        if (download != null &&
            (hovered || touchPlayer || download.entity != null)
        ) {
            ChapterDownloadButton(chapter.id, download)
        }
        if (hovered || chapter.bookmarked) {
            IconButton({ calls.onToggleBookmark(chapter.id, !chapter.bookmarked) }, Modifier.size(RowButton)) {
                Icon(
                    if (chapter.bookmarked) Icons.Filled.Bookmark else Icons.Outlined.BookmarkBorder,
                    stringResource(if (chapter.bookmarked) Res.string.bookmark_remove else Res.string.bookmark_add),
                    Modifier.size(18.dp),
                    tint = if (chapter.bookmarked) marks.bookmark else colors.onSurfaceVariant,
                )
            }
        }
        if (hovered) {
            IconButton({ calls.onToggleRead(chapter.id, !chapter.read) }, Modifier.size(RowButton)) {
                Icon(
                    if (chapter.read) Icons.Outlined.RemoveDone else Icons.Outlined.DoneAll,
                    stringResource(if (chapter.read) Res.string.title_mark_unread else Res.string.title_mark_read),
                    Modifier.size(18.dp),
                    tint = colors.onSurfaceVariant,
                )
            }
        }
    }
}

// The name of a row, without a name that only says its number again, such as Episode 12: Episode 12.
@Composable
private fun rowName(given: String?, number: Double, kind: Kind): String {
    val numbered = numberedUnit(kind, number)
    val name = given?.trim() ?: return numbered
    val head = name.substringBefore(':').trim()
    val tail = name.substringAfter(':', "").trim()
    return if (tail.isNotEmpty() && tail.equals(head, ignoreCase = true)) head else name
}

// The round mark at the start of a row. A title not in the library has nothing read, so its rows show their number there.
@Composable
private fun StateMark(chapter: ChapterItem, next: Boolean, marks: MarkColors, preview: Boolean, locked: Boolean) {
    val colors = MaterialTheme.colorScheme
    val progress = chapter.progress
    Box(Modifier.size(30.dp), contentAlignment = Alignment.Center) {
        when {
            preview -> Text(
                chapter.number.numberText(),
                style = MaterialTheme.typography.labelLarge,
                color = colors.onSurfaceVariant,
                maxLines = 1,
            )

            next -> Box(
                Modifier.size(30.dp).clip(CircleShape).background(colors.primary),
                contentAlignment = Alignment.Center,
            ) {
                Icon(
                    if (locked) Icons.Rounded.Lock else Icons.Rounded.PlayArrow,
                    null,
                    Modifier.size(if (locked) 16.dp else 18.dp),
                    tint = colors.onPrimary,
                )
            }

            locked && !chapter.read -> Icon(Icons.Rounded.Lock, null, Modifier.size(17.dp), tint = colors.primary)

            chapter.read -> Icon(Icons.Rounded.Check, null, Modifier.size(18.dp), tint = colors.outline)

            progress != null -> {
                val track = colors.outlineVariant
                val fill = marks.bar.firstOrNull() ?: colors.primary
                Canvas(Modifier.size(22.dp)) {
                    val stroke = 2.5.dp.toPx()
                    val inset = stroke / 2
                    val arc = Size(size.width - stroke, size.height - stroke)
                    drawArc(track, 0f, 360f, false, Offset(inset, inset), arc, style = Stroke(stroke))
                    drawArc(
                        fill,
                        -90f,
                        360f * progress,
                        false,
                        Offset(inset, inset),
                        arc,
                        style = Stroke(stroke, cap = StrokeCap.Round),
                    )
                }
            }

            else -> Box(Modifier.size(8.dp).clip(CircleShape).background(marks.dot))
        }
    }
}

// How see-through a locked row is.
private const val LockedAlpha = 0.72f

// The pill after the name of a locked chapter, with the time the site said was left when it gave one.
@Composable
private fun LockPill(lock: ChapterLock) {
    val colors = MaterialTheme.colorScheme
    Text(
        lock.left?.let { stringResource(Res.string.chapter_locked_left, it) }
            ?: stringResource(Res.string.chapter_locked),
        Modifier
            .clip(RoundedCornerShape(50))
            .background(softFill(strong = true))
            .padding(horizontal = 8.dp, vertical = 2.dp),
        style = MaterialTheme.typography.labelSmall,
        fontWeight = FontWeight.SemiBold,
        color = colors.primary,
        maxLines = 1,
    )
}
