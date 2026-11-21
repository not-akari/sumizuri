package com.sumizuri.app.feature.library.shelves

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.Status
import com.sumizuri.app.data.model.library.Category
import com.sumizuri.app.data.model.library.SortRule
import com.sumizuri.app.data.model.library.shelf.ShelfCondition

// Everything the page of a shelf can change, handed over together when it is saved.
internal class ShelfEdit(
    val name: String,
    val exclude: Boolean,
    val kind: Kind?,
    val rule: SortRule?,
    val status: Status?,
    val conditions: List<ShelfCondition>,
    val matchAll: Boolean,
) {
    // Whether anything here is not what the shelf has now.
    fun differsFrom(shelf: Category): Boolean =
        name.trim() != shelf.name || exclude != shelf.excludeFromUpdate || kind != shelf.kind || rule != shelf.rule ||
            status != shelf.status || conditions != shelf.conditions || matchAll != shelf.matchAll
}

// What the page of the shelves can ask for.
internal class ShelfCalls(
    val onAdd: (String, Kind?) -> Unit,
    val onReorder: (List<Long>) -> Unit,
    // Opens the page of one shelf.
    val onEdit: (Long) -> Unit,
)
