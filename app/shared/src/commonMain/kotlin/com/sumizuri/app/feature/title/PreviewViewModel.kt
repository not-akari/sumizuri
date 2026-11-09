package com.sumizuri.app.feature.title

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.library.SeasonCovers
import com.sumizuri.app.data.model.ChapterSort
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.settings.SessionRepository
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.feature.browse.asTitle
import com.sumizuri.app.feature.comments.CommentsTarget
import com.sumizuri.app.feature.title.chapter.seasonLookupNames
import com.sumizuri.app.feature.title.chapter.seasonNumbers
import com.sumizuri.app.source.SourceError
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.browser.ChallengeSolver
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.source.valueOrNull
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch

// An entry of a source that is not saved yet. It is read from the source alone and saved when the user asks.
class PreviewViewModel(
    private val installed: InstalledSource,
    private var entry: SourceEntry,
    private val manager: SourceManager,
    private val library: LibraryRepository,
    private val session: SessionRepository,
    private val solver: ChallengeSolver,
    private val covers: SeasonCovers,
    private val settings: SettingsRepository,
) : ViewModel() {
    private var chapters = emptyList<SourceChapter>()

    // The volumes of the title, for a source that also lists it by volume, once asked, and whether the list shows them.
    private var volumes: List<SourceChapter>? = null
    private var showingVolumes = false
    private var saving = false

    private val mutableState = MutableStateFlow(
        TitleState(entry.asTitle(installed.kind, installed.id), installed.name, loading = true, preview = true),
    )
    val state: StateFlow<TitleState> = mutableState

    init {
        // The choices of the chapter list are followed as they change, as on the page of a saved title.
        viewModelScope.launch {
            session.chapterLook.collect { chosen ->
                mutableState.update {
                    it.copy(
                        oldestFirst = chosen.oldestFirst,
                        grid = chosen.grid,
                        gridPictures = chosen.pictures,
                        hideDuplicates = chosen.hideDuplicates,
                        sort = chosen.sort,
                    )
                }
            }
        }
        viewModelScope.launch { load() }
    }

    fun onToggleSort() {
        val next = !mutableState.value.oldestFirst
        mutableState.update { it.copy(oldestFirst = next) }
        viewModelScope.launch { session.setOldestFirst(next) }
    }

    fun onToggleGrid() {
        val next = !mutableState.value.grid
        mutableState.update { it.copy(grid = next) }
        viewModelScope.launch { session.setChapterGrid(next) }
    }

    fun onToggleGridPictures() {
        val next = !mutableState.value.gridPictures
        mutableState.update { it.copy(gridPictures = next) }
        viewModelScope.launch { session.setChapterPictures(next) }
    }

    fun onToggleDuplicates() {
        val next = !mutableState.value.hideDuplicates
        mutableState.update { it.copy(hideDuplicates = next) }
        viewModelScope.launch { session.setHideDuplicates(next) }
    }

    fun onSort(sort: ChapterSort) {
        mutableState.update { it.copy(sort = sort) }
        viewModelScope.launch { session.setChapterSort(sort) }
    }

    fun onRefresh() {
        mutableState.update { it.copy(loading = true, error = null, challengeUrl = null) }
        viewModelScope.launch { load() }
    }

    // Saves the entry with the chapters read so far, then tells the caller the id of the saved title.
    fun onAdd(onSaved: (Long) -> Unit) {
        if (saving || mutableState.value.loading) return
        saving = true
        viewModelScope.launch {
            val id = library.addFromSource(installed.id, installed.kind, entry, chapters)
            saving = false
            onSaved(id)
        }
    }

    // Saves the entry out of the library so the chapter has a place to keep its reading, then tells the caller the title and the chapter to open. A chapter of the preview is known by its place in the list from the source, plus one. A volume is saved with the volumes of the title, which then opens on its volumes.
    fun onRead(chapter: Long, onOpen: (Long, Long) -> Unit) {
        val volumeList = volumes.takeIf { showingVolumes }
        val picked = (volumeList ?: chapters).getOrNull((chapter - 1).toInt()) ?: return
        if (saving || mutableState.value.loading) return
        saving = true
        viewModelScope.launch {
            val id = library.addFromSource(installed.id, installed.kind, entry, chapters, inLibrary = false)
            val volumeEntry = volumeEntry()
            val chapterId = if (volumeList != null && volumeEntry != null) {
                library.applyDetails(id, entry)
                VolumeViews.remember(id, true)
                library.chapterIdOf(
                    library.addFromSource(installed.id, installed.kind, volumeEntry, volumeList, inLibrary = false),
                    picked.url,
                )
            } else {
                library.chapterIdOf(id, picked.url)
            }
            saving = false
            if (chapterId != null) onOpen(id, chapterId)
        }
    }

    // Turns the list between the chapters and the volumes of the title. The volumes are asked of the source the first time.
    fun onSwitchVolumes() {
        if (saving || mutableState.value.loading || entry.volumesId == null) return
        showingVolumes = !showingVolumes
        val asked = volumes
        if (!showingVolumes || asked != null) {
            showList()
            return
        }
        mutableState.update { it.copy(loading = true, error = null, challengeUrl = null, volumeSwitch = true) }
        viewModelScope.launch { load() }
    }

    // The same title by volume, as the source names it.
    private fun volumeEntry(): SourceEntry? = entry.volumesId?.let { SourceEntry(url = it, title = entry.title) }

    private fun showList() {
        mutableState.update {
            it.copy(
                chapters = items((if (showingVolumes) volumes else null) ?: chapters),
                selected = emptySet(),
                loading = false,
                volumeSwitch = if (entry.volumesId !=
                    null
                ) {
                    showingVolumes
                } else {
                    null
                },
            )
        }
        lookUpSeasons()
    }

    // The posters of the seasons of an anime, looked up when the person lets the app do so. A preview keeps them only a few minutes.
    private var seasonLookup: Job? = null

    private fun lookUpSeasons() {
        val shown = mutableState.value
        seasonLookup?.cancel()
        if (installed.kind != Kind.Anime) return
        val seasons = shown.chapters.map { it.season to it.seasonName }
        val names = seasonLookupNames(entry.title, seasons)
        if (names.isEmpty()) return
        seasonLookup = viewModelScope.launch {
            if (!settings.flag(SettingKey.AniListSeasonCovers, true).first()) return@launch
            val found = covers.posters(entry.title, names, seasonNumbers(seasons), keep = false)
            mutableState.update { it.copy(seasonCovers = found) }
        }
    }

    private suspend fun load() {
        val source = when (val opened = manager.open(installed)) {
            is SourceResult.Err -> return fail(opened.error)
            is SourceResult.Ok -> opened.value
        }
        // The comments tile shows when the code of the source says it has comments.
        if (source.info.hasComments) {
            mutableState.update {
                it.copy(comments = CommentsTarget(installed.id, entry.url, entry.title))
            }
        }
        // Details are optional. A source without them keeps the entry from the listing.
        source.details(entry).valueOrNull()?.let { entry = merge(entry, it) }
        mutableState.update { it.copy(title = entry.asTitle(installed.kind, installed.id)) }
        // The list that is shown is asked again: the chapters, or the volumes for a source that lists the title both ways.
        val volumeEntry = volumeEntry().takeIf { showingVolumes }
        when (val result = source.chapters(volumeEntry ?: entry)) {
            is SourceResult.Err -> fail(result.error)

            is SourceResult.Ok -> {
                if (volumeEntry != null) volumes = result.value else chapters = result.value
                showList()
            }
        }
    }

    private fun fail(error: SourceError) = mutableState.update {
        it.copy(loading = false, error = error.message, challengeUrl = (error as? SourceError.Challenge)?.url)
    }

    // Opens the site for a person to pass the bot check, then asks again.
    fun onSolve() {
        val url = mutableState.value.challengeUrl ?: return
        viewModelScope.launch {
            solver.solve(url)
            onRefresh()
        }
    }

    // What the details leave empty is filled from the listing.
    private fun merge(listed: SourceEntry, details: SourceEntry) = details.copy(
        url = listed.url,
        title = details.title.ifBlank { listed.title },
        coverUrl = details.coverUrl ?: listed.coverUrl,
    )

    private fun items(list: List<SourceChapter>): List<ChapterItem> = list
        .mapIndexed { index, chapter ->
            val number = chapter.number ?: (list.size - index).toDouble()
            ChapterItem(
                key = "$index${chapter.url}",
                id = index + 1L,
                number = number,
                name = chapter.title.takeIf { it.isNotBlank() },
                at = chapter.uploadedAt ?: 0,
                read = false,
                season = chapter.season,
                seasonName = chapter.seasonName,
                seasonCoverUrl = chapter.seasonCoverUrl,
                sourceOrder = index,
                scanlator = chapter.scanlator?.trim()?.takeIf { it.isNotEmpty() },
                language = chapter.language,
                volume = chapter.volume,
                tags = chapter.tags,
            )
        }.sortedByDescending { it.number }
}
