package com.sumizuri.app.feature.share

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.blocks.ProfileBlocksRepository
import com.sumizuri.app.data.blocks.decodeBlock
import com.sumizuri.app.data.blocks.newBlockId
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.settings.ThemeRepository
import com.sumizuri.app.data.settings.importData
import com.sumizuri.app.data.share.Identified
import com.sumizuri.app.data.share.Incoming
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.ShareProblem
import com.sumizuri.app.data.share.ShareUnreadable
import com.sumizuri.app.data.share.SharedThing
import com.sumizuri.app.data.share.identify
import com.sumizuri.app.data.share.reposOf
import com.sumizuri.app.data.sources.RepoRepository
import com.sumizuri.app.feature.theme.newThemeId
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.serialization.json.jsonObject
import okio.Path

// Where the import page is: nothing chosen yet, reading, a thing to look at before it is taken, done, or a file it cannot read.
sealed interface ImportState {
    data object Empty : ImportState

    data object Reading : ImportState

    data object ToBackup : ImportState

    data class Ready(val thing: SharedThing) : ImportState

    // How many things were taken, how many there were, and a way to put things back as they were, for the kinds that have one.
    data class Done(
        val thing: SharedThing,
        val taken: Int = 1,
        val of: Int = taken,
        val undo: (suspend () -> Unit)? = null,
    ) : ImportState {
        val kind: ShareKind get() = thing.kind
    }

    data class Failed(val problem: ShareProblem) : ImportState
}

// Reads a file to be imported, shows it, and takes it when the person says so. A backup goes to the backup page, which reads it and asks how to restore it.
class ImportViewModel(
    private val settings: SettingsRepository,
    private val themes: ThemeRepository,
    private val blocks: ProfileBlocksRepository,
    private val repos: RepoRepository,
) : ViewModel() {
    private val mutable = MutableStateFlow<ImportState>(ImportState.Empty)
    val state: StateFlow<ImportState> = mutable

    fun onSource(path: Path) {
        mutable.value = ImportState.Reading
        viewModelScope.launch {
            mutable.value = try {
                when (val found = identify(path)) {
                    is Identified.Backup -> {
                        Incoming.offerBackup(found.path)
                        ImportState.ToBackup
                    }

                    is Identified.Small -> ImportState.Ready(found.thing)
                }
            } catch (error: CancellationException) {
                throw error
            } catch (error: ShareUnreadable) {
                ImportState.Failed(error.problem)
            } catch (error: Exception) {
                AppLog.warn("import", "could not read the file, ${error.message}")
                ImportState.Failed(ShareProblem.NotOurs)
            }
        }
    }

    fun onTake() {
        val thing = (mutable.value as? ImportState.Ready)?.thing ?: return
        mutable.value = ImportState.Reading
        viewModelScope.launch {
            mutable.value = try {
                take(thing)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                AppLog.warn("import", "could not take the ${thing.kind.id}, ${error.message}")
                ImportState.Failed(ShareProblem.Damaged)
            }
        }
    }

    fun onAgain() {
        mutable.value = ImportState.Empty
    }

    // Puts things back as they were and shows the thing again, so it can still be taken.
    fun onUndo() {
        val done = mutable.value as? ImportState.Done ?: return
        val undo = done.undo ?: return
        mutable.value = ImportState.Reading
        viewModelScope.launch {
            runCatching { undo() }.onFailure {
                AppLog.warn(
                    "import",
                    "could not undo the ${done.kind.id}, ${it.message}",
                )
            }
            mutable.value = ImportState.Ready(done.thing)
        }
    }

    private suspend fun take(thing: SharedThing): ImportState = when (thing.kind) {
        ShareKind.Settings -> {
            val data = thing.data.jsonObject
            ImportState.Done(thing, settings.importData(data), data.size)
        }

        ShareKind.Theme -> {
            val theme = themeOf(thing) ?: throw IllegalStateException("no theme in the file")
            val kept = theme.copy(id = AppThemeSpec.CustomPrefix + newThemeId())
            val before = themes.active.first().id
            themes.save(kept)
            themes.select(kept.id)
            ImportState.Done(thing) {
                themes.select(before)
                themes.delete(kept.id)
            }
        }

        ShareKind.Block -> {
            val block = decodeBlock(thing.data) ?: throw IllegalStateException("no block in the file")
            val id = newBlockId()
            blocks.update { it.copy(blocks = it.blocks + block.copy(id = id)) }
            ImportState.Done(thing) {
                blocks.update { layout ->
                    layout.copy(
                        blocks = layout.blocks.filterNot {
                            it.id ==
                                id
                        },
                    )
                }
            }
        }

        // Each new repo is checked over the network, so they are added side by side.
        ShareKind.Repos -> {
            val wanted = reposOf(thing).map { it.url }.distinct()
            val had = repos.repos
                .first()
                .map { it.url }
                .toSet()
            val added = coroutineScope {
                wanted
                    .filterNot { it in had }
                    .map { url ->
                        async {
                            url.takeIf {
                                repos.add(
                                    it,
                                ) == null
                            }
                        }
                    }.awaitAll()
                    .filterNotNull()
            }
            ImportState.Done(
                thing,
                added.size + wanted.count { it in had },
                wanted.size,
            ) { added.forEach { repos.remove(it) } }
        }

        ShareKind.Backup -> error("a backup goes to the backup page")
    }

    fun themeOf(thing: SharedThing): AppThemeSpec? = themes.fromData(thing.data)
}
