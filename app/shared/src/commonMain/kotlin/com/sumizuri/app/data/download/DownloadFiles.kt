package com.sumizuri.app.data.download

import com.sumizuri.app.data.local.localFileAddress
import com.sumizuri.app.source.model.Descramble
import com.sumizuri.app.source.model.SourcePage
import com.sumizuri.app.source.model.SourceTrack
import com.sumizuri.app.source.model.SourceVideo
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath

// A page of a saved chapter: a picture file in the folder of the chapter, or a block of words, with the order of the tiles of a picture a site shuffles.
@Serializable
data class SavedPage(val file: String? = null, val text: String? = null, val descramble: Descramble? = null)

@Serializable
data class SavedChapter(val pages: List<SavedPage> = emptyList(), val video: SavedVideo? = null)

// A saved episode: its video or playlist, its separate sound when it has one, and its subtitles, all as files in the folder of the episode.
@Serializable
data class SavedVideo(val file: String, val subtitles: List<SavedTrack> = emptyList(), val audio: String? = null)

@Serializable
data class SavedTrack(val file: String, val label: String, val language: String? = null)

private val Format = Json { ignoreUnknownKeys = true }

// Where saved chapters are kept: a folder for each title, and in it a folder for each chapter with its pictures and a list of its pages. A chapter is saved into a folder of its own first and moved to its place only when it is whole, so a save that stops never leaves half a chapter that looks saved.
class DownloadFiles(private val root: Path, private val fs: FileSystem = FileSystem.SYSTEM) {
    fun folderOf(titleId: Long, chapterId: Long): Path = root / titleId.toString() / chapterId.toString()

    private fun partOf(titleId: Long, chapterId: Long): Path = root / titleId.toString() / "$chapterId.part"

    // An empty folder to save a chapter into, with what a save that stopped left in it cleared.
    fun begin(titleId: Long, chapterId: Long): Path {
        val part = partOf(titleId, chapterId)
        fs.deleteRecursively(part)
        fs.createDirectories(part)
        return part
    }

    fun write(folder: Path, name: String, bytes: ByteArray) = fs.write(folder / name) { write(bytes) }

    // Writes the list of pages and moves the chapter to its place. A chapter saved before is replaced.
    fun finish(titleId: Long, chapterId: Long, part: Path, chapter: SavedChapter) {
        fs.write(part / Manifest) { writeUtf8(Format.encodeToString(SavedChapter.serializer(), chapter)) }
        val folder = folderOf(titleId, chapterId)
        fs.deleteRecursively(folder)
        fs.atomicMove(part, folder)
    }

    fun abandon(titleId: Long, chapterId: Long) = fs.deleteRecursively(partOf(titleId, chapterId))

    fun delete(titleId: Long, chapterId: Long) {
        fs.deleteRecursively(folderOf(titleId, chapterId))
        fs.deleteRecursively(partOf(titleId, chapterId))
        // A title with nothing saved any more leaves no empty folder behind.
        val title = root / titleId.toString()
        if (fs.exists(title) && fs.list(title).isEmpty()) fs.delete(title)
    }

    // The pages of a saved chapter in the shape a source gives them, with its pictures as addresses on the device, or null when it is not saved or its files are gone.
    fun read(titleId: Long, chapterId: Long): List<SourcePage>? {
        val folder = folderOf(titleId, chapterId)
        val manifest = folder / Manifest
        if (!fs.exists(manifest)) return null
        val chapter =
            runCatching {
                Format.decodeFromString(
                    SavedChapter.serializer(),
                    fs.read(manifest) { readUtf8() },
                )
            }.getOrNull()
                ?: return null
        if (chapter.pages.any { page -> page.file != null && !fs.exists(folder / page.file) }) return null
        return chapter.pages.mapIndexed { index, page ->
            SourcePage(
                index,
                imageUrl = page.file?.let {
                    localFileAddress((folder / it).toString())
                },
                text = page.text,
                descramble = page.descramble,
            )
        }
    }

    // The saved video of an episode, as a video the players open from the device, or null when it is not saved or its file is gone.
    fun readVideo(titleId: Long, chapterId: Long): SourceVideo? {
        val folder = folderOf(titleId, chapterId)
        val manifest = folder / Manifest
        if (!fs.exists(manifest)) return null
        val video = runCatching { Format.decodeFromString(SavedChapter.serializer(), fs.read(manifest) { readUtf8() }) }
            .getOrNull()?.video ?: return null
        if (!fs.exists(folder / video.file)) return null
        return SourceVideo(
            url = fileAddress((folder / video.file).toString()),
            quality = "Saved",
            subtitles = video.subtitles.map { SourceTrack(fileAddress((folder / it.file).toString()), it.label, it.language) },
            pairedAudio = video.audio?.let { SourceTrack(fileAddress((folder / it).toString()), "Saved sound") },
        )
    }

    // The folders of saved chapters on the device, by title and chapter, for clearing those the library no longer has.
    fun saved(): List<Pair<Long, Long>> {
        if (!fs.exists(root)) return emptyList()
        return fs.list(root).flatMap { title ->
            val titleId = title.name.toLongOrNull() ?: return@flatMap emptyList()
            fs.list(title).mapNotNull { chapter -> chapter.name.toLongOrNull()?.let { titleId to it } }
        }
    }

    private companion object {
        const val Manifest = "pages.json"
    }
}

// The folder of saved chapters of a profile: beside its database, named after it, or in the temporary folder when there is no database file.
fun downloadFolder(databasePath: String): Path {
    if (databasePath.isBlank()) return FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-downloads"
    val database = databasePath.toPath()
    val parent = database.parent ?: FileSystem.SYSTEM_TEMPORARY_DIRECTORY
    return parent / "downloads" / database.name.substringBeforeLast('.')
}
