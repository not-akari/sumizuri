package com.sumizuri.app.feature.lists

import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.lists.ListItem
import com.sumizuri.app.data.lists.ListTitle
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.model.library.LibraryPrefs

// Finds the library title of a title on a list by its key. Each name of the library is folded once, so a big library is not folded again on every change.
internal class LibraryMatch {
    private val keys = HashMap<Pair<String, Kind>, String>()

    fun byKey(titles: List<Title>): Map<String, Title> =
        titles.associateBy { keys.getOrPut(it.name to it.kind) { ListTitle(it.name, it.kind).key } }
}

// The title whose cover stands for a title on a list: the one in the library, or one made only to paint a cover with the first letter of the name.
internal fun ListItem.coverTitle(saved: Title?): Title =
    saved ?: Title(-id, title, kind, null, 0, Status.Unknown, "", inLibrary = false)

// The cover size and gap the person set for the library, so the grids of lists match it.
@Composable
internal fun libraryGrid(): LibraryPrefs {
    val prefs = LocalAppContainer.current.libraryPrefs
    val now by remember(prefs) { prefs.prefs }.collectAsStateWithLifecycle(LibraryPrefs())
    return now
}
