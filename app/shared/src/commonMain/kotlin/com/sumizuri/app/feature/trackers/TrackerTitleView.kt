package com.sumizuri.app.feature.trackers

import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import com.sumizuri.app.data.db.tracker.LibraryTitle
import com.sumizuri.app.data.db.tracker.TrackerLinkEntity
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.tracker.TrackerAccount
import com.sumizuri.app.data.tracker.TrackerId

// Which titles of the library with no link a list holds.
internal enum class LibraryList { Unlinked, NotFound, LeftOut }

// Linked titles narrowed and ordered by the tools over them, or the bar of what to do while some are picked.
@Composable
internal fun LinkedView(tracker: TrackerId, account: TrackerAccount, links: List<TrackerLinkEntity>, key: String) {
    val tools = rememberTitleTools(tracker)
    // Picks belong to one list, so going to another lets go of them.
    val picking = remember(tracker, key) { Picking() }
    val shown = remember(links, tools.key) { tools.links(links) }
    if (picking.on) {
        PickBar(tracker, picking, shown.map { it.titleId }, PickActions.Linked, pickKind(tracker, tools))
    } else {
        TitleToolsBar(tools, kindsOf(links.map { it.kind }), statusCounts(links.map { it.status }), TitleSort.entries)
    }
    LinkedTitles(tracker, account, shown, key, picking, narrowed = shown.size != links.size)
}

// Titles of the library with no link, narrowed by the tools, in one of the lists that hold them.
@Composable
internal fun LibraryView(tracker: TrackerId, titles: List<LibraryTitle>, list: LibraryList) {
    val tools = rememberTitleTools(tracker)
    val picking = remember(tracker, list) { Picking() }
    val shown = remember(titles, tools.key) { tools.titles(titles) }
    val actions = if (list == LibraryList.LeftOut) PickActions.LeftOut else PickActions.Unlinked
    if (picking.on) {
        PickBar(tracker, picking, shown.map { it.id }, actions, pickKind(tracker, tools))
    } else if (titles.isNotEmpty()) {
        TitleToolsBar(tools, kindsOf(titles.map { it.kind }), null, listOf(TitleSort.Name))
    }
    when (list) {
        LibraryList.LeftOut -> LeftOutTitles(tracker, shown, picking)
        LibraryList.NotFound -> UnlinkedTitles(tracker, shown, notFound = true, picking)
        LibraryList.Unlinked -> UnlinkedTitles(tracker, shown, notFound = false, picking)
    }
}

// The kind the words of the statuses follow, such as Watching for shows.
internal fun pickKind(tracker: TrackerId, tools: TitleTools): Kind =
    tools.kind ?: tracker.kinds.singleOrNull() ?: Kind.Manga

internal fun kindsOf(codes: List<Int>): Set<Kind> = codes.toSet().map(Kind::fromCode).toSet()
