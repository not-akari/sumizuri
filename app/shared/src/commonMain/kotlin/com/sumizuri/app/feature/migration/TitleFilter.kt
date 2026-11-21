package com.sumizuri.app.feature.migration

import com.sumizuri.app.data.migration.MigrationItem
import com.sumizuri.app.data.model.Kind

// Which of the titles the list shows: by a word in the name, by kind, by a shelf, and only the picked ones when asked.
internal data class TitleFilter(
    val query: String = "",
    val kind: Kind? = null,
    val shelf: Long? = null,
    val pickedOnly: Boolean = false,
) {
    fun matches(item: MigrationItem): Boolean = (kind == null || item.title.kind == kind) &&
        (shelf == null || shelf in item.shelves) &&
        (!pickedOnly || item.included) &&
        (query.isBlank() || item.title.name.contains(query.trim(), ignoreCase = true))
}
