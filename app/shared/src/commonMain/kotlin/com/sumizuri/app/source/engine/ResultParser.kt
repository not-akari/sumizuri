package com.sumizuri.app.source.engine

import com.fleeksoft.ksoup.nodes.Entities
import com.sumizuri.app.source.model.Descramble
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.model.SourceBook
import com.sumizuri.app.source.model.SourcePage
import com.sumizuri.app.source.model.SourceTrack
import com.sumizuri.app.source.model.SourceVideo
import com.sumizuri.app.source.model.TimeRange
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.longOrNull
import kotlin.time.Instant

// The mark between the title and the chapter in the address of a chapter, since the app gives a chapter address alone and the format asks for both. Such an address is not a web address.
const val PackedChapterMark = "␟"

// Reads the shapes extensions answer with, by the field names of the format, into the models of the app.
internal object ResultParser {
    // A name as a person reads it, since sites often leave HTML codes for marks in the text they send, which an extension passes on as they are.
    private fun plain(text: String?): String? = if (text != null && '&' in text) Entities.unescape(text) else text

    // A title from Browse, Search or the details, where the details nest the fields under mangaInfo.
    fun entry(element: JsonElement, fallbackId: String? = null): SourceEntry {
        val outer = element as? JsonObject ?: throw ParseException("A title is not an object")
        val info = outer["mangaInfo"] as? JsonObject ?: outer
        val id =
            text(outer, "mangaId") ?: text(outer, "id") ?: text(info, "mangaId") ?: fallbackId
                ?: throw ParseException("A title has no mangaId")
        return SourceEntry(
            url = id,
            title = plain(text(info, "title") ?: text(outer, "title")) ?: id,
            coverUrl = text(info, "image") ?: text(outer, "image"),
            bannerUrl = text(info, "banner") ?: text(outer, "banner"),
            author = plain(text(info, "author") ?: text(outer, "author")),
            description = text(info, "desc") ?: text(info, "summary") ?: text(outer, "summary"),
            rating = number(info, "rating"),
            status = statusOf(text(info, "status")),
            genres = words(info["tags"] ?: outer["tags"]),
            webUrl = text(info, "webURL") ?: text(outer, "webURL"),
            volumesId = text(info, "volumesId") ?: text(outer, "volumesId"),
        )
    }

    // A chapter, or an episode for an anime source. The season fields are an addition of Sumizuri for sources that split episodes by season.
    fun chapter(titleId: String, element: JsonElement): SourceChapter {
        val item = element as? JsonObject ?: throw ParseException("A chapter is not an object")
        val id = text(item, "id") ?: text(item, "chapterId") ?: throw ParseException("A chapter has no id")
        val name = plain(text(item, "name") ?: text(item, "title")) ?: ""
        return SourceChapter(
            url = titleId + PackedChapterMark + id,
            title = name,
            number =
            number(item, "number") ?: number(item, "chapNum")
                ?: Regex("""(\d+(?:\.\d+)?)""").find(name)?.value?.toDoubleOrNull(),
            volume = number(item, "volume"),
            scanlator = text(item, "group"),
            language = text(item, "language"),
            uploadedAt = time(item["time"]),
            // A flag when the extension gives one, and otherwise a chapter whose name says it is locked.
            locked =
            flag(item, "isLocked") == true || flag(item, "locked") == true ||
                Regex("""(^|[^a-z])locked([^a-z]|$)""", RegexOption.IGNORE_CASE).containsMatchIn(name),
            unlocksAt = time(item["unlockAt"] ?: item["unlocksAt"]),
            season = text(item, "season"),
            seasonName = text(item, "seasonName"),
            seasonCoverUrl = text(item, "seasonCover"),
        )
    }

    // The file a chapter points at instead of giving its pages, a PDF or an EPUB, an addition of the Suki build.
    fun book(details: JsonObject): SourceBook? {
        val book = details["book"] as? JsonObject ?: return null
        return text(book, "url")?.let { SourceBook(it, strings(book["headers"])) }
    }

    // The pages of a chapter: picture addresses, given as text or as an object, or the text of a novel chapter as one string or a list of paragraphs.
    fun pages(details: JsonObject, resolved: List<String?>? = null): List<SourcePage> {
        val given = (details["pages"] as? JsonArray).orEmpty()
        val pages = given.mapIndexedNotNull { index, page ->
            val address = resolved?.getOrNull(index) ?: pageAddress(page)
            address?.let { SourcePage(index, imageUrl = it, descramble = (page as? JsonObject)?.let(::descrambleOf)) }
        }
        if (pages.isNotEmpty()) return pages
        return when (val text = details["text"]) {
            null, JsonNull -> emptyList()

            is JsonArray -> text.mapIndexedNotNull { index, part ->
                (part as? JsonPrimitive)?.content?.let {
                    SourcePage(index, text = it)
                }
            }

            else -> listOfNotNull((text as? JsonPrimitive)?.content?.let { SourcePage(0, text = it) })
        }
    }

