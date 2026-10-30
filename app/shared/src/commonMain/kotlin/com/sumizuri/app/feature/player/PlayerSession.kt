package com.sumizuri.app.feature.player

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.download.Downloader
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.data.model.player.AudioPreference
import com.sumizuri.app.data.model.player.PlayerPrefs
import com.sumizuri.app.data.settings.PlayerPrefsRepository
import com.sumizuri.app.data.settings.ReaderSettingsRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.playback.PlayerEngine
import com.sumizuri.app.playback.PlayerMedia
import com.sumizuri.app.playback.PlayerProblem
import com.sumizuri.app.playback.PlayerTrack
import com.sumizuri.app.playback.hls.expandHlsMasters
import com.sumizuri.app.playback.hls.isHls
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.reader_chapter_gone
import com.sumizuri.app.shared.resources.reader_source_missing
import com.sumizuri.app.shared.resources.reader_source_off
import com.sumizuri.app.source.SourceError
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.browser.ChallengeSolver
import com.sumizuri.app.source.model.SourceChapter
import com.sumizuri.app.source.model.SourceVideo
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeoutOrNull
import org.jetbrains.compose.resources.StringResource
import kotlin.math.abs

// How often the place is kept while playing, and how long a video may take to tell its length before it is called broken.
private const val SaveEveryMs = 5000L
private const val StartTimeoutMs = 30_000L

// How near its length an end must come to count as the end of the episode, a fiftieth of the length kept between these two, and what the log and the failure say when it comes before.
private const val EndSlackMs = 15_000L
private const val EndSlackMinMs = 2_000L

// A video shorter than this has no end the player trusts, since a broken stream reports lengths like that.
private const val ShortestEpisodeMs = 60_000L
private const val StoppedEarly = "The video stopped before its end, its stream could not be read"

