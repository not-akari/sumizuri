package com.sumizuri.app.navigation

import androidx.compose.animation.AnimatedContent
import androidx.compose.animation.EnterExitState
import androidx.compose.animation.core.SeekableTransitionState
import androidx.compose.animation.core.rememberTransition
import androidx.compose.foundation.focusGroup
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.WindowInsetsSides
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.only
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.safeDrawing
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.runtime.saveable.rememberSaveableStateHolder
import androidx.compose.runtime.snapshotFlow
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.drawWithContent
import androidx.compose.ui.focus.focusProperties
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.CompositingStrategy
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.unit.dp
import androidx.navigationevent.NavigationEventTransitionState
import androidx.navigationevent.compose.NavigationEventState
import com.sumizuri.app.ui.motion.LocalPageLeaving
import com.sumizuri.app.ui.motion.LocalPageMotion
import com.sumizuri.app.ui.motion.LocalPageSettled
import com.sumizuri.app.ui.motion.MotionShift
import com.sumizuri.app.ui.motion.PageMotion
import com.sumizuri.app.ui.motion.pageTransform
import com.sumizuri.app.ui.motion.rememberMotionShift
import com.sumizuri.app.ui.motion.underMotion
import com.sumizuri.app.ui.theme.background.BackdropSlot
import com.sumizuri.app.ui.theme.background.HideBackdropBehind
import com.sumizuri.app.ui.theme.background.LocalBackdropSlot
import com.sumizuri.app.ui.theme.background.ambientBackground
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.receiveAsFlow

// What the page layer shows: the page on top, or none, and how many pages are open, which tells a page coming in from one going back.
private data class Shown(val page: Page?, val depth: Int)

// A page is told apart by where it sits in the stack and what it shows, so the same page opened again later starts fresh.
private fun pageKey(depth: Int, page: Page): String = "$depth:${page::class.simpleName}:${page.hashCode()}"

// Tells the page layer that a back gesture was given up, so the page it was uncovering slides back.
class PageBack {
    internal val cancels = Channel<Unit>(Channel.CONFLATED)

    fun cancel() {
        cancels.trySend(Unit)
    }
}

