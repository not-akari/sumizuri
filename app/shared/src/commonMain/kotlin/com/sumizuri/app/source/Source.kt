package com.sumizuri.app.source

import com.sumizuri.app.source.model.CommentPage
import com.sumizuri.app.source.model.CommentSort
import com.sumizuri.app.source.model.FilterGroup
import com.sumizuri.app.source.model.SourceCatalog
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.model.SourceInfo
import com.sumizuri.app.source.model.SourcePage
import com.sumizuri.app.source.model.SourcePreference
import com.sumizuri.app.source.model.SourceVideo

// What the rest of the app talks to, whatever kind of extension is behind it.
interface Source {
    val info: SourceInfo

    suspend fun search(
        query: String,
        page: Int = 1,
        filters: Map<String, Any?> = emptyMap(),
    ): SourceResult<List<SourceEntry>>
    suspend fun popular(page: Int = 1): SourceResult<List<SourceEntry>>
    suspend fun latest(page: Int = 1): SourceResult<List<SourceEntry>>
    suspend fun details(entry: SourceEntry): SourceResult<SourceEntry>
    suspend fun chapters(entry: SourceEntry): SourceResult<List<SourceChapter>>

    // With books off, a chapter that is a whole PDF or EPUB gives no pages, and the file is not fetched.
    suspend fun pages(chapter: SourceChapter, books: Boolean = true): SourceResult<List<SourcePage>>
    suspend fun videos(chapter: SourceChapter): SourceResult<List<SourceVideo>>

    // The settings a search can use. Only a source that says it has filters has any.
    suspend fun filters(): SourceResult<List<FilterGroup>>

    // The extra named lists, and one of them a page at a time.
    suspend fun catalogs(): SourceResult<List<SourceCatalog>>
    suspend fun catalog(id: String, page: Int = 1): SourceResult<List<SourceEntry>>

    // The comments of a title or a chapter a page at a time, from page 1, and the replies of one comment by its key.
    suspend fun comments(
        entry: SourceEntry,
        sort: CommentSort = CommentSort.Newest,
        page: Int = 1,
    ): SourceResult<CommentPage>
    suspend fun chapterComments(
        chapter: SourceChapter,
        sort: CommentSort = CommentSort.Newest,
        page: Int = 1,
    ): SourceResult<CommentPage>
    suspend fun commentReplies(commentId: String, page: Int = 1): SourceResult<CommentPage>

    // The settings the source lets the reader change, and the values chosen so far.
    suspend fun sourcePreferences(): SourceResult<List<SourcePreference>>
    suspend fun preferences(): Map<String, Any?>
    suspend fun setPreference(key: String, value: Any?)

    // Frees the script runtime. The source cannot be used after this.
    fun close()
}