// The episode list, the videos and the one that plays, behind the screen of the player. It opens episodes in place, picks the video the person likes, plays it from where it was left, keeps the place, starts again quietly when the connection drops, and goes on to the next episode when one ends.
internal class PlayerSession(
    private val engine: PlayerEngine,
    private val scope: CoroutineScope,
    private val library: LibraryRepository,
    private val sources: SourceRepository,
    private val manager: SourceManager,
    private val solver: ChallengeSolver,
    private val prefsRepository: PlayerPrefsRepository,
    private val reading: ReaderSettingsRepository,
    private val downloads: Downloader,
) {
    private val mutable = MutableStateFlow(SessionState())
    val state: StateFlow<SessionState> = mutable
    val log = PlaybackLog()

    private var place: ChapterPlace? = null
    private var currentId = 0L
    private var generation = 0
    private var lastSave = 0L
    private var recovering = false
    private var disposed = false
    private val retries = RetryBudget()
    private var extraSubtitles = emptyList<PlayerTrack>()
    private var incognito = false

    // Reads the choices, starts watching the engine and opens the episode.
    fun start(chapterId: Long) {
        scope.launch {
            mutable.update { it.copy(prefs = prefsRepository.prefs.first()) }
            launch { prefsRepository.prefs.collect { saved -> mutable.update { it.copy(prefs = saved) } } }
            watch()
            open(chapterId)
        }
    }

    // Changes the choices of the person, which are kept.
    fun updatePrefs(change: (PlayerPrefs) -> PlayerPrefs) {
        scope.launch { prefsRepository.update(change) }
    }

    fun nextEpisode() {
        val now = mutable.value
        now.episodes.getOrNull(now.index + 1)?.let { scope.launch { open(it.id) } }
    }

    fun previousEpisode() {
        val now = mutable.value
        now.episodes.getOrNull(now.index - 1)?.let { scope.launch { open(it.id) } }
    }

    fun openEpisode(id: Long) {
        if (id != currentId) scope.launch { open(id) }
    }

    fun retry() {
        scope.launch { open(currentId) }
    }

    // Opens the site for a person to pass the bot check, then asks for the videos again.
    fun solve() {
        val url = mutable.value.failure?.challengeUrl ?: return
        scope.launch {
            solver.solve(url)
            open(currentId)
        }
    }

    // Plays another of the videos of the episode from where this one is, and remembers its quality for the next episode.
    fun selectVideo(choice: SourceVideo) {
        if (choice == mutable.value.current) return
        val quality = choice.quality?.takeIf { it.isNotEmpty() }
        if (quality != null) scope.launch { prefsRepository.update { it.copy(preferredQuality = quality) } }
        val at = engine.state.value.positionMs
        val mine = ++generation
        log.add("Switching to ${choice.quality ?: "another video"}")
        setPhase(PlayerPhase.Loading)
        scope.launch { play(choice, mine, startAt = at) }
    }

    fun tryAnotherVideo() {
        val now = mutable.value
        val next = now.videos.indexOf(now.current) + 1
        now.videos.getOrNull(next)?.let(::selectVideo)
    }

    // Adds a subtitle file from the device to the video, which starts again at the same place with it, and turns it on.
    fun loadSubtitle(path: String, name: String) {
        val current = mutable.value.current ?: return
        val track = PlayerTrack(
            "file${extraSubtitles.size}",
            name,
            null,
            "file:///" + path.replace('\\', '/').removePrefix("/"),
        )
        extraSubtitles = extraSubtitles + track
        val before = engine.state.value
        log.add("Subtitle file: $name")
        engine.open(mediaOf(current, extraSubtitles), before.positionMs, play = before.playing)
        scope.launch {
            // The new track has its name when the engine keeps names, and is the last one in the list when it does not.
            val loaded = withTimeoutOrNull(5000) {
                engine.state.first { now ->
                    now.subtitles.size > before.subtitles.size ||
                        now.subtitles.any { it.label == name }
                }
            } ?: return@launch
            val added = loaded.subtitles.firstOrNull { it.label == name } ?: loaded.subtitles.lastOrNull()
            added?.let { engine.selectSubtitle(it.id) }
        }
    }

    // Keeps the place and lets go of what is watched. The engine is released by whoever made it.
    fun dispose() {
        generation++
        disposed = true
        val keep = snapshot()
        CoroutineScope(SupervisorJob() + Dispatchers.Default).launch { runCatching { save(keep) } }
    }

    private suspend fun open(id: Long) {
        save(snapshot())
        val mine = ++generation
        currentId = id
        retries.reset()
        extraSubtitles = emptyList()
        lastSave = 0
        mutable.update { it.copy(phase = PlayerPhase.Loading, failure = null, videos = emptyList(), current = null) }
        val here = library.chapterPlace(id) ?: return failSource(Res.string.reader_chapter_gone)
        place = here
        incognito = reading.observe(here.titleId).first().incognito
        refreshEpisodes(here.titleId)
        val now = mutable.value
        log.add("Episode ${now.index + 1} of ${now.episodes.size}: ${here.name ?: here.number}\n    ${here.url}")
        // A saved episode plays from the device, with no source and no connection.
        downloads.savedVideo(here.titleId, id)?.let { saved ->
            log.add("Playing the saved copy")
            mutable.update { it.copy(videos = listOf(saved)) }
            return play(saved, mine)
        }
        val found = sources.find(here.sourceId) ?: return failSource(Res.string.reader_source_missing)
        if (!found.enabled) return failSource(Res.string.reader_source_off)
        log.add("Asking ${found.name} for the videos...")
        val asked = nowMillis()
        val opened = when (val result = manager.open(found)) {
            is SourceResult.Err -> return failSource(result.error)
            is SourceResult.Ok -> result.value
        }
        val listed = when (val result = opened.videos(SourceChapter(url = here.url, title = ""))) {
            is SourceResult.Err -> return failSource(result.error)
            is SourceResult.Ok -> result.value
        }
        if (mine != generation) return
        log.add("The source answered in ${nowMillis() - asked} ms with ${listed.size} video(s)")
        listed.forEach { log.add("  ${describeVideo(it)}") }
        markAnime(listed, here.sourceId)
        val videos = withQualities(listed, log)
        if (mine != generation) return
        mutable.update { it.copy(videos = videos) }
        val prefs = mutable.value.prefs
        val choice = VideoChoice.pick(videos, prefs.preferredQuality, prefs.qualityMode, prefs.audioPreference)
        if (choice == null) {
            log.add("The source listed no videos for this episode", problem = true)
            return fail(PlayerFailure(FailureKind.NoVideos))
        }
        val liked = prefs.audioPreference.takeIf { it != AudioPreference.Any }
        val audio = liked?.let { ", ${it.name.lowercase()} preferred" }.orEmpty()
        log.add("Chose ${choice.quality ?: "the first video"} (${prefs.qualityMode.name.lowercase()}$audio)")
        play(choice, mine)
    }

    fun reloadEpisodes() {
        place?.let { scope.launch { refreshEpisodes(it.titleId) } }
    }

    // The chapters of the title in order, with the place of the open one in them.
    private suspend fun refreshEpisodes(titleId: Long) {
        val list = library.chaptersInOrder(titleId).first().map { EpisodeRef(it.id, it.number, it.name, it.read) }
        val index = list.indexOfFirst { it.id == currentId }.coerceAtLeast(0)
        mutable.update { it.copy(titleName = place?.titleName.orEmpty(), episodes = list, index = index) }
    }

    // Opens the video paused, waits for its length, goes to the place it was left, and plays. The place is the one given, or the one that was kept.
    private suspend fun play(choice: SourceVideo, mine: Int, startAt: Long? = null) {
        mutable.update { it.copy(current = choice) }
        log.add("Opening ${choice.quality ?: "video"}${startAt?.let { " at ${formatTime(it)}" } ?: ""}")
        val opened = nowMillis()
        engine.open(mediaOf(choice, extraSubtitles), 0, play = false)
        val ready = withTimeoutOrNull(StartTimeoutMs) { engine.state.first { it.durationMs > 0 || it.problem != null } }
        if (mine != generation) return
        if (ready == null) {
            log.add("The video gave no length within ${StartTimeoutMs / 1000} s, so it did not start", problem = true)
            return fail(PlayerFailure(FailureKind.DidNotStart))
        }
        if (ready.problem != null) {
            log.add("The video did not open: ${ready.message ?: ready.problem}", problem = true)
            return fail(failureOf(ready.problem, ready.message))
        }
        log.add("Video opened in ${nowMillis() - opened} ms, ${formatTime(ready.durationMs)} long")
        val kept = place?.position?.takeIf { mutable.value.prefs.resume }
        val at = startAt ?: kept?.let { PlaybackProgress.resume(it, ready.durationMs) }
        if (at != null && at > 0) {
            log.add("Resuming at ${formatTime(at)}")
            engine.seekTo(at)
        }
        choice.pairedAudio?.let { log.add("Sound: ${it.label}") }
        engine.play()
        log.add("Playing")
        setPhase(PlayerPhase.Ready)
        if (startAt == null) applyStartPreferences(mine)
    }

    // Applies the speed and the subtitle the person likes to a video that just started. A choice that cannot be applied never stops the episode.
    private suspend fun applyStartPreferences(mine: Int) {
        val prefs = mutable.value.prefs
        if (abs(prefs.speed - 1f) > 0.001f) {
            engine.setSpeed(prefs.speed)
            log.add("Speed ${prefs.speed}x")
        }
        if (!prefs.showSubtitles) {
            engine.selectSubtitle(null)
            log.add("Subtitles off, as set")
            return
        }
        val tracks = withTimeoutOrNull(3000) { engine.state.first { it.subtitles.isNotEmpty() } }?.subtitles
        if (mine != generation) return
        val choice = tracks?.let { VideoChoice.alwaysOn(it, emptyList(), prefs.subtitleLanguage) }?.track
        if (choice == null) {
            log.add("This episode has no subtitles")
            return
        }
        engine.selectSubtitle(choice.id)
        log.add("Subtitles: ${choice.label}")
    }

    // Watches the engine for what the session reacts to: the place to keep, the end of an episode, and errors.
    private fun watch() {
        scope.launch {
            var wasPlaying = false
            engine.state.collect { now ->
                if (mutable.value.phase != PlayerPhase.Ready) {
                    wasPlaying = now.playing
                    return@collect
                }
                if (now.playing && nowMillis() - lastSave >= SaveEveryMs) save(snapshot())
                if (wasPlaying && !now.playing && !now.ended) save(snapshot())
                wasPlaying = now.playing
            }
        }
        scope.launch {
            engine.state.map { it.buffering }.distinctUntilChanged().collect { buffering ->
                val note = if (buffering) "Buffering..." else "Buffering done"
                if (mutable.value.phase == PlayerPhase.Ready) log.add(note)
            }
        }
        scope.launch {
            engine.state.map { it.ended }.distinctUntilChanged().collect { ended ->
                if (ended && mutable.value.phase == PlayerPhase.Ready) onCompleted()
            }
        }
        scope.launch {
            engine.state.map { it.problem to it.message }.distinctUntilChanged().collect { (problem, message) ->
                if (problem == null || mutable.value.phase != PlayerPhase.Ready || recovering) return@collect
                onError(problem, message.orEmpty())
            }
        }
    }

    private suspend fun onError(problem: PlayerProblem, message: String) {
        log.add("Engine error: $message", problem = true)
        val position = engine.state.value.positionMs
        val network = PlayerErrors.isNetwork(message)
        if ((network || PlayerErrors.isGlitch(message)) && retries.take(position)) {
            val why = if (network) "Connection dropped" else "Playback stopped after a damaged piece"
            log.add("$why at ${formatTime(position)}: starting again from there", problem = true)
            scope.launch { recover(position) }
        } else {
            fail(failureOf(problem, message))
        }
    }

    // Opens the video again at the place it stopped, after a second.
    private suspend fun recover(at: Long) {
        val video = mutable.value.current ?: return
        recovering = true
        val mine = ++generation
        setPhase(PlayerPhase.Loading)
        try {
            delay(1000)
            if (mine == generation) play(video, mine, startAt = at)
        } finally {
            recovering = false
        }
    }

    private suspend fun onCompleted() {
        val now = engine.state.value
        // A stream that breaks off is reported by mpv as an end too. An end well before the length is such a break: it is tried once more from where it stopped, then shown as a failure, and never marks the episode watched or starts the next one, which once ran through a whole season in a minute. A broken stream can also give a length of almost nothing, the size of a picture it took the video for, so an end only counts for a video of a real length, with room that shrinks for a short one.
        val slack = (now.durationMs / 50).coerceIn(EndSlackMinMs, EndSlackMs)
        AppLog.info("player", "the video ended at ${now.positionMs} ms of ${now.durationMs} ms")
        if (now.durationMs < ShortestEpisodeMs || now.positionMs < now.durationMs - slack) {
            AppLog.warn("player", "that is not the end of the episode, it is treated as a failure")
            log.add(
                "The video stopped at ${formatTime(now.positionMs)} of ${formatTime(now.durationMs)}, before its end",
                problem = true,
            )
            // A stream no player can read is not tried again, since another start breaks the same way.
            val unreadable = now.message?.takeIf(PlayerErrors::isUnreadable)
            if (unreadable == null && retries.take(now.positionMs)) {
                scope.launch { recover(now.positionMs) }
            } else {
                fail(failureOf(PlayerProblem.Failed, unreadable ?: StoppedEarly))
            }
            return
        }
        log.add("Reached the end")
        save(Snapshot(now.durationMs, now.durationMs))
        val state = mutable.value
        if (state.prefs.autoNext && state.hasNext) {
            log.add("Starting the next episode")
            nextEpisode()
        }
    }

    private fun snapshot() = engine.state.value.let { Snapshot(it.positionMs, it.durationMs) }

    // Keeps how far the episode was watched, and marks it watched once enough of it was played.
    private suspend fun save(at: Snapshot) {
        val here = place ?: return
        if (incognito || mutable.value.phase != PlayerPhase.Ready) return
        val fraction = PlaybackProgress.fraction(at.positionMs, at.durationMs) ?: return
        lastSave = nowMillis()
        library.saveProgress(here.titleId, here.id, fraction, fraction * 100 >= mutable.value.prefs.watchedAt)
    }

    // A failure of the episode itself, such as a chapter that is gone or a source that is missing or turned off.
    private fun failSource(note: StringResource) = fail(PlayerFailure(FailureKind.Source, note = note))

    private fun failSource(error: SourceError) {
        log.add("The source failed: ${error.message}", problem = true)
        fail(PlayerFailure(FailureKind.Source, error.message, (error as? SourceError.Challenge)?.url))
    }

    private fun fail(failure: PlayerFailure) {
        if (disposed) return
        mutable.update { it.copy(phase = PlayerPhase.Failed, failure = failure) }
    }

    private fun setPhase(phase: PlayerPhase) {
        if (!disposed) mutable.update { it.copy(phase = phase) }
    }
}
