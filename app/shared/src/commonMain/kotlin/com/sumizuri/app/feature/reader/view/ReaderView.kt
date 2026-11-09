package com.sumizuri.app.feature.reader.view

import com.sumizuri.app.data.model.controls.ReaderAction

// What a viewer is told about the reading in progress. It starts at a page, goes to a page when asked, and says which page it shows and how far the reader has got.
class ReaderView(
    val startPage: Int,
    val jump: Int?,
    val onJumped: () -> Unit,
    val onPage: (Int) -> Unit,
    // The page in view, the furthest page on the screen and how many pages there are.
    val onProgress: (shown: Int, reached: Int, count: Int) -> Unit,
    // How far into the chapter the reader was, from 0 to 1, and a way to say how many pages the viewer made of it when that is not the number of pages the source gave.
    val startFraction: Double,
    val onCount: (Int) -> Unit,
    val onToggleControls: () -> Unit,
    // Does what the viewer does not do itself, such as opening the next chapter or the options. It says whether it did.
    val onCommon: (ReaderAction) -> Boolean,
    // Called when the pages in view are the last few that are loaded, so the next chapter can be added.
    val onNearEnd: () -> Unit,
    // Whether the long scroll moves by itself, how fast in dp each second, and what to call when it stops.
    val auto: Boolean,
    val autoSpeed: Int,
    val onAutoStopped: () -> Unit,
)
