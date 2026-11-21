package com.sumizuri.app.ui.theme.spec

import kotlinx.serialization.Serializable

// Everything about a theme besides its colors and corners, in one part for each place it shows.
@Serializable
data class ThemeOptions(
    val typography: ThemeTypography = ThemeTypography(),
    val layout: ThemeLayout = ThemeLayout(),
    val effects: ThemeEffects = ThemeEffects(),
    val components: ThemeComponents = ThemeComponents(),
    val covers: ThemeCovers = ThemeCovers(),
    val controls: ThemeControls = ThemeControls(),
    val motion: ThemeMotion = ThemeMotion(),
    val background: ThemeBackground = ThemeBackground(),
    val pageColors: ThemePageColors = ThemePageColors(),
    val accentFrom: AccentSource = AccentSource.Theme,
)

// How the page of a title takes its colors from the cover. The first values tint the page lightly, as the app always did.
@Serializable
data class ThemePageColors(
    // The page keeps the background and cards of the theme, and only its accents follow the cover, so it matches every other page.
    val mode: CoverColorMode = CoverColorMode.Accent,
    // How far the page and the cards lean toward the cover, from not at all to two and a half times the usual.
    val strength: Float = 1f,
    // How many colors of the cover are used, from the main one alone to three.
    val colors: Int = 3,
    // How strong the colors of the cover are made, from calm to vivid.
    val vibrance: Float = 1f,
    // Whether the dots, bars and bookmarks of the chapters take the colors of the cover.
    val chapterMarks: Boolean = true,
)

// The moving page behind every screen. How strong it is stays the glow of the effects, so older themes keep theirs. The first values draw the ink the app has always had.
@Serializable
data class ThemeBackground(
    val style: BackgroundStyle = BackgroundStyle.Ink,
    // How fast it moves, from still at 0 to three times as fast.
    val speed: Float = 1f,
    // How many times a second it moves on. The whole window is drawn again each time, so fewer steps spare the graphics card, and the slow motion of a background looks the same at a few.
    val fps: Int = 5,
    // How strong it is on pages opened over the tabs, such as the page of a title or of the settings, against the tabs, and whether it stands still on them.
    val pageStrength: Float = 1f,
    val pagesStill: Boolean = false,
    // How far each shape wanders from its place, from not at all to twice as far.
    val drift: Float = 1f,
    // How large the shapes are against the page.
    val scale: Float = 1f,
    // How many shapes there are.
    val count: Int = 4,
    val palette: BackgroundPalette = BackgroundPalette.Accents,
    // The colors of the own palette as 0xAARRGGBB numbers, used in turn.
    val colors: List<Long> = emptyList(),
    // The thin ring like the one on the icon, turning very slowly.
    val ring: Boolean = true,
    // How much the edges of the page are shaded, from none to deep.
    val vignette: Float = 0f,
)

// How things move: how much a piece grows when the pointer is over it, how much it shrinks while it is pressed, and how fast pages and parts change, from half speed to double.
@Serializable
data class ThemeMotion(
    val hoverScale: Float = 1.02f,
    val pressScale: Float = 0.96f,
    val transitionSpeed: Float = 1f,
    // The cover behind the page of a title drifts and zooms slowly, as in a film. Off by itself, since it draws all the time.
    val coverDrift: Boolean = false,
)

// How a cover, the count of unread chapters on it and the bar of how far it is read look. The corner the count sits in, and whether the bar shows at all, are chosen with the display of the library.
@Serializable
data class ThemeCovers(
    val aspect: CoverAspect = CoverAspect.Tall,
    // How many lines of the name show under a cover.
    val titleLines: Int = 2,
    val badgeStyle: CoverBadgeStyle = CoverBadgeStyle.Tilted,
    val coverBorder: Boolean = true,
    val progressStyle: ProgressStyle = ProgressStyle.Gradient,
    // How thick the bar is, in dp.
    val progressHeight: Float = 4f,
    // A bar that floats a little above the bottom edge and in from the sides, instead of lying along the edge.
    val progressFloating: Boolean = false,
)
