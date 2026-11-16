package com.sumizuri.app.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.remember
import androidx.navigationevent.NavigationEventInput
import androidx.navigationevent.compose.LocalNavigationEventDispatcherOwner

// Back asked for by a key or a mouse button, sent through the same chain as the back of the system, so the innermost thing that listens goes first: an open panel, a picking mode, a page beside the settings list, and only then the page itself.
class BackInput : NavigationEventInput() {
    private var listened = false

    override fun onHasEnabledHandlersChanged(hasEnabledHandlers: Boolean) {
        listened = hasEnabledHandlers
    }

    // Gives false when nothing listens, so the key goes on to the page under it.
    fun back(): Boolean {
        if (!listened) return false
        dispatchOnBackCompleted()
        return true
    }
}

// The back of keys and mouse buttons, joined to the chain of the window for as long as it is shown.
@Composable
fun rememberBackInput(): BackInput {
    val owner = LocalNavigationEventDispatcherOwner.current
    val input = remember { BackInput() }
    DisposableEffect(owner) {
        val dispatcher = owner?.navigationEventDispatcher
        dispatcher?.addInput(input)
        onDispose { dispatcher?.removeInput(input) }
    }
    return input
}
