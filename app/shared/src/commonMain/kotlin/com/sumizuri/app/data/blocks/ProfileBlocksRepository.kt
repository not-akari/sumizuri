package com.sumizuri.app.data.blocks

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.settings.SettingsRepository
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive

private const val Key = "profile.blocks"

private val BlockJson = Json {
    ignoreUnknownKeys = true
    encodeDefaults = false
}

// Reads a layout written as JSON, or gives null when it cannot be read.
fun decodeLayout(text: String): BlockLayout? =
    runCatching { BlockJson.decodeFromString(BlockLayout.serializer(), text) }
        .onFailure { AppLog.warn("profile", "the blocks of the profile could not be read, ${it.message}") }
        .getOrNull()

fun encodeLayout(layout: BlockLayout): String = BlockJson.encodeToString(BlockLayout.serializer(), layout)

// One block as the content of a file of the app, which is how a block is shared with other people.
fun blockData(block: ProfileBlock): JsonElement = BlockJson.encodeToJsonElement(ProfileBlock.serializer(), block)

// The block the content of a file holds, or null when it holds none.
fun decodeBlock(data: JsonElement): ProfileBlock? = runCatching {
    BlockJson.decodeFromJsonElement(ProfileBlock.serializer(), data)
}.getOrNull()

// The blocks of the profile page, kept with the settings of the profile. A profile that never changed them gets the page as it was before blocks.
class ProfileBlocksRepository(private val settings: SettingsRepository) {
    val layout: Flow<BlockLayout> = settings.text(Key).distinctUntilChanged().map { text ->
        text?.let(::decodeLayout)?.let(::bringOver)
            ?: defaultLayout()
    }

    suspend fun save(layout: BlockLayout) = settings.setText(Key, encodeLayout(layout))

    // Changes the layout as it is now and keeps the change.
    suspend fun update(change: (BlockLayout) -> BlockLayout) = save(change(layout.first()))

    suspend fun updateBlock(id: String, change: (ProfileBlock) -> ProfileBlock) = update { layout ->
        layout.copy(blocks = layout.blocks.map { if (it.id == id) change(it) else it })
    }

    suspend fun reset() = settings.resetNames(Key)
}

// Blocks saved by the first version of blocks held a graph of nodes in place of a script. One that showed a part of the profile as it came gets the script of that part, and any other starts empty, so none shows an error for what it never had.
internal fun bringOver(layout: BlockLayout): BlockLayout = layout.copy(
    blocks = layout.blocks.map { block ->
        if (block.script.isNotBlank() ||
            block.graph == null
        ) {
            block
        } else {
            block.copy(script = sectionOf(block)?.let(::sectionScript).orEmpty(), graph = null)
        }
    },
)

// The part of the profile an old block showed: the section set on its node of that kind, or the one its id names.
private fun sectionOf(block: ProfileBlock): String? {
    val nodes = ((block.graph as? JsonObject)?.get("nodes") as? JsonArray).orEmpty().filterIsInstance<JsonObject>()
    val classic = nodes.firstOrNull { (it["type"] as? JsonPrimitive)?.content == "view_classic" }
    val set = ((classic?.get("set") as? JsonObject)?.get("section") as? JsonPrimitive)?.content
    return (set ?: block.id.removePrefix("classic-").takeIf { block.id.startsWith("classic-") })?.lowercase()
}
