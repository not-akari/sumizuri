package com.sumizuri.app.data.model.feed

import com.sumizuri.app.data.model.library.LibraryDisplayStyle
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.feed_row_cards
import com.sumizuri.app.shared.resources.feed_row_inbox
import com.sumizuri.app.shared.resources.feed_row_timeline
import com.sumizuri.app.shared.resources.updates_calendar
import com.sumizuri.app.shared.resources.updates_list
import com.sumizuri.app.shared.resources.updates_side_off
import org.jetbrains.compose.resources.StringResource

// How the rows of a feed are drawn when it is a list.
enum class FeedRowStyle(val label: StringResource) {
    // Each title a card.
    Cards(Res.string.feed_row_cards),

    // A line down the side with the days on it, and new chapters as chips.
    Timeline(Res.string.feed_row_timeline),

    // Dense rows like a mail inbox, with a dot on what is new.
    Inbox(Res.string.feed_row_inbox),
}

// What the updates page shows beside its list on a wide window.
enum class UpcomingSide(val label: StringResource) {
    Calendar(Res.string.updates_calendar),
    List(Res.string.updates_list),

    // Nothing, and what comes next opens from the button in the bar.
    Off(Res.string.updates_side_off),
}

// How a feed page looks and behaves, as the person set it.
data class FeedPrefs(
    val style: LibraryDisplayStyle = LibraryDisplayStyle.List,
    val rowStyle: FeedRowStyle = FeedRowStyle.Timeline,
    // A swipe on a row marks it read. Off, a swipe sideways changes the shelf.
    val swipeMarksRead: Boolean = false,
    val upcomingSide: UpcomingSide = UpcomingSide.Calendar,
)
