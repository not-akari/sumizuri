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
import com.sumizuri.app.data.share.ImportSource
import com.sumizuri.app.data.share.Incoming
import com.sumizuri.app.data.share.ShareKind
import com.sumizuri.app.data.share.ShareProblem
import com.sumizuri.app.data.share.ShareUnreadable
import com.sumizuri.app.data.share.SharedThing
import com.sumizuri.app.data.share.identify
import com.sumizuri.app.data.sources.RepoRepository
import com.sumizuri.app.feature.theme.newThemeId
import com.sumizuri.app.ui.theme.spec.AppThemeSpec
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject

// A repo in a file of repos.
data class SharedRepo(val url: String, val name: String)

// Where the import page is: nothing chosen yet, reading, a thing to look at before it is taken, done, or a file it cannot read.
sealed interface ImportState {
    data object Empty : ImportState

    data object Reading : ImportState

    data object ToBackup : ImportState

    data class Ready(val thing: SharedThing) : ImportState

    // How many things were taken, and how many there were.
    data class Done(val kind: ShareKind, val taken: Int, val of: Int) : ImportState

    data class Failed(val problem: ShareProblem) : ImportState
}

// Reads what is to be imported, shows it, and takes it when the person says so. A backup goes to the backup page, which reads it and asks how to restore it.
class ImportViewModel(
    private val settings: SettingsRepository,
    private val themes: ThemeRepository,
    private val blocks: ProfileBlocksRepository,
    private val repos: RepoRepository,
) : ViewModel() {
    private val mutable = MutableStateFlow<ImportState>(ImportState.Empty)
    val state: StateFlow<ImportState> = mutable

    fun onSource(source: ImportSource) {
        mutable.value = ImportState.Reading
        viewModelScope.launch {
            mutable.value = try {
                when (val found = identify(source)) {
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
                AppLog.warn("import", "could not read what was given, ${error.message}")
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

    private suspend fun take(thing: SharedThing): ImportState = when (thing.kind) {
        ShareKind.Settings -> {
            val data = thing.data.jsonObject
            ImportState.Done(ShareKind.Settings, settings.importData(data), data.size)
        }

        ShareKind.Theme -> {
            val theme = themeOf(thing) ?: throw IllegalStateException("no theme in the file")
            val kept = theme.copy(id = AppThemeSpec.CustomPrefix + newThemeId())
            themes.save(kept)
            themes.select(kept.id)
            ImportState.Done(ShareKind.Theme, 1, 1)
        }

        ShareKind.Block -> {
            val block = decodeBlock(thing.data.toString()) ?: throw IllegalStateException("no block in the file")
            blocks.update { it.copy(blocks = it.blocks + block.copy(id = newBlockId())) }
            ImportState.Done(ShareKind.Block, 1, 1)
        }

        ShareKind.Repos -> {
            val wanted = reposOf(thing)
            val added = wanted.count { repos.add(it.url) == null }
            ImportState.Done(ShareKind.Repos, added, wanted.size)
        }

        // A backup never reaches here, since the backup page takes it.
        ShareKind.Backup -> ImportState.ToBackup
    }

    fun themeOf(thing: SharedThing): AppThemeSpec? = themes.fromData(thing.data)
}

// The repos a file of repos holds.
fun reposOf(thing: SharedThing): List<SharedRepo> = (thing.data as? JsonArray).orEmpty().mapNotNull { item ->
    val row = item as? JsonObject ?: return@mapNotNull null
    val url = (row["url"] as? JsonPrimitive)?.content ?: return@mapNotNull null
    SharedRepo(url, (row["name"] as? JsonPrimitive)?.content ?: url)
}
