package com.sumizuri.app.navigation

import com.sumizuri.app.data.pair.PairLink
import io.ktor.http.Url
import io.ktor.http.parseQueryString
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

// The sumizuri links the app was opened with, such as an Open in Sumizuri button on the page of a repo, until a screen takes them.
object AppLinks {
    private val repo = MutableStateFlow<String?>(null)

    // The address of a repo a link asked to add, which waits for the person to say yes in the window of adding a repo.
    val addRepo: StateFlow<String?> = repo

    // Reads a link and keeps what it asks for. Gives false for a link that is not one of the app.
    fun open(link: String?): Boolean {
        val url =
            link
                ?.trim()
                ?.takeIf {
                    it.startsWith(
                        "$Scheme:",
                        ignoreCase = true,
                    )
                }?.let { runCatching { Url(it) }.getOrNull() }
                ?: return false
        return when (url.host.lowercase()) {
            "add-repo" -> {
                val address =
                    url.parameters["url"]?.trim()?.takeIf { it.startsWith("http://") || it.startsWith("https://") }
                        ?: return false
                repo.value = address
                true
            }

            // A title from a notice of new chapters, to open or to read on from where it was left.
            "title" -> {
                val id = url.parameters["id"]?.toLongOrNull() ?: return false
                title.value = TitleLink(id, url.parameters["read"] == "1")
                true
            }

            "updates" -> {
                updates.value = true
                true
            }

            // A TV showed its code, and the phone sends it what it chooses.
            "pair" -> {
                pair.value = PairLink.read(url) ?: return false
                true
            }

            // A tracker opens the app again after the person allowed it there, with a token behind the # of the link or a code in its query.
            "track" -> {
                val fragment = parseQueryString(url.fragment)
                val answer = (
                    url.parameters.names().associateWith { url.parameters[it].orEmpty() } +
                        fragment.names().associateWith { fragment[it].orEmpty() }
                    ).filterValues { it.isNotBlank() }
                if ("access_token" !in answer && "code" !in answer) return false
                track.value = TrackLink(url.encodedPath.trim('/'), answer)
                true
            }

            else -> false
        }
    }

    fun repoTaken() {
        repo.value = null
    }

    private val title = MutableStateFlow<TitleLink?>(null)

    // The title a link asked to open, until the app has opened it.
    val openTitle: StateFlow<TitleLink?> = title

    fun titleTaken() {
        title.value = null
    }

    private val track = MutableStateFlow<TrackLink?>(null)

    // The token a tracker sent the person back with, until the app has taken it.
    val trackSignIn: StateFlow<TrackLink?> = track

    fun trackTaken() {
        track.value = null
    }

    private val updates = MutableStateFlow(false)

    // Whether a link asked for the tab of updates, until the app has shown it.
    val openUpdates: StateFlow<Boolean> = updates

    fun updatesTaken() {
        updates.value = false
    }

    private val pair = MutableStateFlow<PairLink?>(null)

    // The TV a code asked to send to, until the window of sending closes.
    val pairWith: StateFlow<PairLink?> = pair

    fun pairTaken() {
        pair.value = null
    }

    // The link that opens a title, or reads on in it.
    fun titleLink(id: Long, read: Boolean): String = "$Scheme://title?id=$id&read=${if (read) 1 else 0}"

    const val Scheme = "sumizuri"
}

// What a tracker sends back when the person allowed the app: which tracker, and what its answer held, such as a token or a code.
data class TrackLink(val tracker: String, val answer: Map<String, String>)

// A title a link asked for, and whether to read on in it or only to open it.
data class TitleLink(val id: Long, val read: Boolean)
