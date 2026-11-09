package com.sumizuri.app.feature.title

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.backup.ImportedSources
import com.sumizuri.app.data.db.download.DownloadEntity
import com.sumizuri.app.data.download.AutoDownloads
import com.sumizuri.app.data.download.Downloader
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.library.SeasonCovers
import com.sumizuri.app.data.model.Chapter
import com.sumizuri.app.data.model.ChapterFilter
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.Facet
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.CoverFocusRepository
import com.sumizuri.app.data.settings.LibraryPrefsRepository
import com.sumizuri.app.data.settings.SessionRepository
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.sync.TitleSync
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.feature.title.chapter.continueTargetOf
import com.sumizuri.app.feature.title.chapter.seasonLookupNames
import com.sumizuri.app.feature.title.chapter.seasonNumbers
import com.sumizuri.app.source.SourceError
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.browser.ChallengeSolver
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.originIdOf
import com.sumizuri.app.source.valueOrNull
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// A title asked this recently is not asked again when its page opens.
private const val FreshForMs = 5 * 60 * 1000L

// A saved title. It shows what the database has and asks the source again in the background.
@OptIn(ExperimentalCoroutinesApi::class)
class TitleViewModel(
    private val titleId: Long,
    private val library: LibraryRepository,
    private val sync: TitleSync,
    private val sources: SourceRepository,
    private val session: SessionRepository,
    private val focus: CoverFocusRepository,
    private val manager: SourceManager,
    private val solver: ChallengeSolver,
    prefs: LibraryPrefsRepository,
    private val downloads: Downloader,
    private val auto: AutoDownloads,
    private val covers: SeasonCovers,
    private val settings: SettingsRepository,
) : ViewModel() {
    private val loading = MutableStateFlow(true)
    private val error = MutableStateFlow<SourceError?>(null)
    private val sourceName = MutableStateFlow<String?>(null)
    private val comments = MutableStateFlow<CommentsTarget?>(null)
    private val look = MutableStateFlow(Look())

    // The title whose chapters the list shows: this one, or the same title by volume, or by chapter for a list by volume. The page stays this title either way.
    private val listId = MutableStateFlow(titleId)
    private var otherId: Long? = null

    // True when this title is the list by volume of another saved title.
    private val isVolumes = MutableStateFlow(false)

    // The posters found for the seasons of an anime, when the person lets the app look them up.
    private val seasonArt = MutableStateFlow<Map<String, String>>(emptyMap())
    private val volumeSwitch = combine(library.volumesIdOf(titleId), isVolumes, listId) { volumesId, volumes, shown ->
        val onOther = shown != titleId
        if (volumesId != null) {
            onOther
        } else if (volumes) {
            !onOther
        } else {
            null
        }
    }

    // The page starts with the title as the library already has it, so the top of the page is there on the first frame and does not come in while the page slides open. Only the chapters fill in after.
    @OptIn(ExperimentalCoroutinesApi::class)
    val state: StateFlow<TitleState> = combine(
        library.title(titleId),
        // The rows and the chapter to continue with are worked out when the chapters or their order change, not each time a chapter is picked or the look changes. The chapter to continue with is one of the groups, languages and labels the title shows.
        combine(
            listId.flatMapLatest { library.chapters(it) },
            session.chapterLook.map { it.sort }.distinctUntilChanged(),
            session.hiddenFacets(titleId),
        ) { chapters, sort, hidden ->
            val items = chapters.map { it.toItem() }
            val shown = if (hidden.isEmpty()) items else items.filter { it.facets().none(hidden::contains) }
            items to continueTargetOf(shown, nowMillis(), sort)
        },
        combine(loading, error, sourceName, volumeSwitch, ::PageStatus),
        combine(
            look,
            prefs.prefs.map { it.favoritesEnabled },
            comments,
            listId.flatMapLatest { downloads.observeOf(it) },
            seasonArt,
        ) { now, favorites, talk, saved, art -> PageExtras(now, favorites, talk, saved, art) },
    ) { title, (items, target), (isLoading, message, source, switch), (now, favorites, talk, saved, art) ->
        TitleState(
            title = title,
            sourceName = source,
            chapters = items,
            loading = isLoading,
            error = message?.message,
            challengeUrl = (message as? SourceError.Challenge)?.url,
            oldestFirst = now.oldestFirst,
            grid = now.grid,
            gridPictures = now.pictures,
            hideDuplicates = now.hideDuplicates,
            sort = now.sort,
            filter = now.filter,
            hidden = now.hidden,
            selected = now.selected,
            target = target,
            focus = now.focus,
            favoritesEnabled = favorites,
            comments = talk,
            downloads = saved,
            seasonCovers = art,
            volumeSwitch = switch,
        ).also { ahead ->
            // The order of the chapters and what else is worked out from all of them is done here, away from the thread that draws, and kept for the next state of the same chapters.
            ahead.shown
            ahead.facets
            ahead.furthestRead
        }
    }.flowOn(Dispatchers.Default).stateIn(
        viewModelScope,
        SharingStarted.WhileSubscribed(5_000),
        TitleState(title = library.cachedTitle(titleId), loading = true),
    )

    // What the page does to its chapters, on the list it shows.
    val chapters = TitleChapterActions(viewModelScope, library, downloads, auto, look, listId) { state.value }

    init {
        // The seasons are looked up again when their names, the title or its place in the library change. A title in the library keeps what was found.
        viewModelScope.launch {
            combine(
                library.title(titleId),
                listId.flatMapLatest { library.chapters(it) },
                settings.flag(SettingKey.AniListSeasonCovers, true),
            ) { title, chapters, on ->
                if (!on || title == null || title.kind != Kind.Anime) {
                    null
                } else {
                    val seasons = chapters.map { it.season to it.seasonName }
                    SeasonAsk(
                        title.inLibrary,
                        title.name,
                        seasonLookupNames(title.name, seasons),
                        seasonNumbers(seasons),
                    )
                }
            }.distinctUntilChanged().collectLatest { wanted ->
                if (wanted == null || wanted.names.isEmpty()) {
                    seasonArt.value = emptyMap()
                    return@collectLatest
                }
                seasonArt.value = covers.posters(wanted.show, wanted.names, wanted.numbers, keep = wanted.keep)
            }
        }
        viewModelScope.launch { look.update { it.copy(focus = focus.get(titleId)) } }
        // The page is kept while the profile is open, so it follows the choices of the chapter list as they change, wherever they are changed, and not only as they were when it was made.
        viewModelScope.launch {
            session.chapterLook.collect { chosen ->
                look.update {
                    it.copy(
                        oldestFirst = chosen.oldestFirst,
                        grid = chosen.grid,
                        pictures = chosen.pictures,
                        hideDuplicates = chosen.hideDuplicates,
                        sort = chosen.sort,
                        filter = chosen.filter,
                    )
                }
            }
        }
        viewModelScope.launch {
            session.hiddenFacets(titleId).collect { hidden -> look.update { it.copy(hidden = hidden) } }
        }
        viewModelScope.launch {
            val origin = library.origin(titleId)
            val found = sources.find(origin?.sourceId)
            sourceName.value =
                found?.name ?: origin?.let { ImportedSources.labelOf(it.sourceId) ?: originIdOf(it.sourceId) }
            // The comments tile shows when the code of the source says it has comments.
            if (origin != null) isVolumes.value = library.mainOfVolumes(origin.sourceId, origin.externalId) != null
            val installed = found?.takeIf { it.enabled }
            if (origin != null && installed != null) {
                val opened = manager.open(installed).valueOrNull()
                if (opened?.info?.hasComments == true) {
                    comments.value = CommentsTarget(
                        installed.id,
                        origin.externalId,
                        library
                            .title(titleId)
                            .first()
                            ?.name
                            .orEmpty(),
                    )
                }
            }
        }
        // A title asked a moment ago, here or by the check of the library, is not asked again just for being opened. The refresh button still asks.
        if (sync.isFresh(titleId, FreshForMs)) loading.value = false else onRefresh()
        // A title last shown by volume opens by volume again.
        if (VolumeViews.showing(titleId)) onSwitchVolumes()
    }

    // Turns the list between the chapters and the volumes of the title, on this same page. The other list is a title of its own, saved out of the library the first time, so its reading is kept like any other.
    fun onSwitchVolumes() {
        if (listId.value != titleId) {
            look.update { it.copy(selected = emptySet()) }
            listId.value = titleId
            VolumeViews.remember(titleId, false)
            return
        }
        viewModelScope.launch {
            val other = otherId ?: findOther()?.also { otherId = it } ?: return@launch
            look.update { it.copy(selected = emptySet()) }
            listId.value = other
            VolumeViews.remember(titleId, true)
            if (!sync.isFresh(other, FreshForMs)) refreshList(other)
        }
    }

    // The other list of this title: its volumes, or the title its volumes belong to.
    private suspend fun findOther(): Long? {
        val origin = library.origin(titleId) ?: return null
        if (isVolumes.value) return library.mainOfVolumes(origin.sourceId, origin.externalId)
        val volumesId = library.volumesIdOf(titleId).first() ?: return null
        val entry = SourceEntry(url = volumesId, title = library.nameOf(titleId))
        return library.savedId(origin.sourceId, entry)
            ?: library.addFromSource(
                origin.sourceId,
                state.value.title?.kind ?: Kind.Manga,
                entry,
                emptyList(),
                inLibrary = false,
            )
    }

    // Asks the source again for the list that is shown.
    fun onRefresh() = refreshList(listId.value)

    private fun refreshList(id: Long) {
        loading.value = true
        error.value = null
        viewModelScope.launch {
            error.value = sync.refresh(id)
            loading.value = false
        }
    }

    // Opens the site for a person to pass the bot check, then asks again.
    fun onSolve() {
        val url = (error.value as? SourceError.Challenge)?.url ?: return
        viewModelScope.launch {
            solver.solve(url)
            onRefresh()
        }
    }

    // Switches the source of this title back on and asks it again.
    fun onEnableSource() {
        viewModelScope.launch {
            val origin = library.origin(titleId) ?: return@launch
            sources.setEnabled(origin.sourceId, true)
            onRefresh()
        }
    }

    fun onToggleSort() {
        val next = !look.value.oldestFirst
        look.update { it.copy(oldestFirst = next) }
        viewModelScope.launch { session.setOldestFirst(next) }
    }

    fun onToggleGrid() {
        val next = !look.value.grid
        look.update { it.copy(grid = next) }
        viewModelScope.launch { session.setChapterGrid(next) }
    }

    fun onToggleGridPictures() {
        val next = !look.value.pictures
        look.update { it.copy(pictures = next) }
        viewModelScope.launch { session.setChapterPictures(next) }
    }

    fun onToggleDuplicates() {
        val next = !look.value.hideDuplicates
        look.update { it.copy(hideDuplicates = next) }
        viewModelScope.launch { session.setHideDuplicates(next) }
    }

    // Which chapters show by their marks, for every title.
    fun onFilter(filter: ChapterFilter) {
        look.update { it.copy(filter = filter) }
        viewModelScope.launch { session.setChapterFilter(filter) }
    }

    // The groups, languages and labels whose chapters this title hides.
    fun onHideFacets(hidden: Set<Facet>) {
        look.update { it.copy(hidden = hidden) }
        viewModelScope.launch { session.setHiddenFacets(titleId, hidden) }
    }

    fun onSort(sort: ChapterSort) {
        look.update { it.copy(sort = sort) }
        viewModelScope.launch { session.setChapterSort(sort) }
    }

    fun onToggleLibrary() {
        val title = state.value.title ?: return
        viewModelScope.launch { library.setInLibrary(titleId, !title.inLibrary) }
    }

    fun onToggleFavorite() {
        val title = state.value.title ?: return
        viewModelScope.launch { library.setFavorite(setOf(titleId), !title.favorite) }
    }

    fun onSetFocus(x: Float, y: Float) {
        look.update { it.copy(focus = x to y) }
        viewModelScope.launch { focus.set(titleId, x, y) }
    }

    fun onClearFocus() {
        look.update { it.copy(focus = null) }
        viewModelScope.launch { focus.clear(titleId) }
    }
}

// What the posters of the seasons of a title are looked up by: whether it is kept in the library, the name of the show, and the name and the number of each season by its key.
private data class SeasonAsk(
    val keep: Boolean,
    val show: String,
    val names: Map<String, String>,
    val numbers: Map<String, Int>,
)
