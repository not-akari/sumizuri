package com.sumizuri.app.ui.theme.spec

// Colors of a role set in one mode, from the six numbers a preset gives.
private fun colors(surface: Long, primary: Long, container: Long, secondary: Long, tertiary: Long, error: Long) =
    ThemeColors(
        primary = primary or 0xFF000000,
        primaryContainer = container or 0xFF000000,
        secondary = secondary or 0xFF000000,
        tertiary = tertiary or 0xFF000000,
        error = error or 0xFF000000,
        surface = surface or 0xFF000000,
    )

// Every corner of every piece at one size, for the square looks of print.
private fun squareShapes(size: Float) = shapesOf(ShapeCharacter.Sharp).let { base ->
    val each = ShapeSpec(ShapeStyle.Uniform, size)
    base.copy(card = each, item = each, cover = each, button = each, chip = each, iconTile = each, dialog = each, navBar = each, sheetRadius = size)
}

// Corners larger than the round look, for the soft glowing looks of the night.
private fun pillowShapes() = ThemeShapes(
    card = ShapeSpec(ShapeStyle.Uniform, 22f),
    item = ShapeSpec(ShapeStyle.Uniform, 18f),
    cover = ShapeSpec(ShapeStyle.Uniform, 14f),
    button = ShapeSpec(ShapeStyle.Pill, 0f),
    chip = ShapeSpec(ShapeStyle.Pill, 0f),
    iconTile = ShapeSpec(ShapeStyle.Uniform, 14f),
    dialog = ShapeSpec(ShapeStyle.Uniform, 28f),
    sheetRadius = 28f,
)

// A background of one style that lies still, so no preset moves behind its pages.
private fun backdrop(style: BackgroundStyle, count: Int = 4, vignette: Float = 0f, ring: Boolean = true) =
    ThemeBackground(style = style, speed = 0f, count = count, vignette = vignette, ring = ring)

