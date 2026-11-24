package com.sumizuri.app.navigation

import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import com.sumizuri.app.data.AppContainer
import com.sumizuri.app.data.share.Incoming
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.feature.library.continueChapterOf

// What the app was opened with from outside, a sumizuri link or a file, turned into the page or the tab it asks for once the saved place of the app is back.
@Composable
internal fun AppLinkEffects(place: NavigationState, navigation: NavigationViewModel, container: AppContainer) {
    // A link that asks to add a repo opens Browse, where the window of adding one shows it and waits for a yes.
    val linkedRepo by AppLinks.addRepo.collectAsStateWithLifecycle()
    LaunchedEffect(linkedRepo, place.restored) {
        if (linkedRepo != null && place.restored) navigation.select(Destination.Browse)
    }
    // A notice of new chapters opens its title, or reads on in it from where it was left.
    val linkedTitle by AppLinks.openTitle.collectAsStateWithLifecycle()
    LaunchedEffect(linkedTitle, place.restored) {
        val link = linkedTitle ?: return@LaunchedEffect
        if (!place.restored) return@LaunchedEffect
        AppLinks.titleTaken()
        val chapter = if (link.read) continueChapterOf(container.library, link.id) else null
        navigation.push(chapter?.let { Page.Reader(it) } ?: Page.Saved(link.id))
    }
    // A tracker that sent the person back with a token signs this profile in. The page the person left shows how it went.
    val linkedTrack by AppLinks.trackSignIn.collectAsStateWithLifecycle()
    LaunchedEffect(linkedTrack) {
        val link = linkedTrack ?: return@LaunchedEffect
        AppLinks.trackTaken()
        TrackerId.of(link.tracker)?.let { container.trackers.finish(it, link.answer) }
    }
    val linkedUpdates by AppLinks.openUpdates.collectAsStateWithLifecycle()
    LaunchedEffect(linkedUpdates, place.restored) {
        if (linkedUpdates && place.restored) {
            AppLinks.updatesTaken()
            navigation.select(Destination.Updates)
        }
    }
    // A file of the app the system opened it with, such as one double clicked or picked with Open with, goes to the import page, which reads it as if it was chosen there.
    val openedFile by Incoming.opened.collectAsStateWithLifecycle()
    LaunchedEffect(openedFile, place.restored) {
        if (openedFile != null && place.restored && place.top != Page.Import) navigation.push(Page.Import)
    }
}
