package com.sumizuri.app.data.backup

import androidx.room3.withWriteTransaction
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.library.ChapterCarry
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.model.Title
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.work.BusyKind
import com.sumizuri.app.data.work.BusyWork
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.model.SourceEntry
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.source.repo.originId
import com.sumizuri.app.source.repo.originIdOf
import com.sumizuri.app.source.valueOrNull
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.flow.updateAndGet
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withPermit

// How many titles are worked on at once, and how many of them may ask one source at the same time, so one slow site cannot hold the rest.
private const val AtOnce = 6
private const val PerSource = 2

// Links titles that came from a backup without a source of their own to the same source installed here: one on the site of the title, or, as a backup of another app often keeps no site, one of the name the backup gave. The address of the title is tried on it, and when the source knows the title, the title is given to it, keeping its row, its shelves, its marks and its bookmarks. Nothing is searched for by name: a title with no such source, or one the source does not know at that address, waits to be moved on the page that moves titles, where the person picks the sources and checks each match. Only the details of the source are read: the chapters the title brought from the backup hold its marks until the source's own chapters are read, when the title is opened or the library is checked, and then give way to them.
class SourceMatcher(
    private val db: AppDatabase,
    private val library: LibraryRepository,
    private val sources: SourceRepository,
    private val manager: SourceManager,
    private val carry: ChapterCarry,
) {
    // A look for sources started from the page of missing sources. It runs for as long as the app does, so it goes on when the page is left or the app is out of sight.
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val linkState = MutableStateFlow(LinkRun())
    val linking: StateFlow<LinkRun> = linkState
    private var linkJob: Job? = null

    // Starts linking these titles unless a look is running already.
    fun linkAll(titles: List<Title>) {
        if (linkJob?.isActive == true) return
        linkState.value = LinkRun(checking = 0 to titles.size)
        linkJob = scope.launch {
            BusyWork.keep(BusyKind.Linking, { linkState.value.checking }, ::stopLinking) {
                val count = match(candidatesOf(titles), { done, total ->
                    linkState.value =
                        LinkRun(checking = done to total)
                }, { false })
                linkState.value = LinkRun(found = count to titles.size)
            }
        }
    }

    // Stops the look. The titles linked so far stay linked.
    fun stopLinking() {
        linkJob?.cancel()
        linkState.update { it.copy(checking = null) }
    }

    // The titles of the library written as candidates, each with the address the source gave it and the name of the source it came from when that is known.
    suspend fun candidatesOf(titles: List<Title>): List<SourceCandidate> = titles.mapNotNull { title ->
        val origin = db.titles().origin(title.id) ?: return@mapNotNull null
        SourceCandidate(
            title.id,
            title.kind,
            origin.externalId,
            ImportedSources.nameOf(
                title.sourceId,
            ),
            originIdOf(title.sourceId).takeIf {
                !ImportedSources.isImported(title.sourceId)
            },
        )
    }

    // The ids of the candidates that still have no source of their own, which is the case for those that no source took.
    suspend fun waiting(candidates: List<SourceCandidate>): List<Long> = candidates
        .filter {
            db
                .titles()
                .origin(it.titleId)
                ?.sourceId
                ?.let(ImportedSources::isImported) == true
        }.map { it.titleId }

    // Gives how many titles were linked. A title with no same source installed is passed over at once, without asking any site. The rest are worked on a few at once, each source asked by only a few of them at a time.
    suspend fun match(
        candidates: List<SourceCandidate>,
        onProgress: (done: Int, total: Int) -> Unit,
        isCancelled: () -> Boolean,
    ): Int {
        val installed = sources.installed.first().filter { it.enabled }
        val lanes = installed.associate { it.id to Semaphore(PerSource) }
        val done = MutableStateFlow(0)
        val linked = MutableStateFlow(0)
        onProgress(0, candidates.size)
        val gate = Semaphore(AtOnce)
        coroutineScope {
            candidates
                .map { candidate ->
                    async {
                        val same = sourcesFor(candidate, installed)
                        if (same.isNotEmpty()) {
                            gate.withPermit {
                                if (!isCancelled() &&
                                    guarded(candidate) { tryEach(candidate, same, lanes) }
                                ) {
                                    linked.update { it + 1 }
                                }
                            }
                        }
                        onProgress(done.updateAndGet { it + 1 }, candidates.size)
                    }
                }.awaitAll()
        }
        AppLog.info(
            "backup",
            "${linked.value} of ${candidates.size} titles were linked to the same source installed here",
        )
        return linked.value
    }

    // Runs one try for a title, so a failure of one title is logged and does not stop the others.
    private suspend fun guarded(candidate: SourceCandidate, block: suspend () -> Boolean): Boolean = try {
        block()
    } catch (error: CancellationException) {
        throw error
    } catch (error: Exception) {
        AppLog.warn("backup", "linking title ${candidate.titleId} to its source failed, ${error.message}")
        false
    }

    // Tries the address of the title, in each form, on each of its same sources, and gives it to the first that knows it.
    private suspend fun tryEach(
        candidate: SourceCandidate,
        same: List<InstalledSource>,
        lanes: Map<String, Semaphore>,
    ): Boolean {
        for (installedSource in same) {
            val taken = lanes.getValue(installedSource.id).withPermit {
                val source = manager.open(installedSource).valueOrNull() ?: return@withPermit false
                // The address of the backup, in the forms another app may have kept it in, such as /series/name where this source knows it as name.
                for (address in addressesOf(candidate.url, installedSource.baseUrl)) {
                    // A title that is saved under that source already is left as it is.
                    if (db.titles().findId(installedSource.id, address) != null) return@withPermit false
                    val details = source.details(SourceEntry(url = address, title = "")).valueOrNull() ?: continue
                    // A source that answers for any address gives an empty page for a wrong one, so a name is needed to count.
                    if (details.title.isBlank()) continue
                    adopt(candidate.titleId, installedSource.id, details.copy(url = address))
                    return@withPermit true
                }
                false
            }
            if (taken) return true
        }
        return false
    }

    // The forms to try: the address as it is, without its leading folders, and as a whole link on the site of the source.
    private fun addressesOf(url: String, baseUrl: String): List<String> {
        val path = url
            .substringAfter(
                "://",
                url,
            ).let { if (url.contains("://")) "/" + it.substringAfter('/', "") else it }
        val last = path.trimEnd('/').substringAfterLast('/')
        val whole = if (url.startsWith("/") && baseUrl.isNotBlank()) baseUrl.trimEnd('/') + url else null
        return listOfNotNull(url, path.trimStart('/'), last, whole).filter { it.isNotBlank() }.distinct()
    }

    // Moves the title to the source at the address the source knows it by, with the details it gave. Its chapters from the backup stay and are marked as brought, so the source's own take their place the first time they are read.
    private suspend fun adopt(titleId: Long, sourceId: String, entry: SourceEntry) = db.withWriteTransaction {
        db.titles().setOrigin(titleId, sourceId, entry.url)
        library.applyDetails(titleId, entry)
        carry.mark(titleId)
    }

    // The installed sources that are the source the title came from: those on its site, then those of the name the backup gave.
    private fun sourcesFor(candidate: SourceCandidate, installed: List<InstalledSource>): List<InstalledSource> {
        val host = hostOf(candidate.url)
        val usable = installed.filter { it.kind == candidate.kind }
        // The same source installed from another repo, such as after the repo it first came from was removed, is tried first.
        val sameOrigin = candidate.originId?.let { origin -> usable.filter { it.originId == origin } }.orEmpty()
        val byHost = if (host ==
            null
        ) {
            emptyList()
        } else {
            usable.filter { it !in sameOrigin && hostOf(it.baseUrl) == host }
        }
        // Apps write the same source in different ways, such as Asura Scans and AsuraScans, so only the letters and numbers are compared.
        val wanted = candidate.sourceName?.let(::plainName)?.takeIf { it.isNotEmpty() }
        val byName = usable.filter {
            it !in sameOrigin && it !in byHost && wanted != null &&
                plainName(it.name) == wanted
        }
        return sameOrigin + byHost + byName
    }

    private fun plainName(name: String): String = name.lowercase().filter { it.isLetterOrDigit() }

    private fun hostOf(url: String): String? = HostPart
        .find(url)
        ?.groupValues
        ?.get(1)
        ?.lowercase()
        ?.removePrefix("www.")
}

// How a look for sources is going: how far it got while it runs, and how many titles found a source once it ended.
data class LinkRun(val checking: Pair<Int, Int>? = null, val found: Pair<Int, Int>? = null)

// The host of an address.
private val HostPart = Regex("^[a-zA-Z][a-zA-Z0-9+.-]*://([^/:?#]+)")
