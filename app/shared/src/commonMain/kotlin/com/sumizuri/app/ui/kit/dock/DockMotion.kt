package com.sumizuri.app.ui.kit.dock

import androidx.compose.animation.AnimatedContentTransitionScope
import androidx.compose.animation.ContentTransform
import androidx.compose.animation.EnterTransition
import androidx.compose.animation.SizeTransform
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.tween
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.togetherWith
import androidx.compose.ui.unit.IntSize

// A soft spring for things that grow or arrive, settling without a bounce one can see.
private fun <T> settle() = spring<T>(dampingRatio = 0.86f, stiffness = Spring.StiffnessMediumLow)

// How the panels of a dock change, where none is the state with no panel open. Opening one grows the dock with a spring while the panel fades in a moment later, closing one fades it out fast while the dock settles back, and one panel fades into the next while the dock takes its new size. The size is the only thing that moves the dock, so nothing fights it.
fun <T> AnimatedContentTransitionScope<T>.panelChange(reduce: Boolean, none: T): ContentTransform {
    val size = SizeTransform(clip = true) { _, _ -> if (reduce) tween<IntSize>(150) else settle() }
    if (reduce) return (fadeIn(tween(150)) togetherWith fadeOut(tween(100))) using size
    val opening = initialState == none
    val closing = targetState == none
    val enter = if (closing) EnterTransition.None else fadeIn(tween(220, delayMillis = if (opening) 70 else 40))
    val exit = fadeOut(tween(if (closing) 140 else 90))
    return (enter togetherWith exit) using size
}
