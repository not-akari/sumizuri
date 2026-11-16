package com.sumizuri.app.navigation

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.SessionRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.text.enumNamed
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.drop
import kotlinx.coroutines.flow.filter
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// The place the user is in. It is saved with every change, so the app can open where it was left when the person wants that.
class NavigationViewModel(
    private val session: SessionRepository,
    private val sources: SourceRepository,
    private val library: LibraryRepository,
) : ViewModel() {
    private val mutableState = MutableStateFlow(NavigationState())
    val state: StateFlow<NavigationState> = mutableState

    init {
        viewModelScope.launch {
            mutableState.filter { it.restored }.drop(1).collect { session.setPlace(PlaceJson.encode(it)) }
        }
    }

    // Starts the app on the library, or, when the person asked for it, on the saved place, read once. Without one, or when it cannot be read, the app starts on the library too.
    suspend fun restore(reopen: Boolean) {
        if (mutableState.value.restored) return
        if (!reopen) {
            mutableState.update { NavigationState(restored = true) }
            return
        }
        val saved = session.place()?.let { PlaceJson.decode(it, sources.installed.first()) }
        // An episode is not opened again when the app starts: a video is best begun by hand, and a player that cannot start must never stand between the person and the app.
        val opened = saved?.let { place ->
            place.copy(
                pages = place.pages.filterNot { page ->
                    page is Page.Reader &&
                        library.chapterPlace(page.chapterId)?.kind == Kind.Anime
                },
            )
        }
        mutableState.update { opened ?: NavigationState(restored = true) }
    }

    // The pages back closed, the newest last, which forward opens again. Going anywhere new forgets them, as a browser does.
    private var closed = emptyList<Page>()

    // Choosing a tab closes every page that was open over the old one.
    fun select(tab: Destination) {
        closed = emptyList()
        mutableState.update { NavigationState(tab, restored = true) }
    }

    fun push(page: Page) {
        closed = emptyList()
        mutableState.update { it.copy(pages = it.pages + page) }
    }

    // Swaps the page on top, for example a preview that became a saved title.
    fun replaceTop(page: Page) {
        closed = emptyList()
        mutableState.update { it.copy(pages = it.pages.dropLast(1) + page) }
    }

    fun pop() {
        mutableState.value.top?.let { closed = closed + it }
        mutableState.update { it.copy(pages = it.pages.dropLast(1)) }
    }

    // Opens again the page back closed last, and gives false when there is none.
    fun forward(): Boolean {
        val page = closed.lastOrNull() ?: return false
        closed = closed.dropLast(1)
        mutableState.update { it.copy(pages = it.pages + page) }
        return true
    }

    // Closes the page that moved a title. When the page under it is the title that was moved, that page becomes the moved title, so back leads to where the title was opened from. Under any other page, such as a list of titles that wait for a source, only the moving page closes and that page stays as it was.
    fun moved(oldId: Long, newId: Long) = mutableState.update { now ->
        closed = emptyList()
        val rest = now.pages.dropLast(1)
        now.copy(pages = if (rest.lastOrNull() == Page.Saved(oldId)) rest.dropLast(1) + Page.Saved(newId) else rest)
    }
}

data class NavigationState(
    val tab: Destination = Destination.Library,
    val pages: List<Page> = emptyList(),
    // False until the saved place has been read, so the app does not flash the library before it jumps back.
    val restored: Boolean = false,
) {
    val top: Page? get() = pages.lastOrNull()
}

// The tab a shortcut of the launcher asked for, from its name, or null when the name is none of the tabs.
fun requestedTabOf(name: String?): Destination? = enumNamed<Destination>(name)
