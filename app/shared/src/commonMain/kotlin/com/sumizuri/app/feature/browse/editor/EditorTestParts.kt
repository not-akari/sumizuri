package com.sumizuri.app.feature.browse.editor

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.itemsIndexed
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil3.compose.AsyncImage
import com.sumizuri.app.feature.comments.sortLabel
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapters_count
import com.sumizuri.app.shared.resources.ext_edit_list_end
import com.sumizuri.app.shared.resources.ext_edit_list_page
import com.sumizuri.app.shared.resources.ext_edit_load_page
import com.sumizuri.app.shared.resources.ext_edit_more_pages
import com.sumizuri.app.shared.resources.ext_edit_pages
import com.sumizuri.app.shared.resources.ext_edit_titles
import com.sumizuri.app.source.model.CommentSort
import com.sumizuri.app.source.model.SourceComment
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.ui.kit.art.InkOutlinedButton
import com.sumizuri.app.ui.kit.image.imageRequest
import com.sumizuri.app.ui.kit.input.BackButton
import com.sumizuri.app.ui.text.agoText
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource
import com.sumizuri.app.ui.kit.chips.SoftChip

// A list of titles, with a button for its next page until a page comes back empty or the same as the one before.
internal fun LazyListScope.listPart(test: ExtensionTest, idle: Boolean, back: (() -> Unit)?, actions: ExtensionEditorActions) {
    item {
        val name = when {
            test.catalog != null -> test.catalog.name
            else -> test.list?.let { stringResource(it.label) }.orEmpty() + if (test.query.isNotEmpty()) " \"${test.query}\"" else ""
        }
        val count = pluralStringResource(Res.plurals.ext_edit_titles, test.entries.size, test.entries.size)
        PartHeader(name, if (test.page > 1) "$count · ${stringResource(Res.string.ext_edit_list_page, test.page)}" else count, back)
    }
    items(test.entries) { entry -> ResultRow(entry.title.ifBlank { "—" }, entry.url, entry.coverUrl, tall = true) { actions.onOpenEntry(entry) } }
    if (test.entries.isNotEmpty()) {
        item {
            if (test.ended) {
                Hint(stringResource(Res.string.ext_edit_list_end))
            } else {
                InkOutlinedButton(actions.onNextPage, Modifier.padding(vertical = 8.dp), enabled = idle) { Text(stringResource(Res.string.ext_edit_load_page, test.page + 1)) }
            }
        }
    }
}

// A title as the code gives its details, each value as it came so an empty one stands out, then the way to its comments, then its chapters.
internal fun LazyListScope.titlePart(entry: SourceEntry, test: ExtensionTest, idle: Boolean, back: (() -> Unit)?, actions: ExtensionEditorActions) {
    item { PartHeader(entry.title, pluralStringResource(Res.plurals.chapters_count, test.chapters.size, test.chapters.size), back) }
    item {
        Row(Modifier.padding(vertical = 4.dp), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
            Thumb(entry.coverUrl, 72.dp, 104.dp)
            SelectionContainer {
                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Field("url", entry.url)
                    Field("author", entry.author)
                    Field("status", entry.status)
                    Field("rating", entry.rating?.toString())
                    Field("genres", entry.genres.joinToString().ifEmpty { null })
                    Field("coverUrl", entry.coverUrl)
                    Field("description", entry.description?.take(240))
                }
            }
        }
    }
    item {
        InkOutlinedButton({ actions.onComments(CommentSort.Newest) }, Modifier.padding(vertical = 4.dp), enabled = idle) { Text(stringResource(TestStep.Comments.label)) }
    }
    items(test.chapters) { chapter ->
        val number = chapter.number?.let { if (it % 1.0 == 0.0) it.toLong().toString() else it.toString() }
        val title = listOfNotNull(number?.let { "#$it" }, chapter.title.ifBlank { null }).joinToString("  ").ifEmpty { "—" }
        val extra = listOfNotNull(chapter.scanlator, chapter.uploadedAt?.let { agoText(it) }, if (chapter.locked) "🔒" else null).joinToString(" · ")
        ResultRow(title, listOf(chapter.url, extra).filter { it.isNotEmpty() }.joinToString("  ·  ")) { actions.onOpenChapter(chapter) }
    }
}