// The themes that come with the app. Each has a character of its own beyond its colors: its corners, its still background, its room and its covers, all in the font of the app. Sumizuri is the first and the one the app starts with. A TV keeps every background still.
val ThemePresets: List<AppThemeSpec> = listOf(
    // Sumizuri: moonlight over sumi ink, the colors of the icon. Round with calm waves.
    AppThemeSpec(
        AppThemeSpec.DefaultId,
        "Sumizuri",
        light = colors(0xF2F3F6, 0x343A4A, 0xECE5C2, 0x4E5260, 0x6B6A80, 0xB3261E),
        dark = colors(0x0F1114, 0xE8E0B0, 0x2C2F38, 0xB9BFCC, 0x9AA6C2, 0xE58592),
        options = ThemeOptions(background = backdrop(BackgroundStyle.Waves)),
    ),
    // Shikkoku: black lacquer, gold leaf and a touch of crimson. Sharp corners, gold brush strokes and covers that cast a shadow.
    AppThemeSpec(
        "builtin:shikkoku",
        "Shikkoku",
        light = colors(0xF1F1F3, 0x7A5A12, 0xEADFC4, 0x4A4436, 0x9E2B3A, 0xB3261E),
        dark = colors(0x0B0A08, 0xE2B659, 0x3A2E10, 0xC9BFA8, 0xD64550, 0xF2A3A0),
        shapes = shapesOf(ShapeCharacter.Sharp),
        options = ThemeOptions(
            background = backdrop(BackgroundStyle.Strokes, count = 3),
            covers = ThemeCovers(badgeStyle = CoverBadgeStyle.Pill, progressStyle = ProgressStyle.Solid),
            effects = ThemeEffects(coverShadow = true),
        ),
    ),
    // Yuki: a quiet snowfall. Cool white and ice blue with a hint of lavender, soft corners, falling flakes and more room.
    AppThemeSpec(
        "builtin:yuki",
        "Yuki",
        light = colors(0xF2F6FA, 0x2F5D8A, 0xD7E5F3, 0x55606C, 0x7A5AA6, 0xB3261E),
        dark = colors(0x0E131A, 0xA8CBEB, 0x23384D, 0xBCC6D1, 0xC7B3EE, 0xF2A3A0),
        shapes = shapesOf(ShapeCharacter.Soft),
        options = ThemeOptions(
            layout = ThemeLayout(LayoutDensity.Comfortable, spacing = 1.15f),
            background = backdrop(BackgroundStyle.Dots, count = 5, ring = false),
        ),
    ),
    // Akihabara: neon signs on a night street. Pillowy corners, glowing orbs and round badges.
    AppThemeSpec(
        "builtin:akihabara",
        "Akihabara",
        light = colors(0xF4F2FA, 0xC2187A, 0xF8D5EA, 0x4B4A66, 0x007C91, 0xB3261E),
        dark = colors(0x0B0B14, 0xFF4FB0, 0x5C0E3E, 0xB9B8D6, 0x3BE0F0, 0xFF8A8A),
        shapes = pillowShapes(),
        options = ThemeOptions(
            background = backdrop(BackgroundStyle.Orbs, count = 5),
            covers = ThemeCovers(badgeStyle = CoverBadgeStyle.Circle),
        ),
    ),
    // Sakura: cherry blossom in spring. Leaf cut corners and a soft aurora of pink and green.
    AppThemeSpec(
        "builtin:sakura",
        "Sakura",
        light = colors(0xFBF3F4, 0xC2496B, 0xF9D9E2, 0x6E5A60, 0x5E7A4A, 0xB3261E),
        dark = colors(0x1A1215, 0xF48FB1, 0x5A2335, 0xD8BFC6, 0xA8C98F, 0xF2A3A0),
        shapes = shapesOf(ShapeCharacter.Leaf),
        options = ThemeOptions(background = backdrop(BackgroundStyle.Aurora)),
    ),
    // Matcha: a quiet tea room. Soft corners, calm waves and the most room of all.
    AppThemeSpec(
        "builtin:matcha",
        "Matcha",
        light = colors(0xF1F3EA, 0x4E7A2E, 0xDCE8C8, 0x55604A, 0x8A6A2E, 0xB3261E),
        dark = colors(0x11150E, 0xA9D17F, 0x2F4520, 0xBCC7AE, 0xD8B878, 0xF2A3A0),
        shapes = shapesOf(ShapeCharacter.Soft),
        options = ThemeOptions(
            layout = ThemeLayout(LayoutDensity.Spacious),
            background = backdrop(BackgroundStyle.Waves),
        ),
    ),
    // Ukiyo: a woodblock print of the great wave. Square corners and Prussian blue and ochre strokes.
    AppThemeSpec(
        "builtin:ukiyo",
        "Ukiyo",
        light = colors(0xEEF2F7, 0x1F4E8C, 0xD6E1F2, 0x4A4F5C, 0x9A7414, 0xB3261E),
        dark = colors(0x0D1420, 0x8DB4F0, 0x1C3A66, 0xB7C0D1, 0xE8C25C, 0xF2A3A0),
        shapes = squareShapes(3f),
        options = ThemeOptions(
            background = backdrop(BackgroundStyle.Strokes),
        ),
    ),
    // Shinbun: the morning paper. Square corners, a plain page, tight rows and one red for what matters.
    AppThemeSpec(
        "builtin:shinbun",
        "Shinbun",
        light = colors(0xF2F2EF, 0x1A1A1A, 0xDCDCD8, 0x4F4F4F, 0x9A1C1C, 0xB3261E),
        dark = colors(0x111111, 0xEDEDED, 0x3A3A3A, 0xB5B5B5, 0xE06666, 0xF2A3A0),
        shapes = squareShapes(1f),
        options = ThemeOptions(
            layout = ThemeLayout(LayoutDensity.Compact),
            background = backdrop(BackgroundStyle.Dots, count = 2, ring = false),
            covers = ThemeCovers(badgeStyle = CoverBadgeStyle.Pill, progressStyle = ProgressStyle.Solid, coverBorder = false),
        ),
    ),
    // Yugure: dusk, violet into amber, as an aurora behind round corners.
    AppThemeSpec(
        "builtin:yugure",
        "Yugure",
        light = colors(0xF3F0F9, 0x5B43B8, 0xE3DCF8, 0x5B5670, 0x8A4B14, 0xB3261E),
        dark = colors(0x120F1C, 0xB7A1FF, 0x342766, 0xC5BED9, 0xFFB77A, 0xF2A3A0),
        options = ThemeOptions(background = backdrop(BackgroundStyle.Aurora)),
    ),
    // Gekijou: a theater before the film. Red velvet and warm brass, dark edges like a screen, and title pages in the colors of their covers.
    AppThemeSpec(
        "builtin:gekijou",
        "Gekijou",
        light = colors(0xF4F2F3, 0x8E1B2B, 0xF3D6D9, 0x5A4A4C, 0x8A6A2E, 0xB3261E),
        dark = colors(0x0D0A0B, 0xFF8A93, 0x5A1520, 0xD6C2C4, 0xE2C07A, 0xF2A3A0),
        options = ThemeOptions(
            background = backdrop(BackgroundStyle.Ink, vignette = 0.6f),
            pageColors = ThemePageColors(mode = CoverColorMode.Tinted),
            effects = ThemeEffects(coverShadow = true),
        ),
    ),
    // Shinkai: the deep sea at night. Dark teal water, pillowy corners and orbs like light from far above, with the violet glow of jellyfish.
    AppThemeSpec(
        "builtin:shinkai",
        "Shinkai",
        light = colors(0xEFF4F4, 0x0E6A73, 0xCBE7E8, 0x4A5A5C, 0x6A4FB5, 0xB3261E),
        dark = colors(0x081216, 0x6FD6DF, 0x0F3F46, 0xB6C9CB, 0xB39DFF, 0xF2A3A0),
        shapes = pillowShapes(),
        options = ThemeOptions(background = backdrop(BackgroundStyle.Orbs)),
    ),
    // Hotaru: fireflies over a summer forest. Soft corners and small lights in the dark.
    AppThemeSpec(
        "builtin:hotaru",
        "Hotaru",
        light = colors(0xF1F4EC, 0x5C6E12, 0xE3ECC2, 0x50573F, 0x2E6E8A, 0xB3261E),
        dark = colors(0x0B100A, 0xD4F06A, 0x33401A, 0xC2CBB0, 0x8FD3F0, 0xF2A3A0),
        shapes = shapesOf(ShapeCharacter.Soft),
        options = ThemeOptions(background = backdrop(BackgroundStyle.Dots, count = 6)),
    ),
)
