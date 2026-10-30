package com.sumizuri.app.data.local

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.source.repo.EngineKind
import com.sumizuri.app.source.repo.InstalledSource
import okio.FileSystem
import okio.Path
import okio.Path.Companion.toPath

private val ComicFiles = setOf("cbz", "zip", "epub")
private val NovelFiles = setOf("epub", "txt", "pdf")

// The two sources built into the app that show files on the device: one for comics in folders, CBZ, ZIP and EPUB files, and one for novels in EPUB and TXT files. They are always there, need no code and no connection, and keep their files in folders of their own. Their names here are the English ones, and screens show them in the language of the app.
object LocalSources {
    const val MangaId = "device:manga"
    const val NovelId = "device:novels"

    fun isLocal(id: String?): Boolean = id == MangaId || id == NovelId

    val all: List<InstalledSource> = listOf(
        InstalledSource(id = MangaId, repoUrl = null, name = "Local files", lang = "local", kind = Kind.Manga, engineKind = EngineKind.Current, version = 1, iconUrl = "", baseUrl = "", code = ""),
        InstalledSource(id = NovelId, repoUrl = null, name = "Local novels", lang = "local", kind = Kind.Novel, engineKind = EngineKind.Current, version = 1, iconUrl = "", baseUrl = "", code = ""),
    )

    // The kinds of files a local source reads, by the end of their names. The same go in its folder as titles, in a title folder as chapters, and through Add files.
    fun readableFiles(novels: Boolean): Set<String> = if (novels) NovelFiles else ComicFiles

    // The folder a local source reads, inside the folder of local files.
    fun folderOf(root: Path, id: String): Path = root / if (id == NovelId) "Novels" else "Manga"

    fun open(id: String, root: Path): LocalSource = LocalSource(
        name = (all.firstOrNull { it.id == id } ?: all.first()).name,
        novels = id == NovelId,
        folder = folderOf(root, id),
    )
}

// The folder of local files: beside the database of the main profile, so every profile sees the same files, or in the temporary folder when there is no database file.
fun localFolder(databasePath: String): Path {
    val parent = databasePath.takeIf { it.isNotBlank() }?.toPath()?.parent ?: return FileSystem.SYSTEM_TEMPORARY_DIRECTORY / "sumizuri-local"
    val home = if (parent.name == "profiles") parent.parent ?: parent else parent
    return home / "local"
}
