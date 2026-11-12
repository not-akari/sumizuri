package com.sumizuri.app.data.model.reader

import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_align_justify
import com.sumizuri.app.shared.resources.reader_align_left
import com.sumizuri.app.shared.resources.reader_bg_black
import com.sumizuri.app.shared.resources.reader_bg_dark
import com.sumizuri.app.shared.resources.reader_bg_sepia
import com.sumizuri.app.shared.resources.reader_bg_theme
import com.sumizuri.app.shared.resources.reader_bg_white
import com.sumizuri.app.shared.resources.reader_dual_cover
import com.sumizuri.app.shared.resources.reader_dual_off
import com.sumizuri.app.shared.resources.reader_dual_on
import com.sumizuri.app.shared.resources.reader_font_dyslexic
import com.sumizuri.app.shared.resources.reader_font_system
import com.sumizuri.app.shared.resources.reader_orientation_free
import com.sumizuri.app.shared.resources.reader_orientation_landscape
import com.sumizuri.app.shared.resources.reader_orientation_portrait
import com.sumizuri.app.shared.resources.reader_scale_height
import com.sumizuri.app.shared.resources.reader_scale_original
import com.sumizuri.app.shared.resources.reader_scale_screen
import com.sumizuri.app.shared.resources.reader_scale_width
import com.sumizuri.app.shared.resources.reader_size_custom
import com.sumizuri.app.shared.resources.reader_size_full
import com.sumizuri.app.shared.resources.reader_size_large
import com.sumizuri.app.shared.resources.reader_size_medium
import com.sumizuri.app.shared.resources.reader_size_none
import com.sumizuri.app.shared.resources.reader_size_small
import com.sumizuri.app.shared.resources.reader_turn_fade
import com.sumizuri.app.shared.resources.reader_turn_flip
import com.sumizuri.app.shared.resources.reader_turn_slide
import com.sumizuri.app.shared.resources.reader_turn_stack
import com.sumizuri.app.shared.resources.reader_turn_zoom
import com.sumizuri.app.shared.resources.reader_zoom_auto
import com.sumizuri.app.shared.resources.reader_zoom_center
import com.sumizuri.app.shared.resources.reader_zoom_left
import com.sumizuri.app.shared.resources.reader_zoom_right
import org.jetbrains.compose.resources.StringResource

// How a page is sized in a turned page layout.
enum class ReaderScale(val label: StringResource) {
    Screen(Res.string.reader_scale_screen),
    Width(Res.string.reader_scale_width),
    Height(Res.string.reader_scale_height),
    Original(Res.string.reader_scale_original),
}

// What is behind the pages. A null color means the color of the app theme, and dark says whether text on it is light.
enum class ReaderBackground(val label: StringResource, val color: Long?, val dark: Boolean) {
    Theme(Res.string.reader_bg_theme, null, false),
    Black(Res.string.reader_bg_black, 0xFF000000, true),
    Dark(Res.string.reader_bg_dark, 0xFF1B1B1F, true),
    White(Res.string.reader_bg_white, 0xFFFFFFFF, false),
    Sepia(Res.string.reader_bg_sepia, 0xFFF2E6CE, false),
}

// The space between pages in the long scroll, in dp.
enum class ReaderGap(val label: StringResource, val dp: Int) {
    None(Res.string.reader_size_none, 0),
    Small(Res.string.reader_size_small, 4),
    Medium(Res.string.reader_size_medium, 8),
    Large(Res.string.reader_size_large, 16),
}

// The widest the long scroll grows, in dp, or null for the whole window. Custom takes the width the person set.
enum class ReaderWidth(val label: StringResource, val dp: Int?) {
    Small(Res.string.reader_size_small, 600),
    Medium(Res.string.reader_size_medium, 720),
    Large(Res.string.reader_size_large, 1000),
    Full(Res.string.reader_size_full, null),
    Custom(Res.string.reader_size_custom, null),
    ;

    // The widest the long scroll grows with this choice, the own width for Custom.
    fun widest(custom: Int): Int? = if (this == Custom) custom.coerceIn(CustomLeast, CustomMost) else dp

    companion object {
        const val CustomLeast = 400
        const val CustomMost = 1600
    }
}

// Whether two pages share one screen, and whether the first page stands alone as a cover.
enum class ReaderDual(val label: StringResource) {
    Off(Res.string.reader_dual_off),
    On(Res.string.reader_dual_on),
    Cover(Res.string.reader_dual_cover),
}

// The typeface of text in a chapter that is words. OpenDyslexic is built for readers with dyslexia.
enum class ReaderFont(val label: StringResource) {
    System(Res.string.reader_font_system),
    OpenDyslexic(Res.string.reader_font_dyslexic),
}

// How the phone is held while the reader is open. Free follows the phone, and the others keep the screen upright or on its side.
enum class ReaderOrientation(val label: StringResource) {
    Free(Res.string.reader_orientation_free),
    Portrait(Res.string.reader_orientation_portrait),
    Landscape(Res.string.reader_orientation_landscape),
}

// Where a page that is wider than the screen starts. Auto starts at the side the book begins on, the right for a book that reads right to left.
enum class ReaderZoomStart(val label: StringResource) {
    Auto(Res.string.reader_zoom_auto),
    Left(Res.string.reader_zoom_left),
    Center(Res.string.reader_zoom_center),
    Right(Res.string.reader_zoom_right),
}

// How lines of text end on the right.
enum class ReaderTextAlign(val label: StringResource) {
    Left(Res.string.reader_align_left),
    Justify(Res.string.reader_align_justify),
}

// How a page moves as it turns in the paged modes: it slides, fades, the next one comes over it, it flips like a card, or it shrinks away.
enum class ReaderPageTurn(val label: StringResource) {
    Slide(Res.string.reader_turn_slide),
    Fade(Res.string.reader_turn_fade),
    Stack(Res.string.reader_turn_stack),
    Flip(Res.string.reader_turn_flip),
    Zoom(Res.string.reader_turn_zoom),
}
