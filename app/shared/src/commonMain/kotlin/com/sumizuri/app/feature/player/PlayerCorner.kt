package com.sumizuri.app.feature.player

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxScope
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.sumizuri.app.feature.player.overlay.ActiveMarker
import com.sumizuri.app.feature.player.overlay.PlayerMarkerButton
import com.sumizuri.app.feature.player.overlay.PlayerSkipButton
import com.sumizuri.app.feature.player.overlay.PlayerUpNextButton
import com.sumizuri.app.playback.PlayerState

// How high the corner buttons sit while the controls show and while they rest.
private val LiftShown = 136.dp
private val LiftHidden = 24.dp

// A place at an edge of the player for a button or a panel, kept clear of the notch and the bars of the system on the sides given.
@Composable
internal fun BoxScope.PlayerCorner(
    alignment: Alignment,
    sides: WindowInsetsSides,
    padding: PaddingValues,
    content: @Composable () -> Unit,
) {
    Box(
        Modifier.align(alignment).windowInsetsPadding(WindowInsets.safeDrawing.only(sides)).padding(padding),
    ) { content() }
}

// The buttons in the bottom corners of the video: skipping the intro or the end, jumping ahead, and the next episode. They sit higher while the controls show.
@Composable
internal fun BoxScope.PlayerCornerButtons(
    state: SessionState,
    player: PlayerState,
    controls: Boolean,
    skipSeconds: Int,
    onMarker: (ActiveMarker) -> Unit,
    onSkip: () -> Unit,
    onNext: () -> Unit,
) {
    val lift = if (controls) LiftShown else LiftHidden
    val bottom = WindowInsetsSides.Bottom + WindowInsetsSides.Horizontal
    val start = PaddingValues(start = 20.dp, bottom = lift)
    val video = state.current
    if (video != null && (video.intro != null || video.outro != null)) {
        PlayerCorner(Alignment.BottomStart, bottom, start) {
            PlayerMarkerButton(player.positionMs, player.durationMs, video.intro, video.outro, onMarker)
        }
    }
    if (controls && video?.intro == null) {
        PlayerCorner(Alignment.BottomStart, bottom, start) { PlayerSkipButton(skipSeconds, onSkip) }
    }
    PlayerCorner(Alignment.BottomEnd, bottom, PaddingValues(end = 20.dp, bottom = lift)) {
        PlayerUpNextButton(state.hasNext, player.positionMs, player.durationMs, onNext)
    }
}
