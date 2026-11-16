package com.sumizuri.app.feature.profile

import com.sumizuri.app.data.blocks.BlockContext
import com.sumizuri.app.data.blocks.BlockLayout
import com.sumizuri.app.data.blocks.BlockTemplate
import com.sumizuri.app.data.blocks.BlockView
import com.sumizuri.app.data.blocks.ProfileBlock
import com.sumizuri.app.data.blocks.ProfilePreset
import com.sumizuri.app.data.blocks.runScript
import com.sumizuri.app.data.model.FeedItem
import com.sumizuri.app.data.model.stats.ReadingStats
import com.sumizuri.app.data.profile.Profile
import kotlinx.serialization.json.JsonElement

// What the profile page shows: the readers of this device, the one that is open, how its reading adds up, the titles it read last, and the blocks of the page with what each shows.
data class ProfileState(
    val profiles: List<Profile> = emptyList(),
    val active: Profile? = null,
    val stats: ReadingStats = ReadingStats(),
    val recent: List<FeedItem> = emptyList(),
    // How many titles of the library have a source that is missing or off, so the profile can point to where that is mended.
    val unreachable: Int = 0,
    val blocks: List<ShownBlock> = emptyList(),
)

// A block with what its graph gave, and the title typed on its Block node.
data class ShownBlock(val block: ProfileBlock, val view: BlockView, val title: String)

// What the page can ask for. A picture is the bytes of a file the person chose, which is cut to a square before it is kept.
class ProfileCalls(
    val onOpenSettings: () -> Unit,
    val onOpenSync: () -> Unit,
    val onOpenMissing: () -> Unit,
    val onOpenTitle: (Long) -> Unit,
    val onSwitch: (Long) -> Unit,
    // Makes a profile and opens it, and gives false when it could not be made.
    val onCreate: suspend (name: String, picture: ByteArray?) -> Boolean,
    val onSave: (id: Long, name: String, picture: ByteArray?, removePicture: Boolean) -> Unit,
    // Deletes a profile that is not open, and gives false when it could not be.
    val onDelete: suspend (Long) -> Boolean,
    // Puts a preset in place of the blocks, and opens the page where the blocks are edited.
    val onPreset: (ProfilePreset) -> Unit,
    val onArrange: () -> Unit,
)

// What the page of the blocks can ask for: a block moved to a place in the order, resized, removed, copied, added from a template or from shared text, or opened in the editor of its script, and all of them replaced by a preset.
class BlockCalls(
    val onMove: (id: String, to: Int) -> Unit,
    val onResize: (id: String, w: Int, h: Int) -> Unit,
    val onRemove: (String) -> Unit,
    val onDuplicate: (String) -> Unit,
    val onAdd: (BlockTemplate) -> Unit,
    val onImport: suspend (JsonElement) -> Boolean,
    val onEdit: (String) -> Unit,
    val onPreset: (ProfilePreset) -> Unit,
)

// Each block with what its script shows on the reading as it is now.
fun showBlocks(layout: BlockLayout, reading: BlockContext): List<ShownBlock> = layout.blocks.map { block ->
    runScript(block.script, reading).let {
        ShownBlock(block, it.view, it.title)
    }
}
