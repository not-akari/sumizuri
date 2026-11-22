package com.sumizuri.app.data.pair

import com.sumizuri.app.data.account.SyncAccount
import com.sumizuri.app.data.account.SyncAccountStore
import com.sumizuri.app.data.account.SyncClient
import com.sumizuri.app.data.account.thisDevice
import com.sumizuri.app.data.settings.SettingKey
import com.sumizuri.app.data.settings.SettingsRepository
import com.sumizuri.app.data.sources.RepoRepository
import com.sumizuri.app.data.sources.SourceRepository
import com.sumizuri.app.data.tracker.TrackerId
import com.sumizuri.app.data.tracker.Trackers
import com.sumizuri.app.source.SourceManager
import com.sumizuri.app.source.SourceResult
import com.sumizuri.app.source.repo.installIdFor
import com.sumizuri.app.source.repo.originId
import com.sumizuri.app.source.valueOrNull
import com.sumizuri.sync.core.AccountKeys
import com.sumizuri.sync.core.SigninRequest
import com.sumizuri.sync.core.SyncCrypto
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.withContext

// What came of a package: how many repos were added and sources installed, the name the TV signed in to sync as, how many trackers it signed in to, and what could not be done.
class PairResult(val repos: Int, val sources: Int, val syncedAs: String?, val trackers: Int, val problems: List<String>)

// What a TV needs to take in what a phone sent.
class PairPlace(
    val repos: RepoRepository,
    val sources: SourceRepository,
    val manager: SourceManager,
    val accounts: SyncAccountStore,
    val settings: SettingsRepository,
    val trackers: Trackers,
)

// Takes in a package: adds the repos this TV lacks, installs the sources it lacks from them, signs in to sync as a device of its own with the same profile on the server as the phone, and keeps the tracker accounts it lacks. Each part goes on when another fails, and what failed is told.
suspend fun applyPair(pack: PairPackage, place: PairPlace): PairResult {
    val problems = mutableListOf<String>()
    val known = place.repos.repos
        .first()
        .map { it.url }
        .toSet()
    var repos = 0
    for (url in pack.repos.distinct().filter { it !in known }) {
        val problem = place.repos.add(url)
        if (problem == null) repos++ else problems += url
    }
    var sources = 0
    for ((repoUrl, wanted) in pack.sources.groupBy { it.repoUrl }) {
        val index = place.manager.repos
            .fetchIndex(repoUrl)
            .valueOrNull()
        if (index == null) {
            problems += repoUrl
            continue
        }
        for (want in wanted) {
            val installed = place.sources.installed.first()
            if (installed.any { it.repoUrl == repoUrl && it.originId == want.id }) continue
            val offered = index.sources.firstOrNull { it.id == want.id } ?: continue
            when (val got = place.manager.repos.fetchSource(offered, repoUrl)) {
                is SourceResult.Ok -> {
                    place.sources.save(got.value.copy(id = installIdFor(got.value.repoUrl, offered.id, installed)))
                    sources++
                }

                is SourceResult.Err -> problems += offered.name
            }
        }
    }
    val syncedAs = pack.sync?.takeIf { place.accounts.account.value == null }?.let { sync ->
        runCatching { signIn(sync, place) }.getOrElse {
            problems += it.message ?: sync.server
            null
        }
    }
    val trackers = place.trackers.takeHanded(
        pack.trackers
            .mapNotNull { (id, account) ->
                TrackerId.of(id)?.let {
                    it to
                        account
                }
            }.toMap(),
    )
    return PairResult(repos, sources, syncedAs, trackers, problems)
}

// Signs in the way the sync page does, with the password the phone sent, so this TV gets a session of its own and opens the account key itself.
private suspend fun signIn(sync: PairSync, place: PairPlace): String {
    val client = SyncClient()
    val info = client.info(sync.server)
    val salt = client.salt(sync.server, sync.username.trim())
    val keys = withContext(Dispatchers.Default) { AccountKeys.signInKeys(sync.password, salt) }
    val signed = client.signin(
        sync.server,
        SigninRequest(
            sync.username.trim(),
            SyncCrypto.base64(keys.proof),
            thisDevice(),
            sync.code?.trim()?.ifEmpty { null },
        ),
    )
    val accountKey =
        AccountKeys.openAccountKey(keys.unlock, signed.keyByPassword) ?: error("The account key could not be opened.")
    place.accounts.save(
        SyncAccount(
            sync.server,
            info.name,
            signed.userId,
            signed.username,
            signed.role,
            signed.deviceId,
            signed.token,
            SyncCrypto.base64(accountKey),
        ),
    )
    sync.libraryId?.let { place.settings.setText(SettingKey.SyncLibraryId, it.toString()) }
    return signed.username
}
