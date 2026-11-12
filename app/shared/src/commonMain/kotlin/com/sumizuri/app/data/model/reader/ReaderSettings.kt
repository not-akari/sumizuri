package com.sumizuri.app.data.model.reader

// Every choice of the reader. The mode is the default for titles with none of their own, and override says the layout and text values are kept for one title only. The light, the auto scroll speed and the switches are always for every title.
data class ReaderSettings(
    val mode: ReaderMode = ReaderMode.RightToLeft,
    val titleMode: ReaderMode? = null,
    val scale: ReaderScale = ReaderScale.Screen,
    val background: ReaderBackground = ReaderBackground.Theme,
    val gap: ReaderGap = ReaderGap.None,
    val width: ReaderWidth = ReaderWidth.Medium,
    // The width of the long scroll in dp when its width is Custom.
    val customWidth: Int = 800,
    val dual: ReaderDual = ReaderDual.Off,
    val invertTaps: Boolean = false,
    val font: ReaderFont = ReaderFont.System,
    // The size of text in sp, the line height as a multiple of it, and the space between paragraphs in dp.
    val fontSize: Int = 17,
    val lineHeight: Float = 1.6f,
    val paragraphGap: Int = 12,
    val textAlign: ReaderTextAlign = ReaderTextAlign.Left,
    val override: Boolean = false,
    // How much the screen is darkened and how much of an amber tint is laid over it, each from 0 to 1.
    val dim: Float = 0f,
    val warmth: Float = 0f,
    // The speed of the auto scroll in dp each second.
    val autoSpeed: Int = 120,
    // How many words the reader gets through in a minute, for the time a chapter takes.
    val readingWpm: Int = 200,
    val quality: ReaderQuality = ReaderQuality.Best,
    val progressBar: ReaderProgressBar = ReaderProgressBar.Horizontal,
    // Whether a small page number stays at the bottom while the controls are hidden.
    val pageNumber: Boolean = true,
    // How solid the dark band behind the controls is, from see through to fully dark.
    val controlShade: Float = 0.92f,
    // Whether a row of small page pictures shows above the page track, to jump by sight.
    val pageStrip: Boolean = false,
    val lookup: ReaderLookup = ReaderLookup.Auto,
    // Whether the long scroll goes on into the next chapter by itself.
    val inlineNext: Boolean = true,
    val incognito: Boolean = false,
    val keepScreenOn: Boolean = true,
    val hideSystemBars: Boolean = true,
    val orientation: ReaderOrientation = ReaderOrientation.Free,
    val zoomStart: ReaderZoomStart = ReaderZoomStart.Auto,
    // Whether turning a page slides to it. Off, the next page is there at once.
    val animatePages: Boolean = true,
    val pageTurn: ReaderPageTurn = ReaderPageTurn.Slide,
    // The paged modes zoom to one panel at a time, then turn the page after the last.
    val panelZoom: Boolean = false,
    // Whether blank white or black margins are cut off the pages of a turned layout, and whether the pictures are drawn gray or with their colors turned around.
    val cropBorders: Boolean = false,
    val grayscale: Boolean = false,
    val invertColors: Boolean = false,
    // How much of an old paper brown the pages take, from 0 to 1, and how strong their contrast is, from half to twice.
    val sepia: Float = 0f,
    val contrast: Float = 1f,
    // A warmer and dimmer screen between two hours of the day, given as hours from 0 to 23, laid over the light chosen by hand.
    val bedtime: Boolean = false,
    val bedtimeFrom: Int = 22,
    val bedtimeTo: Int = 7,
    val bedtimeWarmth: Float = 0.6f,
    val bedtimeDim: Float = 0.25f,
)
