package com.sumizuri.app.data.library

import com.sumizuri.app.data.model.seasonOrder

// One season of a list: its key, its name, the seasons of the source it is made of, whether it is the first season the source left unnamed, and its items in order.
class SeasonSlice<T>(
    val key: String?,
    val name: String?,
    val keys: Set<String?>,
    val isFirst: Boolean,
    val items: List<T>,
) {
    val merged: Boolean get() = keys.size > 1
}

// The seasons of a list in their order, or nothing when there are fewer than two. Parts of one season that follow each other, such as Season 1 Part 1 and Part 2, are made one season named after it.
fun <T> seasonSlices(items: List<T>, season: (T) -> String?, name: (T) -> String?): List<SeasonSlice<T>> {
    val byKey = items.groupBy(season)
    if (byKey.size < 2) return emptyList()
    val order = seasonOrder(byKey.keys)
    val slices = order.keys.map { key ->
        val list = byKey.getValue(key)
        SeasonSlice(key, list.firstNotNullOfOrNull(name), setOf(key), key == null && order.noneIsFirst, list)
    }
    val joined = buildList<SeasonSlice<T>> {
        for (slice in slices) {
            val base = slice.name?.let(::partOf)
            val last = lastOrNull()
            val lastBase = last?.let { if (it.merged) it.name else it.name?.let(::partOf) }
            if (base != null && last != null && base.equals(lastBase, ignoreCase = true)) {
                this[size - 1] =
                    SeasonSlice(last.key, base, last.keys + slice.keys, last.isFirst, last.items + slice.items)
            } else {
                add(slice)
            }
        }
    }
    return joined.takeIf { it.size >= 2 }.orEmpty()
}
