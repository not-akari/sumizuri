package com.sumizuri.app.feature.share

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.produceState
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.lists.ListSizeLimit
import com.sumizuri.app.data.lists.ListTitle
import com.sumizuri.app.data.lists.SharedList
import com.sumizuri.app.data.lists.sharedListOf
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.share.SharedThing
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.import_list_extra
import com.sumizuri.app.shared.resources.import_list_more
import com.sumizuri.app.shared.resources.list_shared_name
import com.sumizuri.app.shared.resources.titles_count
import com.sumizuri.app.ui.kit.cover.CoverArt
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource

// How many covers the preview shows before it says how many more there are, and how wide each is.
private const val PreviewTitles = 12
private val PreviewWidth = 84.dp

// A shared list read for its preview, with the covers of its first titles: the library cover for a title the person has, and a painted one for the rest.
private class Previewed(val list: SharedList, val covers: List<Title>)

// A shared list before it is saved, in the look of the list itself: its name, the line about it, how many titles, and the first covers with their names. The file is read and matched to the library away from the screen, as it can be big.
@OptIn(ExperimentalLayoutApi::class)
@Composable
internal fun SharedListPreview(thing: SharedThing) {
    val library = LocalAppContainer.current.library
    val shown by produceState<Previewed?>(null, thing) {
        val titles = library.library.first()
        value = withContext(Dispatchers.Default) {
            val list = sharedListOf(thing.data) ?: return@withContext null
            val saved = titles.associateBy { ListTitle(it.name, it.kind).key }
            val covers = list.titles.take(PreviewTitles).mapIndexed { index, item ->
                saved[item.title.key]
                    ?: Title(
                        -index - 1L,
                        item.title.name,
                        item.title.kind,
                        null,
                        0,
                        Status.Unknown,
                        "",
                        inLibrary = false,
                    )
            }
            Previewed(list, covers)
        }
    }
    val preview = shown ?: return
    val list = preview.list
    val colors = MaterialTheme.colorScheme
    Text(
        list.name.ifEmpty { stringResource(Res.string.list_shared_name) },
        style = MaterialTheme.typography.titleLarge,
        fontWeight = FontWeight.SemiBold,
    )
    if (list.about.isNotEmpty()) {
        Text(
            list.about,
            style = MaterialTheme.typography.bodyMedium,
            color = colors.onSurfaceVariant,
        )
    }
    Text(
        pluralStringResource(Res.plurals.titles_count, list.titles.size, list.titles.size),
        style = MaterialTheme.typography.bodySmall,
        color = colors.outline,
    )
    if (list.extra > 0) {
        Text(
            pluralStringResource(Res.plurals.import_list_extra, list.extra, list.extra, ListSizeLimit),
            style = MaterialTheme.typography.bodySmall,
            color = colors.error,
        )
    }
    FlowRow(
        Modifier.padding(top = 6.dp),
        horizontalArrangement = Arrangement.spacedBy(10.dp),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        for (cover in preview.covers) {
            Column(Modifier.width(PreviewWidth)) {
                CoverArt(cover, letterSize = 20)
                Text(
                    cover.name,
                    Modifier.padding(top = 4.dp),
                    style = MaterialTheme.typography.bodySmall,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                )
            }
        }
    }
    val more = list.titles.size - preview.covers.size
    if (more >
        0
    ) {
        Text(
            stringResource(Res.string.import_list_more, more),
            style = MaterialTheme.typography.bodySmall,
            color = colors.outline,
        )
    }
}
