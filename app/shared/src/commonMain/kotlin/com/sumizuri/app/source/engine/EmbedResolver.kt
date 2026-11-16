package com.sumizuri.app.source.engine

import com.sumizuri.app.source.browser.BrowserBroker
import com.sumizuri.app.source.browser.request.RenderRequest
import com.sumizuri.app.source.browser.request.RenderResult
import com.sumizuri.app.source.host.net.AddressGuard
import com.sumizuri.app.source.model.SourceVideo
import kotlinx.coroutines.CancellationException
import kotlin.time.Duration.Companion.seconds

// Turns an embed entry of an episode, which is the address of a player page and not of a video, into a video: the page is opened in the hidden browser and the stream it loads is taken.
internal object EmbedResolver {
    private const val MediaPattern = """\.(m3u8|mp4|webm)(\?|#|$)"""
    private val Media = Regex(MediaPattern, RegexOption.IGNORE_CASE)

    // What a player page loads that is not the video: adverts, trackers and pictures.
    private val NotTheVideo =
        Regex(
            """(doubleclick|googlesyndication|googletagmanager|/ads?/|analytics|pixel|favicon|thumb|poster|preview|sprite)""",
            RegexOption.IGNORE_CASE,
        )

    // A stream written in the page itself, as a player's setup script has it, with the slashes escaped or not.
    private val WrittenInPage =
        Regex("""https?:(?:\\?/){2}[^\s"'<>\\]+?\.(?:m3u8|mp4|webm)[^\s"'<>\\]*""", RegexOption.IGNORE_CASE)

    private val PageTimeout = 20.seconds

    // The video the page behind [embed] plays, or null when it gave none in time.
    suspend fun resolve(browser: BrowserBroker, embed: SourceVideo): SourceVideo? {
        val result = try {
            browser.render(
                RenderRequest(
                    url = AddressGuard.check(embed.url),
                    waitForResource = MediaPattern,
                    capture = MediaPattern,
                    timeout = PageTimeout,
                ),
            )
        } catch (error: CancellationException) {
            throw error
        } catch (error: Exception) {
            return null
        }
        val address = pick(result) ?: return null
        val origin = embed.url.substringBefore("://") + "://" + embed.url.substringAfter("://").substringBefore('/')
        return embed.copy(
            url = address,
            headers = embed.headers + mapOf("Referer" to embed.url, "Origin" to origin),
            type = null,
        )
    }

    // The stream to play among what the page loaded and wrote: a playlist before a plain file.
    fun pick(result: RenderResult): String? {
        val written = WrittenInPage.findAll(result.html).map { it.value.replace("\\/", "/") }
        val found = (result.resources.asSequence() + written)
            .filter { Media.containsMatchIn(it) && !NotTheVideo.containsMatchIn(it) }
            .distinct()
            .toList()
        return found.firstOrNull { it.substringBefore('?').endsWith(".m3u8", ignoreCase = true) } ?: found.firstOrNull()
    }
}
