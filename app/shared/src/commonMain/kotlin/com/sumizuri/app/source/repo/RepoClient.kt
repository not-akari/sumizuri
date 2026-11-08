package com.sumizuri.app.source.repo

import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.source.SourceError
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.host.BridgeException
import com.sumizuri.app.source.host.net.HttpHost
import kotlinx.coroutines.CancellationException
import okio.ByteString.Companion.encodeUtf8

// The folders the source tree of a repo sorts its sources into by kind.
private val RepoFolders = listOf("anime", "donghua", "drama", "western", "comics", "novels", "mixed")

// Fetches a repo's index and the code of its sources, always through the host's address checks.
class RepoClient(private val http: HttpHost) {

    // The address of a repo is tried with the name of its index after it, as the format lays a repo out, then as it is.
    suspend fun fetchIndex(url: String): SourceResult<RepoIndex> = guarded {
        val tried = if (url.endsWith(".json")) listOf(url) else listOf("${url.trimEnd('/')}/versioning.json", url)
        var first: Exception? = null
        for (address in tried) {
            try {
                val page = http.get(address)
                if (page.statusCode !in 200..299) failure("The repo answered with status ${page.statusCode}.")
                return@guarded decodeRepoIndex(page.body, address)
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                if (first == null) first = error
            }
        }
        throw first ?: Failure(SourceError.Network("The repo could not be read."))
    }

    // Gives the source with its code, ready to install. A file with a hash in the index must match it.
    suspend fun fetchSource(source: RepoSource, repoUrl: String?): SourceResult<InstalledSource> = guarded {
        val page = fetchFile(source)
        if (page.body.isBlank()) failure("${source.name}: the file is empty.")
        source.sha256?.let { expected ->
            if (!expected.equals(sha256(page.body), ignoreCase = true)) {
                failure("${source.name}: the file does not match the hash its repo gave, so it was not installed.")
            }
        }
        InstalledSource(
            id = source.id,
            repoUrl = repoUrl,
            name = source.name,
            lang = source.lang,
            kind = source.kind,
            engineKind = source.engineKind,
            version = source.version,
            iconUrl = source.iconUrl,
            baseUrl = source.baseUrl,
            code = page.body,
            extra = source.extra,
        )
    }

    // The file of a source where the repo keeps it. A published repo has each source in a folder named for it, and the source tree of a repo, such as on GitHub, has it one folder deeper by its kind, so those folders are tried when the first place has nothing.
    private suspend fun fetchFile(source: RepoSource): HttpHost.Page {
        val first = http.get(source.fileUrl)
        if (first.statusCode in 200..299) return first
        val root = source.fileUrl.removeSuffix("/${source.id}/index.js")
        val folders = when (source.kind) {
            Kind.Anime -> listOf("anime", "donghua", "drama", "western")
            Kind.Novel -> listOf("novels", "mixed")
            else -> listOf("comics", "mixed")
        } + RepoFolders
        for (folder in folders.distinct()) {
            val page = try {
                http.get("$root/$folder/${source.id}/index.js")
            } catch (error: CancellationException) {
                throw error
            } catch (error: Exception) {
                continue
            }
            if (page.statusCode in 200..299) return page
        }
        failure("${source.name}: the file answered with status ${first.statusCode}.")
    }

    private fun sha256(text: String): String = text.encodeUtf8().sha256().hex()

    private class Failure(val error: SourceError) : Exception(error.message)

    private fun failure(message: String): Nothing = throw Failure(SourceError.Network(message))

    private suspend fun <T> guarded(block: suspend () -> T): SourceResult<T> = try {
        SourceResult.Ok(block())
    } catch (error: CancellationException) {
        throw error
    } catch (error: Failure) {
        SourceResult.Err(error.error)
    } catch (error: RepoFormatException) {
        SourceResult.Err(SourceError.Parse(error.message ?: "Not a valid repo index"))
    } catch (error: BridgeException) {
        SourceResult.Err(SourceError.Network(error.message ?: "Could not fetch it"))
    }
}
