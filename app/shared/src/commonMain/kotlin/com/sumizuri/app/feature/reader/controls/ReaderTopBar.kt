package com.sumizuri.app.feature.reader.controls

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.outlined.Comment
import androidx.compose.material.icons.automirrored.outlined.OpenInNew
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.outlined.BookmarkBorder
import androidx.compose.material.icons.outlined.MoreVert
import androidx.compose.material.icons.outlined.VisibilityOff
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.reader.ReaderState
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.bookmark_add
import com.sumizuri.app.shared.resources.bookmark_remove
import com.sumizuri.app.shared.resources.comments_chapter_title
import com.sumizuri.app.shared.resources.more
import com.sumizuri.app.shared.resources.reader_incognito
import com.sumizuri.app.shared.resources.reader_open_browser
import com.sumizuri.app.ui.kit.input.BackButton
import com.sumizuri.app.ui.text.numberedUnit
import org.jetbrains.compose.resources.stringResource

// The top of the reader: back, the name of the chapter with the title under it, the bookmark, the comments when the source has them, and a menu with the rest. A small mark under the name says progress is not being saved.
@Composable
fun ReaderTopBar(
    state: ReaderState,
    onBack: () -> Unit,
    onBookmark: () -> Unit,
    onOpenBrowser: (() -> Unit)?,
    onPageMenu: (() -> Unit)?,
    modifier: Modifier = Modifier,
    onComments: (() -> Unit)? = null,
    // How far the title goes on after this chapter, such as 12 chapters left, said after its name.
    left: String? = null,
) {
    Row(modifier.fillMaxWidth().padding(vertical = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        BackButton(onBack)
        Column(Modifier.weight(1f).padding(start = 4.dp)) {
            Text(
                state.chapterName ?: numberedUnit(state.kind, state.chapterNumber),
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.SemiBold,
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
            )
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    if (left == null) state.titleName else "${state.titleName}  ·  $left",
                    Modifier.weight(1f, fill = false),
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
                if (state.settings.incognito) IncognitoMark()
            }
        }
        IconButton(onBookmark) {
            Icon(
                if (state.bookmarked) Icons.Filled.Bookmark else Icons.Outlined.BookmarkBorder,
                stringResource(if (state.bookmarked) Res.string.bookmark_remove else Res.string.bookmark_add),
                tint = if (state.bookmarked) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurfaceVariant,
            )
        }
        if (onComments != null) {
            IconButton(onComments) { Icon(Icons.AutoMirrored.Outlined.Comment, stringResource(Res.string.comments_chapter_title)) }
        }
        // The rest opens in the dock with the actions of the page, or, for words that have no page actions, goes straight to the website.
        when {
            onPageMenu != null -> IconButton(onPageMenu) { Icon(Icons.Outlined.MoreVert, stringResource(Res.string.more)) }
            onOpenBrowser != null -> IconButton(onOpenBrowser) { Icon(Icons.AutoMirrored.Outlined.OpenInNew, stringResource(Res.string.reader_open_browser)) }
        }
    }
}

// A small round mark with a crossed eye, for a reader that keeps no progress.
@Composable
private fun IncognitoMark() {
    Box(
        Modifier.size(18.dp).background(MaterialTheme.colorScheme.tertiaryContainer, CircleShape),
        contentAlignment = Alignment.Center,
    ) {
        Icon(
            Icons.Outlined.VisibilityOff,
            stringResource(Res.string.reader_incognito),
            Modifier.size(12.dp),
            tint = MaterialTheme.colorScheme.onTertiaryContainer,
        )
    }
}

