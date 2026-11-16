package com.sumizuri.app.data.share

import com.sumizuri.app.BuildInfo
import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.data.text.nowMillis
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.addJsonObject
import kotlinx.serialization.json.buildJsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.longOrNull
import kotlinx.serialization.json.put

// The ending of every file the app makes to keep or to share.
const val ShareEnding = ".sumizuri"

// The mark some editors put at the start of a text file, which is not part of its text.
private const val ByteOrderMark = '\uFEFF'

// The version of the outer shape of a file. A file of a newer one is not read, and says so.
private const val ShapeVersion = 1

// What a file of the app holds. The id is what the file says, so it never changes.
enum class ShareKind(val id: String) {
    Backup("backup"),
    Settings("settings"),
    Theme("theme"),
    Block("block"),
    Repos("repos"),
}

// A file of the app as it was read: what it holds, its content, and when it was made.
data class SharedThing(val kind: ShareKind, val data: JsonElement, val made: Long?)

// Why a file could not be read as a file of the app.
enum class ShareProblem { NotOurs, Newer, Damaged }

class ShareUnreadable(val problem: ShareProblem, cause: Throwable? = null) : Exception(problem.name, cause)

// The start of a file, up to where its content begins, for a file whose content is written as it goes, such as a backup. The file ends with one closing brace after the content.
fun shareHead(kind: ShareKind): String = shareEnvelope(kind, JsonPrimitive(0)).toString().removeSuffix("0}")

// A whole file around its content.
fun shareText(kind: ShareKind, data: JsonElement): String = shareEnvelope(kind, data).toString()

// The content is put last, so a file written as it goes can end right after it.
private fun shareEnvelope(kind: ShareKind, data: JsonElement): JsonObject = buildJsonObject {
    put("sumizuri", ShapeVersion)
    put("type", kind.id)
    put("app", BuildInfo.Version)
    put("made", nowMillis())
    put("data", data)
}

// Reads the text of a file of the app. Throws when it is not one, is damaged, or comes from a newer app.
fun readShared(text: String): SharedThing {
    val root = runCatching { Json.parseToJsonElement(text.trimStart(ByteOrderMark, ' ', '\n', '\r', '\t')).jsonObject }
        .getOrElse { throw ShareUnreadable(ShareProblem.NotOurs, it) }
    return readShared(root)
}

private fun readShared(root: JsonObject): SharedThing {
    val version = (root["sumizuri"] as? JsonPrimitive)?.intOrNull ?: throw ShareUnreadable(ShareProblem.NotOurs)
    if (version > ShapeVersion) throw ShareUnreadable(ShareProblem.Newer)
    val type = (root["type"] as? JsonPrimitive)?.content
    val kind = ShareKind.entries.firstOrNull { it.id == type } ?: throw ShareUnreadable(ShareProblem.Newer)
    val data = root["data"] ?: throw ShareUnreadable(ShareProblem.Damaged)
    return SharedThing(kind, data, (root["made"] as? JsonPrimitive)?.longOrNull)
}

// A repo in a file of repos.
data class SharedRepo(val url: String, val name: String)

// The repos a person added, as the content of a file of repos.
fun reposData(repos: List<Repo>): JsonElement = buildJsonArray {
    for (repo in repos) {
        addJsonObject {
            put("url", repo.url)
            put("name", repo.name)
        }
    }
}

// The repos a file of repos holds.
fun reposOf(thing: SharedThing): List<SharedRepo> = (thing.data as? JsonArray).orEmpty().mapNotNull { item ->
    val row = item as? JsonObject ?: return@mapNotNull null
    val url = (row["url"] as? JsonPrimitive)?.content ?: return@mapNotNull null
    SharedRepo(url, (row["name"] as? JsonPrimitive)?.content ?: url)
}

// A plain name for a file of this kind, such as Midnight.sumizuri, with the marks a file name cannot have taken out.
fun shareFileName(name: String): String {
    val clean = name
        .map { if (it.isLetterOrDigit() || it in " -_.()") it else '_' }
        .joinToString("")
        .trim()
        .take(60)
    return clean.ifEmpty { "sumizuri" } + ShareEnding
}
