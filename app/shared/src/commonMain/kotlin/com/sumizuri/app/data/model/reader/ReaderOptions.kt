package com.sumizuri.app.data.model.reader

import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_controls_island
import com.sumizuri.app.shared.resources.reader_controls_island_top
import com.sumizuri.app.shared.resources.reader_lookup_auto
import com.sumizuri.app.shared.resources.reader_lookup_english
import com.sumizuri.app.shared.resources.reader_lookup_japanese
import com.sumizuri.app.shared.resources.reader_lookup_off
import com.sumizuri.app.shared.resources.reader_mode_continuous
import com.sumizuri.app.shared.resources.reader_mode_ltr
import com.sumizuri.app.shared.resources.reader_mode_rtl
import com.sumizuri.app.shared.resources.reader_mode_vertical
import com.sumizuri.app.shared.resources.reader_progress_horizontal
import com.sumizuri.app.shared.resources.reader_progress_vertical
import com.sumizuri.app.shared.resources.reader_quality_balanced
import com.sumizuri.app.shared.resources.reader_quality_best
import com.sumizuri.app.shared.resources.reader_quality_light
import org.jetbrains.compose.resources.StringResource

// How the pages of a chapter are laid out, as one long scroll or as pages turned one after another.
enum class ReaderMode(val label: StringResource) {
    Continuous(Res.string.reader_mode_continuous),
    RightToLeft(Res.string.reader_mode_rtl),
    LeftToRight(Res.string.reader_mode_ltr),
    Vertical(Res.string.reader_mode_vertical),
}

// How sharp pages are kept in memory. A page wider than the limit is brought down to it as it is read, which saves memory on a phone. A null limit keeps every page as it came.
enum class ReaderQuality(val label: StringResource, val maxWidth: Int?) {
    Best(Res.string.reader_quality_best, null),
    Balanced(Res.string.reader_quality_balanced, 2160),
    Light(Res.string.reader_quality_light, 1440),
}

// Where the island with the controls of the reader sits: at the bottom, near the thumb, or at the top.
enum class ReaderControls(val label: StringResource) {
    Island(Res.string.reader_controls_island),
    IslandTop(Res.string.reader_controls_island_top),
}

// Where the slider to jump through a chapter is: along the bottom bar, or down the edge of the screen.
enum class ReaderProgressBar(val label: StringResource) {
    Horizontal(Res.string.reader_progress_horizontal),
    Vertical(Res.string.reader_progress_vertical),
}

// What a long press on a word of a novel does: nothing, or a dictionary lookup in the language of the word or in one that was picked.
enum class ReaderLookup(val label: StringResource) {
    Off(Res.string.reader_lookup_off),
    Auto(Res.string.reader_lookup_auto),
    English(Res.string.reader_lookup_english),
    Japanese(Res.string.reader_lookup_japanese),
}
