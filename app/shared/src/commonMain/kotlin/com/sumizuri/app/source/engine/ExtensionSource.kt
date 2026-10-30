package com.sumizuri.app.source.engine

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.core.perf.Perf
import com.sumizuri.app.source.Source
import com.sumizuri.app.data.local.bookPages
import com.sumizuri.app.source.SourceError
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.host.StandardHost
import com.sumizuri.app.source.model.CommentPage
import com.sumizuri.app.source.model.CommentSort
import com.sumizuri.app.source.model.FilterGroup
import com.sumizuri.app.source.model.FilterOption
import com.sumizuri.app.source.model.FilterType
import com.sumizuri.app.source.model.SourceCatalog
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.model.SourceInfo
import com.sumizuri.app.source.model.SourcePage
import com.sumizuri.app.source.model.SourcePreference
import com.sumizuri.app.source.model.SourceVideo
import com.sumizuri.app.source.repo.InstalledSource
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeout
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.put
import kotlin.time.TimeSource

// How many lazy pages of one chapter are asked for at once.
private const val PagesAtOnce = 4

// A source backed by an extension in the source format: a Source class whose methods are called as the format calls them, with its answers read in the shapes the format defines.
class ExtensionSource private constructor(
    private val runtime: ExtensionRuntime,
    private val host: StandardHost,
    override val info: SourceInfo,
    // The settings the extension declares in its repo entry, without the section headings.
    private val schema: List<JsonObject>,
    private val callTimeoutMs: Long,
) : Source {
    private val methods = runtime.shape.methods

    // The feeds the extension lists, or one unnamed feed when it lists none, as the format gives.
    private val feeds: List<Feed> = runtime.shape.feeds
        .mapNotNull { item ->
            val feed = item as? JsonObject ?: return@mapNotNull null
            Feed(
                feed["id"] ?: JsonNull,
                ResultParser.text(feed, "name") ?: (feed["id"] as? JsonPrimitive)?.content ?: "Popular",
            )
        }.ifEmpty { listOf(Feed(JsonNull, "Popular")) }

    // The first feed that reads as popular and the first that reads as latest fill those two lists of the app. The rest are catalogs.
    private val popularAt = feeds.indexOfFirst { it.reads("popular", "trending", "hot", "top") }.takeIf { it >= 0 } ?: 0
    private val latestAt =
        feeds.indices.firstOrNull { it != popularAt && feeds[it].reads("latest", "recent", "new", "update") }
            ?: if (feeds.size > 1) (if (popularAt == 0) 1 else 0) else popularAt
    private val others = feeds.filterIndexed { index, _ -> index != popularAt && index != latestAt }

    // What each list asked for each of its pages, from the metadata the extension handed back, and the last page of a list that ended.
    private class Cursor(val pages: MutableMap<Int, JsonElement> = mutableMapOf(), var end: Int? = null)

    private val cursors = mutableMapOf<String, Cursor>()
    private val cursorLock = Mutex()

    override suspend fun popular(page: Int) = list(feeds[popularAt].id, "", emptyList(), page)

    override suspend fun latest(page: Int) = list(feeds[latestAt].id, "", emptyList(), page)

    // Search and filters share one method, as the format has it. The tags of every section go together, as the source reads one list.
    override suspend fun search(query: String, page: Int, filters: Map<String, Any?>): SourceResult<List<SourceEntry>> {
        val tags = filters.filterKeys { it == "tags" || it.startsWith("tags.") }.values.flatMap(::many)
        val excluded = many(filters["exclude"])
        val sort = (filters["sort"] as? String)?.takeIf { it.isNotEmpty() }
        val narrowed = query.isNotBlank() || tags.isNotEmpty() || excluded.isNotEmpty() || sort != null
        return list(if (narrowed) JsonNull else feeds[popularAt].id, query, tags, page, sort, excluded)
    }

    override suspend fun catalogs(): SourceResult<List<SourceCatalog>> = SourceResult.Ok(
        others.map {
            SourceCatalog((it.id as? JsonPrimitive)?.content ?: it.name, it.name)
        },
    )

    override suspend fun catalog(id: String, page: Int): SourceResult<List<SourceEntry>> {
        val feed =
            others.firstOrNull { (it.id as? JsonPrimitive)?.content == id }
                ?: return SourceResult.Err(SourceError.NotImplemented("catalog $id"))
        return list(feed.id, "", emptyList(), page)
    }

    // The orders the source offers, its tag sections, and the tags to leave out for a source whose search reads them. A section that says single picks one tag.
    override suspend fun filters(): SourceResult<List<FilterGroup>> {
        val groups = mutableListOf<FilterGroup>()
        if ("getSortOptions" in methods) {
            (call("getSortOptions") { it } as? SourceResult.Ok)?.value?.let { reply ->
                val options = (reply as? JsonArray).orEmpty().mapNotNull { option(it) }
                if (options.isNotEmpty()) groups += FilterGroup("sort", "Sort", FilterType.Select, options)
            }
        }
        if ("getSearchTags" in methods) {
            (call("getSearchTags") { it } as? SourceResult.Ok)?.value?.let { reply ->
                val all = mutableListOf<FilterOption>()
                for (section in sections(reply as? JsonArray ?: JsonArray(emptyList()))) {
                    if (section.options.isEmpty()) continue
                    all += section.options
                    groups += if (section.single) {
                        FilterGroup(
                            "tags.${section.id}",
                            section.title,
                            FilterType.Select,
                            listOf(FilterOption("Any", "")) + section.options,
                        )
                    } else {
                        FilterGroup("tags.${section.id}", section.title, FilterType.MultiSelect, section.options)
                    }
                }
                if (runtime.shape.readsExcluded &&
                    all.isNotEmpty()
                ) {
                    groups += FilterGroup("exclude", "Leave out", FilterType.MultiSelect, all)
                }
            }
        }
        return SourceResult.Ok(groups)
    }

    override suspend fun details(entry: SourceEntry): SourceResult<SourceEntry> = call(
        "getMangaDetails",
        JsonPrimitive(entry.url),
    ) { reply -> ResultParser.entry(reply, entry.url).copy(url = entry.url) }

    override suspend fun chapters(entry: SourceEntry): SourceResult<List<SourceChapter>> =
        call("getChapters", JsonPrimitive(entry.url)) { reply ->
            (reply as? JsonArray).orEmpty().map {
                ResultParser.chapter(entry.url, it)
            }
        }

    // The pages of a chapter. A source that hands its pages out one at a time gives stand ins, and each real page comes from getPageData, a few at once.
    override suspend fun pages(chapter: SourceChapter): SourceResult<List<SourcePage>> {
        val (titleId, chapterId) = splitChapterUrl(chapter.url)
        val details = call("getChapterDetails", JsonPrimitive(titleId), JsonPrimitive(chapterId)) {
            it as? JsonObject
                ?: throw ParseException("The chapter details are not an object")
        }
        val reply = (details as? SourceResult.Ok)?.value ?: return details.map { emptyList() }
        // A chapter that is a whole book, as a PDF or an EPUB the source points at, is read into words here.
        ResultParser.book(reply)?.let { book ->
            return runCatching { SourceResult.Ok(bookPages(book.url, book.headers)) }.getOrElse { problem ->
                if (problem is CancellationException) throw problem
                SourceResult.Err(SourceError.Parse(problem.message ?: "The book could not be read"))
            }
        }
        val given = (reply["pages"] as? JsonArray).orEmpty()
        val lazy = "getPageData" in methods && given.any(ResultParser::needsData)
        val resolved = if (!lazy) null else resolvePages(titleId, chapterId, given.size)
        return SourceResult.Ok(ResultParser.pages(reply, resolved))
    }

    // The videos of an episode, which only an anime source with the getVideos addition of Sumizuri has.
    override suspend fun videos(chapter: SourceChapter): SourceResult<List<SourceVideo>> {
        if ("getVideos" !in methods) return SourceResult.Err(SourceError.NotImplemented("getVideos"))
        val (titleId, chapterId) = splitChapterUrl(chapter.url)
        return call("getVideos", JsonPrimitive(titleId), JsonPrimitive(chapterId)) { ResultParser.videos(it) }
    }

    // Comments are not in the format yet, so the source never says it has them and the comment screens stay hidden.
    override suspend fun comments(entry: SourceEntry, sort: CommentSort, page: Int): SourceResult<CommentPage> =
        SourceResult.Err(SourceError.NotImplemented("comments"))

    override suspend fun chapterComments(
        chapter: SourceChapter,
        sort: CommentSort,
        page: Int,
    ): SourceResult<CommentPage> = SourceResult.Err(SourceError.NotImplemented("comments"))

    override suspend fun commentReplies(commentId: String, page: Int): SourceResult<CommentPage> =
        SourceResult.Err(SourceError.NotImplemented("comments"))

    override suspend fun sourcePreferences(): SourceResult<List<SourcePreference>> =
        SourceResult.Ok(preferencesOf(schema))

    override suspend fun preferences(): Map<String, Any?> = host.storage.preferenceMap().mapValues {
        primitiveValue(it.value)
    }

    override suspend fun setPreference(key: String, value: Any?) = host.storage.putPreference(key, anyToJson(value))

    override fun close() {
        runtime.close()
        host.close()
    }

    // One page of a list. The extension hands back what to ask for the next page, which is kept for that list, and a page with nothing to ask after it is the last.
    private suspend fun list(
        feed: JsonElement,
        query: String,
        tags: List<String>,
        page: Int,
        sort: String? = null,
        excluded: List<String> = emptyList(),
    ): SourceResult<List<SourceEntry>> {
        val key = listOf(
            (feed as? JsonPrimitive)?.content.orEmpty(),
            query,
            tags.joinToString(","),
            sort.orEmpty(),
            excluded.joinToString(","),
        ).joinToString("|")
        val metadata = cursorLock.withLock {
            val cursor = cursors.getOrPut(key) { Cursor() }
            val end = cursor.end
            if (end != null && page > end) return SourceResult.Ok(emptyList())
            if (page <= 1) JsonNull else cursor.pages[page] ?: buildJsonObject { put("page", page) }
        }
        val request = buildJsonObject {
            put("title", query)
            if (feed !is JsonNull) put("feed", feed)
            put("includedTags", buildJsonArray { tags.forEach { add(buildJsonObject { put("id", it) }) } })
            put("excludedTags", buildJsonArray { excluded.forEach { add(buildJsonObject { put("id", it) }) } })
            sort?.let { put("sortId", it) }
        }
        return call("getSearchResults", request, metadata) { reply ->
            val answer = reply as? JsonObject ?: throw ParseException("The search results are not an object")
            val next = answer["metadata"]
            val results = (answer["results"] as? JsonArray).orEmpty().mapNotNull {
                runCatching { ResultParser.entry(it) }.getOrNull()
            }
            next to results
        }.let { result ->
            when (result) {
                is SourceResult.Ok -> {
                    val (next, results) = result.value
                    cursorLock.withLock {
                        val cursor = cursors.getOrPut(key) { Cursor() }
                        if (truthy(next)) cursor.pages[page + 1] = next!! else cursor.end = page
                    }
                    SourceResult.Ok(results)
                }

                is SourceResult.Err -> result
            }
        }
    }

    private suspend fun resolvePages(titleId: String, chapterId: String, count: Int): List<String?> = coroutineScope {
        val resolved = arrayOfNulls<String>(count)
        (0 until count).chunked(PagesAtOnce).forEach { batch ->
            batch
                .map { index ->
                    async {
                        val reply =
                            call(
                                "getPageData",
                                JsonPrimitive(titleId),
                                JsonPrimitive(chapterId),
                                JsonPrimitive(index),
                            ) { it }
                        resolved[index] = (reply as? SourceResult.Ok)?.value?.let(ResultParser::pageData)
                    }
                }.awaitAll()
        }
        resolved.toList()
    }

    // The settings for a call: the defaults of the schema, then what the reader saved, each as text, as App.getSourceSetting gives them.
    private suspend fun settings(): Map<String, String> {
        val values = mutableMapOf<String, String>()
        for (field in schema) {
            val key = ResultParser.text(field, "key") ?: continue
            field["default"]?.let { values[key] = settingText(it) }
        }
        host.storage.preferenceMap().forEach { (key, value) -> values[key] = settingText(value) }
        return values
    }

    // Each call is timed for the performance page, the ones that fail too, apart from a method the source simply lacks.
    private suspend fun <T> call(method: String, vararg args: JsonElement, read: (JsonElement) -> T): SourceResult<T> {
        val started = TimeSource.Monotonic.markNow()
        fun record(ok: Boolean) = Perf.recordCall(info.name, started.elapsedNow().inWholeMilliseconds, ok)
        return try {
            val reply = withTimeout(callTimeoutMs) { runtime.call(method, args.toList(), settings()) }
            val value = read(reply)
            record(ok = true)
            AppLog.debug(info.name, "$method ok in ${started.elapsedNow().inWholeMilliseconds} ms")
            SourceResult.Ok(value)
        } catch (error: TimeoutCancellationException) {
            record(ok = false)
            AppLog.warn(info.name, "$method timed out after ${waited()}")
            SourceResult.Err(SourceError.Network("The source did not answer within ${waited()}."))
        } catch (error: CancellationException) {
            throw error
        } catch (error: ParseException) {
            record(ok = false)
            AppLog.warn(info.name, "$method gave a reply that could not be read: ${error.message}")
            SourceResult.Err(SourceError.Parse(error.message ?: "Unreadable reply"))
        } catch (error: Exception) {
            val failure = classifyFailure(method, error.message ?: error.toString())
            if (failure is SourceError.NotImplemented) {
                AppLog.debug(info.name, "$method is not offered")
            } else {
                record(ok = false)
                AppLog.warn(info.name, "$method failed, ${failure::class.simpleName}: ${failure.message.take(300)}")
            }
            SourceResult.Err(failure)
        }
    }

    private fun waited() = if (callTimeoutMs < 1000) "$callTimeoutMs ms" else "${callTimeoutMs / 1000} seconds"

    companion object {
        // Loads an installed extension and reads what its repo entry and its Source say about it.
        suspend fun open(
            installed: InstalledSource,
            scripts: EngineScripts,
            host: StandardHost,
            callTimeoutMs: Long = 90_000,
        ): ExtensionSource {
            val runtime = ExtensionRuntime.open(installed.id, installed.code, scripts, host.bridge)
            try {
                val extra = runCatching { Json.parseToJsonElement(installed.extra) }.getOrNull() as? JsonObject
                val schema = (extra?.get("settingsSchema") as? JsonArray)
                    .orEmpty()
                    .mapNotNull { it as? JsonObject }
                    .filter { ResultParser.text(it, "type") != "section" && ResultParser.text(it, "key") != null }
                val methods = runtime.shape.methods
                val info = SourceInfo(
                    name = installed.name,
                    lang = installed.lang,
                    iconUrl = installed.iconUrl.ifEmpty { null },
                    baseUrl = installed.baseUrl.ifEmpty { null },
                    hasDetails = true,
                    hasFilters = "getSearchTags" in methods || "getSortOptions" in methods,
                    hasCatalogs = runtime.shape.feeds.size > 2,
                    hasPreferences = schema.isNotEmpty(),
                )
                return ExtensionSource(runtime, host, info, schema, callTimeoutMs)
            } catch (error: Throwable) {
                runtime.close()
                throw error
            }
        }
    }
}

// The same result with its value changed, an error kept as it is.
private inline fun <T, R> SourceResult<T>.map(change: (T) -> R): SourceResult<R> = when (this) {
    is SourceResult.Ok -> SourceResult.Ok(change(value))
    is SourceResult.Err -> this
}
