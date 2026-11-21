package com.sumizuri.app.feature.profile

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.sumizuri.app.data.blocks.ProfileBlocksRepository
import com.sumizuri.app.data.library.LibraryRepository
import com.sumizuri.app.data.library.StatisticsRepository
import com.sumizuri.app.data.profile.ProfileHost
import com.sumizuri.app.ui.kit.input.squareAvatar
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.IO
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.flowOn
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import okio.FileSystem

// A picture for a profile is kept this many pixels wide and high.
private const val AvatarSize = 512

// The profiles of the device and the reading of the one that is open.
class ProfileViewModel(
    private val host: ProfileHost,
    statistics: StatisticsRepository,
    library: LibraryRepository,
    private val blocks: ProfileBlocksRepository,
) : ViewModel() {
    // Each block runs its script on the reading as it is now, every time the reading or the blocks change.
    val state: StateFlow<ProfileState> = combine(
        host.state,
        statistics.reading,
        library.history,
        library.unreachableSources,
        blocks.layout,
    ) { registry, reading, history, unreachable, layout ->
        val shown = showBlocks(layout, reading)
        ProfileState(
            registry.profiles,
            registry.active,
            reading.stats,
            history
                .distinctBy {
                    it.title.id
                }.take(RecentCount),
            unreachable.sumOf { it.count },
            shown,
        )
    }.flowOn(Dispatchers.Default).stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), ProfileState())

    fun onSwitch(id: Long) = host.switchTo(id)

    suspend fun onCreate(name: String, picture: ByteArray?): Boolean =
        host.create(name.trim(), picture?.let { keep(it) }) != null

    fun onSave(id: Long, name: String, picture: ByteArray?, removePicture: Boolean) {
        val trimmed = name.trim()
        if (trimmed.isNotEmpty()) host.rename(id, trimmed)
        viewModelScope.launch {
            if (picture != null) {
                host.setAvatar(id, keep(picture))
            } else if (removePicture) {
                host.setAvatar(id, null)
            }
        }
    }

    suspend fun onDelete(id: Long): Boolean = host.delete(id)

    // Writes the picture to the avatars folder and gives its path, or null when it is no picture.
    private suspend fun keep(picture: ByteArray): String? = withContext(Dispatchers.IO) {
        val square = squareAvatar(picture, AvatarSize) ?: return@withContext null
        val path = host.registry.newAvatarPath()
        FileSystem.SYSTEM.write(path) { write(square) }
        path.toString()
    }

    private companion object {
        const val RecentCount = 8
    }
}
