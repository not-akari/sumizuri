package com.sumizuri.app.feature.player.overlay

import com.sumizuri.app.feature.player.picker.Picker

// What the controls over the picture can do, given by the screen.
internal class OverlayCalls(
    val onClose: () -> Unit,
    val onPlayPause: () -> Unit,
    val onJump: (forward: Boolean) -> Unit,
    val onPrevious: (() -> Unit)?,
    val onNext: (() -> Unit)?,
    val onSeek: (Long) -> Unit,
    val onScrubStart: () -> Unit,
    val onScrubEnd: () -> Unit,
    val onOpen: (Picker) -> Unit,
    val onLock: () -> Unit,
    val onFullscreen: (() -> Unit)?,
    val onFit: () -> Unit,
    // Asks the engine for the small picture of a spot on the seek bar.
    val onPreview: ((Long) -> Unit)? = null,
    // Shrinks the player to the small floating one, where the system has it.
    val onMini: (() -> Unit)? = null,
    // Sets the sound from 0 to 100, where the player has a pointer instead of touch.
    val onVolume: ((Int) -> Unit)? = null,
)
