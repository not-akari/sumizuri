package com.sumizuri.app.feature.player

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.platform.LocalWindowInfo
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.LocalAppContainer
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.model.player.PlayerPrefs
import com.sumizuri.app.feature.player.overlay.subtitleStyle
import com.sumizuri.app.feature.reader.ChapterOpening
import com.sumizuri.app.feature.reader.OpeningLayer
import com.sumizuri.app.feature.reader.OpeningSteps
import com.sumizuri.app.playback.PlayerState
import com.sumizuri.app.playback.PlayerWindow
import com.sumizuri.app.playback.rememberPlayerEngine
import com.sumizuri.app.playback.touchPlayer
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.player_loading_finding
import com.sumizuri.app.shared.resources.player_loading_opening
import com.sumizuri.app.shared.resources.player_loading_opening_quality
import com.sumizuri.app.shared.resources.player_loading_resuming
import com.sumizuri.app.shared.resources.player_loading_starting
import com.sumizuri.app.ui.text.numberedUnit
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import org.jetbrains.compose.resources.stringResource

// The longest the opening waits for the first frame before the player shows anyway, so a video that never says it is ready is not hidden.
private const val FirstFrameWaitMs = 12_000L

// The longest the card waits for the screen to turn sideways, and from how far in a place to start is worth saying.
private const val TurnWaitMs = 700L
private const val ResumeNoteMs = 5_000L

// Finding the video, opening it and starting it.
private const val OpeningStepCount = 3

// The page that plays an episode. It waits for the choices of the person so the subtitles start with the look they chose, then makes the engine and the session. The engine lets go when the page is left, and the session keeps the place first. The opening the reader has shows over it until the first frame is up.
@Composable
fun PlayerRoute(chapterId: Long, onBack: () -> Unit, opening: ChapterPlace? = null) {
    val container = LocalAppContainer.current
    // The screen turns at once, so the opening is already sideways while the episode comes in.
    PlayerWindow()
    val turning = rememberTurning()
    val prefs by produceState<PlayerPrefs?>(null) { value = container.playerPrefs.prefs.first() }
    val loaded = prefs
    if (loaded == null) {
        OpeningLayer(done = false, opening = { EpisodeOpening(opening, null, null, turning, onBack) }) {}
        return
    }
    val engine = rememberPlayerEngine(remember { loaded.subtitleStyle() })
    val scope = rememberCoroutineScope()
    val session = remember(engine) {
        PlayerSession(
            engine,
            scope,
            container.library,
            container.sources,
            container.manager,
            container.solver,
            container.playerPrefs,
            container.reading,
        )
    }
    DisposableEffect(session) {
        session.start(chapterId)
        onDispose { session.dispose() }
    }
    val state by session.state.collectAsStateWithLifecycle()
    val player by engine.state.collectAsStateWithLifecycle()
    // Once the first frame is up the opening stays gone, so a wait for more of the stream later shows the small card of the player instead. A failure lets the player show why.
    var started by remember(chapterId) { mutableStateOf(false) }
    val showing =
        state.phase == PlayerPhase.Ready && player.ready && !player.buffering &&
            (player.videoWidth > 0 || player.positionMs > 0)
    val failed = state.phase == PlayerPhase.Failed
    LaunchedEffect(showing, failed) { if (showing || failed) started = true }
    LaunchedEffect(chapterId) {
        delay(FirstFrameWaitMs)
        started = true
    }
    OpeningLayer(done = started, opening = { EpisodeOpening(opening, state, player, turning, onBack) }) {
        PlayerScreen(session, engine, onBack)
    }
}

// The opening of an episode: its name and the title from what the opener knew, or from the session once it has them. Under them are the steps of finding the video, opening it and starting it, with words for the one at work.
@Composable
private fun EpisodeOpening(
    opening: ChapterPlace?,
    state: SessionState?,
    player: PlayerState?,
    turning: Boolean,
    onBack: () -> Unit,
) {
    val episode = state?.episode
    val heading = episode?.name?.takeIf { it.isNotBlank() }
        ?: opening?.name?.takeIf { it.isNotBlank() }
        ?: (episode?.number ?: opening?.number)?.let { numberedUnit(Kind.Anime, it) }
    val current = state?.current
    val step = when {
        current == null -> 0
        player == null || player.durationMs <= 0 -> 1
        else -> 2
    }
    val note = when (step) {
        0 -> stringResource(Res.string.player_loading_finding)

        1 -> current?.quality?.let { stringResource(Res.string.player_loading_opening_quality, it) }
            ?: stringResource(Res.string.player_loading_opening)

        else -> player?.positionMs?.takeIf { it >= ResumeNoteMs }?.let {
            stringResource(Res.string.player_loading_resuming, formatTime(it))
        } ?: stringResource(Res.string.player_loading_starting)
    }
    ChapterOpening(
        cover = opening?.coverUrl,
        sourceId = opening?.sourceId,
        heading = heading,
        titleName = state?.titleName?.ifEmpty { null } ?: opening?.titleName,
        onBack = onBack,
        note = note,
        hold = turning,
        steps = OpeningSteps(step, OpeningStepCount),
    )
}

// Whether a phone is still turning sideways for the video, for at most a short while so a screen that never turns, such as a big tablet, is not kept waiting.
@Composable
private fun rememberTurning(): Boolean {
    val window = LocalWindowInfo.current.containerSize
    var waited by remember { mutableStateOf(false) }
    LaunchedEffect(Unit) {
        delay(TurnWaitMs)
        waited = true
    }
    return touchPlayer && window.width < window.height && !waited
}