// The pages over the tabs, which come and go the way the person chose. A back gesture of the system moves the top page as the finger moves, uncovering the one under it, and lets it go or springs it back when the finger lifts.
@Composable
internal fun PageStack(
    place: NavigationState,
    navigation: NavigationViewModel,
    back: NavigationEventState<*>,
    pageBack: PageBack,
    tabs: @Composable () -> Unit,
) {
    val style = LocalPageMotion.current
    val ms = style.pageMs()
    val shift = rememberMotionShift()
    val shown = Shown(place.top, place.pages.size)
    val seekable = remember { SeekableTransitionState(shown) }
    // A page opened or closed: the layer moves to it, from wherever a gesture left it.
    LaunchedEffect(shown) {
        if (seekable.currentState != shown || seekable.targetState != shown) seekable.animateTo(shown)
    }
    // The page under the top one follows a back gesture, for as long as there is a page to close.
    LaunchedEffect(back, place.pages) {
        if (place.pages.isEmpty() || ms == 0) return@LaunchedEffect
        val under = Shown(place.pages.getOrNull(place.pages.size - 2), place.pages.size - 1)
        snapshotFlow { back.transitionState }.collect { gesture ->
            if (gesture is NavigationEventTransitionState.InProgress &&
                gesture.direction == NavigationEventTransitionState.TRANSITIONING_BACK
            ) {
                seekable.seekTo(gesture.latestEvent.progress.coerceIn(0f, 1f), under)
            }
        }
    }
    LaunchedEffect(pageBack) {
        pageBack.cancels.receiveAsFlow().collect { seekable.animateTo(seekable.currentState) }
    }
    // Each open page keeps what it saved, such as how far its list was scrolled, while another page covers it, and lets go of it once it is closed.
    val saved = rememberSaveableStateHolder()
    val open = place.pages.mapIndexed { index, each -> pageKey(index + 1, each) }
    val known = remember { mutableSetOf<String>() }
    LaunchedEffect(open) {
        (known - open.toSet()).forEach { saved.removeState(it) }
        known.retainAll(open.toSet())
        known.addAll(open)
    }
    val transition = rememberTransition(seekable, label = "page")
    // The tabs stay composed under the pages so a grid keeps its place. They move as the page that gives way to the first page, and are not drawn while a page covers them.
    // While a page covers them, the remote and the keyboard cannot move into them either.
    val covered by rememberUpdatedState(place.pages.isNotEmpty())
    Box(
        Modifier
            .fillMaxSize()
            .underPages(style, seekable, shift)
            .focusProperties { onEnter = { if (covered) cancelFocusChange() } }
            .focusGroup(),
    ) { tabs() }
    transition.AnimatedContent(
        // Always the whole window, so a page never grows out of a corner when there was no page before it.
        modifier = Modifier.fillMaxSize(),
        transitionSpec = { pageTransform(style, ms, targetState.depth >= initialState.depth, shift) using null },
    ) { now ->
        val page = now.page ?: return@AnimatedContent
        // Once the page has slid all the way in it covers the window, and the background under the tabs is not drawn behind it.
        val entering = this.transition
        val settled = entering.currentState == EnterExitState.Visible && entering.targetState == EnterExitState.Visible
        HideBackdropBehind(settled)
        // The page has a background of its own, which a page part that draws its own background over all of it can hide in turn.
        val pageSlot = remember { BackdropSlot() }
        // The page covers the tabs, so it also takes the touches that would reach them.
        Surface(
            Modifier
                .fillMaxSize()
                .ambientBackground(pageSlot, onPage = true)
                .pointerInput(Unit) { detectTapGestures { } },
            color = Color.Transparent,
            contentColor = MaterialTheme.colorScheme.onBackground,
        ) {
            // A page deeper than the one now shown is on its way out, since only a page that was closed is deeper.
            CompositionLocalProvider(
                LocalBackdropSlot provides pageSlot,
                LocalPageLeaving provides (now.depth > shown.depth),
                LocalPageSettled provides settled,
            ) {
                // The page keeps clear of the tabs down the side, which stay over it, unless it takes the whole window. Its background still runs under them, so the two meet without a seam.
                val side = if (page.fullWindow) 0.dp else LocalSideNavWidth.current
                val insets = if (side > 0.dp) {
                    WindowInsets.safeDrawing.only(
                        WindowInsetsSides.Top + WindowInsetsSides.End + WindowInsetsSides.Bottom,
                    )
                } else {
                    WindowInsets.safeDrawing
                }
                Box(
                    if (page.edgeToEdge) {
                        Modifier.fillMaxSize().padding(start = side)
                    } else {
                        Modifier.fillMaxSize().padding(start = side).windowInsetsPadding(insets)
                    },
                ) {
                    saved.SaveableStateProvider(pageKey(now.depth, page)) { PageHost(page, navigation) }
                }
            }
        }
    }
}

// Moves the tabs as the page under the first one, by how far the change has gone, and leaves them undrawn while a page covers them.
private fun Modifier.underPages(
    style: PageMotion,
    seekable: SeekableTransitionState<Shown>,
    shift: MotionShift,
): Modifier = graphicsLayer {
    // Each part of the screen is faded on its own, and the whole screen is not drawn into a buffer first.
    compositingStrategy = CompositingStrategy.ModulateAlpha
    val from = seekable.currentState.depth
    val to = seekable.targetState.depth
    when {
        from == 0 && to == 0 -> Unit
        from > 0 && to > 0 -> alpha = 0f
        else -> underMotion(style, seekable.fraction, leaving = from == 0, shift)
    }
}.drawWithContent { if (seekable.currentState.depth == 0 || seekable.targetState.depth == 0) drawContent() }