    // Whether a page is a stand in that getPageData has to fill, as the few sources that hand pages out one at a time give.
    fun needsData(page: JsonElement): Boolean =
        pageAddress(page)?.let { !Regex("^(https?:|data:)", RegexOption.IGNORE_CASE).containsMatchIn(it) } ?: true

    // What getPageData gave, as an address the reader can open.
    fun pageData(element: JsonElement): String? {
        val data = element as? JsonObject ?: return null
        text(data, "base64")?.let { return "data:${text(data, "mimeType") ?: "image/jpeg"};base64,$it" }
        return text(data, "uri") ?: text(data, "url")
    }

    // The videos of an episode, an addition of Sumizuri for anime sources: each with its address, quality, headers, subtitles, audio tracks and the times of its intro and outro.
    fun videos(element: JsonElement): List<SourceVideo> = (element as? JsonArray).orEmpty().mapNotNull { item ->
        val video = item as? JsonObject ?: return@mapNotNull null
        val url = text(video, "url") ?: return@mapNotNull null
        SourceVideo(
            url = url,
            quality = text(video, "quality"),
            headers = strings(video["headers"]),
            subtitles = tracks(video["subtitles"]),
            audioTracks = tracks(video["audio"]),
            intro = range(video["intro"]),
            outro = range(video["outro"]),
        )
    }

    private fun pageAddress(page: JsonElement): String? = when (page) {
        is JsonPrimitive -> page.content.takeIf { page.isString && it.isNotBlank() }
        is JsonObject -> text(page, "url") ?: text(page, "uri")
        else -> null
    }

    private fun descrambleOf(page: JsonObject): Descramble? {
        val rule = page["descramble"] as? JsonObject ?: return null
        val cols = number(rule, "cols")?.toInt() ?: return null
        val rows = number(rule, "rows")?.toInt() ?: return null
        val order = (rule["order"] as? JsonArray).orEmpty().mapNotNull { (it as? JsonPrimitive)?.doubleOrNull?.toInt() }
        return Descramble(cols, rows, order).takeIf { order.size == cols * rows }
    }

    private fun tracks(element: JsonElement?): List<SourceTrack> =
        (element as? JsonArray).orEmpty().mapNotNull { item ->
            val track = item as? JsonObject ?: return@mapNotNull null
            val url = text(track, "url") ?: return@mapNotNull null
            SourceTrack(url, text(track, "label") ?: text(track, "language") ?: "", text(track, "language"))
        }

    private fun range(element: JsonElement?): TimeRange? {
        val span = element as? JsonObject ?: return null
        val start = number(span, "start")?.toLong() ?: return null
        val end = number(span, "end")?.toLong() ?: return null
        return TimeRange(start, end).takeIf { end > start }
    }

    // The status words of the format, as the words the app reads.
    private fun statusOf(status: String?): String? = when (status?.uppercase()) {
        "ONGOING" -> "ongoing"
        "COMPLETED" -> "completed"
        "HIATUS" -> "hiatus"
        "CANCELLED" -> "cancelled"
        else -> null
    }

    // A time as epoch milliseconds, from a number as the format gives it or from a date written out.
    private fun time(element: JsonElement?): Long? {
        val value = element as? JsonPrimitive ?: return null
        value.longOrNull?.let { return it }
        value.doubleOrNull?.let { return it.toLong() }
        return runCatching { Instant.parse(value.content).toEpochMilliseconds() }.getOrNull()
    }

    private fun words(element: JsonElement?): List<String> = (element as? JsonArray).orEmpty().mapNotNull { item ->
        when (item) {
            is JsonPrimitive -> item.content.takeIf { it.isNotBlank() }
            is JsonObject -> text(item, "label") ?: text(item, "title") ?: text(item, "id")
            else -> null
        }
    }

    private fun strings(element: JsonElement?): Map<String, String> = (element as? JsonObject)
        ?.mapNotNull { (key, value) ->
            (value as? JsonPrimitive)?.content?.let {
                key to
                    it
            }
        }?.toMap()
        .orEmpty()

    fun text(item: JsonObject, key: String): String? = (item[key] as? JsonPrimitive)
        ?.takeIf {
            it !is JsonNull
        }?.content
        ?.takeIf { it.isNotBlank() }

    private fun number(item: JsonObject, key: String): Double? {
        val value = item[key] as? JsonPrimitive ?: return null
        return value.doubleOrNull ?: value.content.toDoubleOrNull()
    }

    private fun flag(item: JsonObject, key: String): Boolean? = (item[key] as? JsonPrimitive)?.booleanOrNull
}

// A reply that does not have the shape the engine expects.
class ParseException(message: String) : Exception(message)
