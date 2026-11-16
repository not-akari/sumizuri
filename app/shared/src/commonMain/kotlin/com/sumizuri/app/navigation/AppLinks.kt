package com.sumizuri.app.navigation

import io.ktor.http.Url
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

    private val updates = MutableStateFlow(false)

    // Whether a link asked for the tab of updates, until the app has shown it.
    val openUpdates: StateFlow<Boolean> = updates

    fun updatesTaken() {
        updates.value = false
    }

    // The link that opens a title, or reads on in it.
    fun titleLink(id: Long, read: Boolean): String = "$Scheme://title?id=$id&read=${if (read) 1 else 0}"

    const val Scheme = "sumizuri"
}

// A title a link asked for, and whether to read on in it or only to open it.
data class TitleLink(val id: Long, val read: Boolean)
