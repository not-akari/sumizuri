package com.sumizuri.app.data.sources

import com.sumizuri.app.data.db.AppDatabase
import com.sumizuri.app.data.db.repo.RepoEntity
import com.sumizuri.app.data.model.Repo
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.text.nowMillis
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.repo.RepoClient
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map

// The official repo, with the connectors for servers a person runs themselves. It holds no content.
const val OfficialRepoUrl = "https://raw.githubusercontent.com/not-akari/sumizuri-sources/main"

// The repos the user added, and the official one, which is added once.
class RepoRepository(private val db: AppDatabase, private val client: RepoClient) {
    val repos: Flow<List<Repo>> = db.repos().observeAll().map { rows -> rows.map { Repo(it.url, it.name) } }

    // Reads the repo's index to check it, and keeps the repo under the name the index gives. Gives the problem when it fails.
    suspend fun add(address: String): RepoProblem? {
        val url = address.trim()
        if (!url.startsWith("http://") && !url.startsWith("https://")) return RepoProblem.NotAnAddress
        return when (val result = client.fetchIndex(url)) {
            is SourceResult.Err -> RepoProblem.Detail(result.error.message)

            is SourceResult.Ok -> {
                db.repos().put(RepoEntity(url, result.value.name.ifBlank { url }, nowMillis()))
                null
            }
        }
    }

    // Adds the official repo the first time it can be reached. Once it is in, removing it keeps it removed.
    suspend fun addOfficialOnce(settings: SettingsRepository) {
        if (settings.flag(SettingKey.OfficialRepoAdded, false).first()) return
        if (add(OfficialRepoUrl) == null) settings.setFlag(SettingKey.OfficialRepoAdded, true)
    }

    // Removing a repo leaves the sources that were installed from it where they are.
    suspend fun remove(url: String) = db.repos().delete(url)
}

// Why a repo could not be added, either the text is not a web address, or what went wrong when its index was read.
sealed interface RepoProblem {
    data object NotAnAddress : RepoProblem
    data class Detail(val text: String) : RepoProblem
}