// A chapter: its pictures as small previews with their addresses, the start of its words, or its videos, then the way to its comments.
internal fun LazyListScope.chapterPart(test: ExtensionTest, idle: Boolean, back: (() -> Unit)?, actions: ExtensionEditorActions) {
    item { PartHeader(test.chapter?.title.orEmpty(), pluralStringResource(Res.plurals.ext_edit_pages, test.pageCount, test.pageCount), back) }
    item {
        InkOutlinedButton({ actions.onChapterComments(CommentSort.Newest) }, Modifier.padding(vertical = 4.dp), enabled = idle) { Text(stringResource(TestStep.ChapterComments.label)) }
    }
    itemsIndexed(test.pages) { index, page ->
        Row(Modifier.fillMaxWidth().padding(vertical = 3.dp), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
            if (page.imageUrl != null) Thumb(page.imageUrl, 44.dp, 60.dp)
            SelectionContainer(Modifier.weight(1f)) {
                Text("${index + 1}  ${page.text}", style = MaterialTheme.typography.bodySmall, fontFamily = FontFamily.Monospace, fontSize = 11.sp, maxLines = 3, overflow = TextOverflow.Ellipsis)
            }
        }
    }
    if (test.pageCount > test.pages.size) item { Hint(stringResource(Res.string.ext_edit_more_pages, test.pageCount - test.pages.size)) }
}

// The comments of a title or a chapter, with the order they are asked in.
internal fun LazyListScope.commentsPart(of: String, comments: List<SourceComment>, sort: CommentSort, idle: Boolean, back: (() -> Unit)?, onSort: (CommentSort) -> Unit) {
    item { PartHeader(of, comments.size.toString(), back) }
    item {
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            for (order in CommentOrders) SoftChip(sort == order, { onSort(order) }, { Text(stringResource(sortLabel(order))) }, enabled = idle)
        }
    }
    items(comments) { comment ->
        Row(Modifier.fillMaxWidth().padding(vertical = 6.dp), horizontalArrangement = Arrangement.spacedBy(10.dp)) {
            Thumb(comment.avatarUrl, 32.dp, 32.dp)
            Column(Modifier.weight(1f)) {
                Text(listOfNotNull(comment.author.ifBlank { "—" }, comment.postedAt?.let { agoText(it) }).joinToString(" · "), style = MaterialTheme.typography.labelMedium, fontWeight = FontWeight.SemiBold)
                SelectionContainer { Text(comment.text.ifBlank { "—" }, style = MaterialTheme.typography.bodySmall, maxLines = 6, overflow = TextOverflow.Ellipsis) }
            }
        }
    }
}

// The name of a part with how many it has, and the way back to the part it was opened from.
@Composable
internal fun PartHeader(title: String, count: String, onBack: (() -> Unit)?) {
    Row(Modifier.fillMaxWidth().padding(bottom = 4.dp), verticalAlignment = Alignment.CenterVertically) {
        if (onBack != null) BackButton(onBack)
        Column(Modifier.weight(1f).padding(start = if (onBack == null) 0.dp else 4.dp)) {
            Text(title.ifBlank { "—" }, style = MaterialTheme.typography.titleSmall, fontWeight = FontWeight.SemiBold, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(count, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.outline)
        }
    }
}

// A row that opens what it names, with the address under the name and a small picture when there is one.
@Composable
internal fun ResultRow(title: String, url: String, imageUrl: String? = null, tall: Boolean = false, onClick: () -> Unit) {
    Row(Modifier.fillMaxWidth().clickable(onClick = onClick).padding(vertical = 6.dp, horizontal = 4.dp), horizontalArrangement = Arrangement.spacedBy(10.dp), verticalAlignment = Alignment.CenterVertically) {
        if (tall) Thumb(imageUrl, 36.dp, 52.dp)
        Column(Modifier.weight(1f)) {
            Text(title, style = MaterialTheme.typography.bodyMedium, maxLines = 1, overflow = TextOverflow.Ellipsis)
            Text(url, style = MaterialTheme.typography.bodySmall, fontFamily = FontFamily.Monospace, fontSize = 11.sp, color = MaterialTheme.colorScheme.outline, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
    }
}

// A small picture from the site, over a plain box that shows when there is none or it does not load, so a broken address is seen at once.
@Composable
internal fun Thumb(url: String?, width: Dp, height: Dp) {
    Box(Modifier.size(width, height).clip(RoundedCornerShape(6.dp)).background(MaterialTheme.colorScheme.surfaceContainerHighest)) {
        if (!url.isNullOrBlank()) AsyncImage(imageRequest(url, maxWidth = 240), null, Modifier.size(width, height), contentScale = ContentScale.Crop)
    }
}

// A value the code gave, with the name the code gives it, shown as a dash when the code left it out.
@Composable
internal fun Field(name: String, value: String?) {
    Text(
        "$name: ${value ?: "—"}",
        style = MaterialTheme.typography.bodySmall,
        fontFamily = FontFamily.Monospace,
        fontSize = 11.sp,
        color = if (value == null) MaterialTheme.colorScheme.outline else MaterialTheme.colorScheme.onSurface,
        maxLines = 4,
        overflow = TextOverflow.Ellipsis,
    )
}

@Composable
internal fun Hint(text: String) {
    Text(text, Modifier.padding(vertical = 8.dp), style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.outline)
}
