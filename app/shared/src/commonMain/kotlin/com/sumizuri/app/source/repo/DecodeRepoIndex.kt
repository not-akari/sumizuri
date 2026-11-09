package com.sumizuri.app.source.repo

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.source.host.string
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.put

// A version of three numbers, such as 2.3.1, is kept as one number in these parts so versions still compare in order.
private const val MajorPart = 1_000_000
private const val MinorPart = 1_000

// Reads the index of a repo, where the file of each source sits in a folder named for it next to the index, so the address of the index says where the repo is.
fun decodeRepoIndex(text: String, indexUrl: String = ""): RepoIndex {
    val json = try {
        Json.parseToJsonElement(text).jsonObject
    } catch (error: Exception) {
        throw RepoFormatException("Not a valid repo index: ${error.message}")
    }
    val list = json["sources"] as? JsonArray ?: JsonArray(emptyList())
    // The index of the old Sumizuri repos gave a file address for each source, which a current repo never does.
    if ((list.firstOrNull() as? JsonObject)?.get("fileUrl") != null) {
        throw RepoFormatException(
            "This repo uses an old format that no longer runs. Add a repo that has a versioning.json.",
        )
    }
    val base = indexUrl.substringBeforeLast('/', "")
    val sources = list.map { element ->
        decodeSource(
            element as? JsonObject ?: throw RepoFormatException("Not a valid repo index, a source is not an object"),
            base,
        )
    }
    return RepoIndex(name = json.string("name") ?: json.string("repositoryName") ?: "Repo", sources = sources)
}

// One source of the index. Comics and the sources that serve both are listed as manga, and anime is an addition of Sumizuri for sources with videos.
private fun decodeSource(json: JsonObject, base: String): RepoSource {
    val id = json.string("id") ?: throw RepoFormatException("Not a valid repo index, a source has no \"id\"")
    val rating = json.string("contentRating")
    val extra = buildJsonObject {
        json["hosts"]?.let { put("hosts", it) }
        json["imageHeaders"]?.let { put("imageHeaders", it) }
        json["settingsSchema"]?.let { put("settingsSchema", it) }
        rating?.let { put("contentRating", it) }
        json.string("status")?.let { put("status", it) }
        json.string("statusNote")?.let { put("statusNote", it) }
    }
    return RepoSource(
        id = id,
        name = json.string("name") ?: id,
        lang = json.string("language") ?: "en",
        kind = kindOf(json.string("medium") ?: json.string("type")),
        engineKind = EngineKind.Current,
        version = versionNumber(json.string("version")),
        iconUrl = json.string("iconUrl") ?: "",
        baseUrl = json.string("website") ?: "",
        fileUrl = "$base/$id/index.js",
        nsfw = rating == "adult",
        extra = extra.toString(),
        sha256 = json.string("sha256"),
    )
}

// The medium of a source, in any case and with the other names repos give it, so a repo that writes Anime or video still lists its sources as anime and not as comics.
private fun kindOf(medium: String?): Kind = when (medium?.trim()?.lowercase()) {
    "novel", "novels", "lightnovel", "light novel" -> Kind.Novel
    "anime", "animes", "video", "videos" -> Kind.Anime
    else -> Kind.Manga
}

// 2.3.1 becomes 2003001, and a version that is not made of numbers becomes 1.
private fun versionNumber(text: String?): Int {
    val parts = text.orEmpty().split('.').map { it.trim().toIntOrNull()?.coerceIn(0, 999) ?: 0 }
    return (
        parts.getOrElse(0) {
            0
        } * MajorPart + parts.getOrElse(1) { 0 } * MinorPart + parts.getOrElse(2) { 0 }
        ).coerceAtLeast(1)
}
