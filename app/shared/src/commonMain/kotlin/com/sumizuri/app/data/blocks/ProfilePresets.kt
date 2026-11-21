package com.sumizuri.app.data.blocks

import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.block_label_added
import com.sumizuri.app.shared.resources.block_label_authors
import com.sumizuri.app.shared.resources.block_label_days
import com.sumizuri.app.shared.resources.block_label_favorites
import com.sumizuri.app.shared.resources.block_label_hours
import com.sumizuri.app.shared.resources.block_label_kinds
import com.sumizuri.app.shared.resources.block_label_library
import com.sumizuri.app.shared.resources.block_label_month
import com.sumizuri.app.shared.resources.block_label_months
import com.sumizuri.app.shared.resources.block_label_reading
import com.sumizuri.app.shared.resources.block_label_status
import com.sumizuri.app.shared.resources.block_label_unread
import com.sumizuri.app.shared.resources.block_label_week
import com.sumizuri.app.shared.resources.preset_classic
import com.sumizuri.app.shared.resources.preset_classic_about
import com.sumizuri.app.shared.resources.preset_collector
import com.sumizuri.app.shared.resources.preset_collector_about
import com.sumizuri.app.shared.resources.preset_goals
import com.sumizuri.app.shared.resources.preset_goals_about
import com.sumizuri.app.shared.resources.preset_insights
import com.sumizuri.app.shared.resources.preset_insights_about
import com.sumizuri.app.shared.resources.preset_minimal
import com.sumizuri.app.shared.resources.preset_minimal_about
import com.sumizuri.app.shared.resources.preset_overview
import com.sumizuri.app.shared.resources.preset_overview_about
import com.sumizuri.app.shared.resources.preset_reader
import com.sumizuri.app.shared.resources.preset_reader_about
import com.sumizuri.app.shared.resources.stats_longest_streak
import com.sumizuri.app.shared.resources.stats_today
import org.jetbrains.compose.resources.StringResource
import org.jetbrains.compose.resources.getString

// A block of a preset: the size it takes, where a height of 0 fits its content, and how its script is made, in the language of the app at the time.
class PresetPart(val w: Int, val h: Int, val script: suspend () -> String)

// A block of a preset that starts from a template.
private fun part(template: BlockTemplate, w: Int = 4, h: Int = 0) = PresetPart(w, h) { template.script() }

// A block of a preset made like the simple editor makes one, with its label in the language of the app.
private fun simple(label: StringResource, w: Int = 4, h: Int = 0, block: (String) -> SimpleBlock) =
    PresetPart(w, h) { block(getString(label)).script() }

// Whole profile pages to start from. Classic is the page as it came. Choosing one replaces the blocks of the page.
enum class ProfilePreset(val label: StringResource, val about: StringResource, val parts: List<PresetPart>) {
    Classic(Res.string.preset_classic, Res.string.preset_classic_about, emptyList()),

    Overview(
        Res.string.preset_overview,
        Res.string.preset_overview_about,
        listOf(
            part(BlockTemplate.Streak, 2, 1),
            simple(Res.string.stats_today, 2, 1) { SimpleBlock(value = "stats.today", label = it) },
            simple(Res.string.block_label_week, 2, 1) { SimpleBlock(value = "stats.week", label = it) },
            part(BlockTemplate.Pace, 2, 1),
            part(BlockTemplate.Continue),
            part(BlockTemplate.Heatmap),
            part(BlockTemplate.Genres),
        ),
    ),

    Reader(
        Res.string.preset_reader,
        Res.string.preset_reader_about,
        listOf(
            part(BlockTemplate.Continue),
            part(BlockTemplate.Recent),
            part(BlockTemplate.MostRead),
            part(BlockTemplate.Heatmap),
        ),
    ),

    Minimal(
        Res.string.preset_minimal,
        Res.string.preset_minimal_about,
        listOf(
            part(BlockTemplate.Continue),
            part(BlockTemplate.Streak, 2, 1),
            part(BlockTemplate.Finished, 2, 1),
        ),
    ),

    Goals(
        Res.string.preset_goals,
        Res.string.preset_goals_about,
        listOf(
            simple(
                Res.string.stats_today,
                2,
                2,
            ) { SimpleBlock(show = "ring", value = "stats.today", goal = 10.0, label = it) },
            simple(
                Res.string.block_label_week,
                2,
                2,
            ) { SimpleBlock(show = "ring", value = "stats.week", goal = 50.0, label = it) },
            simple(Res.string.block_label_month, 4, 1) {
                SimpleBlock(show = "bar", value = "stats.month", goal = 200.0, label = it)
            },
            part(BlockTemplate.Streak, 2, 1),
            simple(Res.string.stats_longest_streak, 2, 1) { SimpleBlock(value = "stats.best", label = it) },
            part(BlockTemplate.Weekdays),
        ),
    ),

    Insights(
        Res.string.preset_insights,
        Res.string.preset_insights_about,
        listOf(
            part(BlockTemplate.Pace, 2, 1),
            simple(Res.string.block_label_days, 2, 1) { SimpleBlock(value = "stats.days", label = it) },
            simple(Res.string.block_label_hours) {
                SimpleBlock(show = "chart", source = "reads", by = "hour", days = 90, style = "area", label = it)
            },
            simple(Res.string.block_label_months) {
                SimpleBlock(show = "chart", source = "reads", by = "month", days = 365, style = "bars", label = it)
            },
            simple(Res.string.block_label_kinds) {
                SimpleBlock(
                    show = "chart",
                    source = "reads",
                    by = "kind",
                    days = 0,
                    top = 0,
                    style = "donut",
                    label = it,
                )
            },
            part(BlockTemplate.MostRead),
        ),
    ),

    Collector(
        Res.string.preset_collector,
        Res.string.preset_collector_about,
        listOf(
            simple(Res.string.block_label_library, 2, 1) { SimpleBlock(value = "stats.library", label = it) },
            simple(Res.string.block_label_favorites, 2, 1) { SimpleBlock(value = "stats.favorites", label = it) },
            simple(Res.string.block_label_reading, 2, 1) { SimpleBlock(value = "reading", label = it) },
            simple(Res.string.block_label_unread, 2, 1) { SimpleBlock(value = "stats.unread", label = it) },
            simple(
                Res.string.block_label_added,
            ) { SimpleBlock(show = "covers", titles = "added", count = 12, label = it) },
            simple(Res.string.block_label_status) {
                SimpleBlock(show = "chart", source = "library", by = "status", top = 0, style = "pie", label = it)
            },
            simple(Res.string.block_label_authors) {
                SimpleBlock(show = "list", source = "library", by = "author", top = 5, label = it)
            },
        ),
    ),
    ;

    // The page of the preset. Classic gives the page as it came, with the blocks it always had.
    suspend fun layout(): BlockLayout = if (this == Classic) {
        defaultLayout()
    } else {
        BlockLayout(blocks = parts.map { ProfileBlock(newBlockId(), it.w, it.h, it.script()) })
    }
}
