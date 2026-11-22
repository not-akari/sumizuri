package com.sumizuri.app.source

import com.sumizuri.app.core.log.AppLog
import com.sumizuri.app.data.local.LocalSources
import com.sumizuri.app.source.browser.BrowserBroker
import com.sumizuri.app.source.browser.page.RenderPageFactory
import com.sumizuri.app.source.engine.EngineScripts
import com.sumizuri.app.source.engine.ExtensionSource
import com.sumizuri.app.source.engine.open
import com.sumizuri.app.source.host.StandardHost
import com.sumizuri.app.source.host.net.HttpHost
import com.sumizuri.app.source.host.net.ImageHost
import com.sumizuri.app.source.host.store.CookieStore
import com.sumizuri.app.source.host.store.HomeNetwork
import com.sumizuri.app.source.host.store.StorageHost
import com.sumizuri.app.source.host.store.StoredBrowserFirstFlag
import com.sumizuri.app.source.host.store.ValueStore
import com.sumizuri.app.source.repo.EngineKind
import com.sumizuri.app.source.repo.InstalledSource
import com.sumizuri.app.source.repo.RepoClient
import io.ktor.client.HttpClient
import io.ktor.client.engine.HttpClientEngine
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import okio.Path
import kotlin.concurrent.Volatile

// How long a call of a draft in the editor may take, shorter than for a real source, so a stuck test gives its answer soon.
private const val TestTimeoutMs = 30_000L

// Starts each installed source once and keeps it running, so a page does not pay for it twice.
class SourceManager(
    pages: RenderPageFactory,
    private val values: ValueStore,
    private val cookies: CookieStore,
    // Where the built in sources of files on the device read them.
    val localFolder: Path,
) {
    private class Running(val version: Int, val source: ExtensionSource)

    private val broker = BrowserBroker(pages)
    private val lock = Mutex()
    private val running = mutableMapOf<String, Running>()

    // The ids of the sources that are running, copied after every change so the performance overlay can read it from any thread.
    @Volatile
    var runningIds: List<String> = emptyList()
        private set

    // One network engine for every source, made the first time a source starts. Each source still has its own client with its own cookies, but they share the connections and the threads of this one, where each used to start a pool of its own. Made once even when pictures and sources ask for it at the same moment.
    private val sharedEngine = lazy { HttpClient().engine }

    private fun engine(): HttpClientEngine = sharedEngine.value

    private var scripts: EngineScripts? = null

    // The repo reads go through their own client, which never needs the hidden browser.
    val repos = RepoClient(HttpHost(engine = engine()))

    // Pictures of sites that put a bot check in front of them are loaded through the hidden browser.
    val images = ImageHost(broker, values, cookies, engine = ::engine)

    suspend fun open(installed: InstalledSource): SourceResult<Source> = lock.withLock {
        // The sources of files on the device are built in, keep nothing between calls and need no engine.
        if (LocalSources.isLocal(
                installed.id,
            )
        ) {
            return@withLock SourceResult.Ok(LocalSources.open(installed.id, localFolder))
        }
        val current = running[installed.id]
        if (current != null && current.version == installed.version) return@withLock SourceResult.Ok(current.source)
        current?.source?.close()
        running.remove(installed.id)
        runningIds = running.keys.toList()
        try {
            val engine = scripts ?: EngineScripts.load().also { scripts = it }
            val http = HttpHost(
                engine = engine(),
                browser = broker,
                browserFirst = StoredBrowserFirstFlag(installed.id, values),
                label = installed.id,
                cookieStore = cookies,
                cookieScope = installed.id,
                allowedHosts = installed.allowedHosts(),
                kind = installed.kind,
                sourceId = installed.id,
                homeNetwork = { HomeNetwork.allowed(installed.id, values) },
            )
            val storage = StorageHost(installed.id, values, installed.secureSettingKeys())
            storage.sealOld()
            val host =
                StandardHost(
                    http = http,
                    storage = storage,
                    browser = broker,
                    label = installed.id,
                )
            val source = ExtensionSource.open(runnable(installed), engine, host)
            source.fillHeaders()
            running[installed.id] = Running(installed.version, source)
            runningIds = running.keys.toList()
            AppLog.info("sources", "started ${installed.id} version ${installed.version}")
            SourceResult.Ok(source)
        } catch (error: CancellationException) {
            throw error
        } catch (error: Throwable) {
            AppLog.error("sources", "could not start ${installed.id}", error)
            SourceResult.Err(SourceError.Script(error.message ?: "The source could not be started"))
        }
    }

    // Starts a draft of a source for the editor to try, apart from the sources the app uses, so a test never replaces one of them. The script knows it is tested and tells what it finds, which the log keeps under the label. It shares the cookies and the saved values of the source it is a draft of. The caller closes it.
    suspend fun openTest(draft: InstalledSource, label: String): SourceResult<Source> = try {
        val engine = lock.withLock { scripts ?: EngineScripts.load().also { scripts = it } }
        val http = HttpHost(
            engine = engine(),
            browser = broker,
            browserFirst = StoredBrowserFirstFlag(draft.id, values),
            label = label,
            cookieStore = cookies,
            cookieScope = draft.id,
            allowedHosts = draft.allowedHosts(),
            kind = draft.kind,
            sourceId = draft.id,
            homeNetwork = { HomeNetwork.allowed(draft.id, values) },
        )
        val storage = StorageHost(draft.id, values, draft.secureSettingKeys())
        val host = StandardHost(http = http, storage = storage, browser = broker, label = label)
        val source = ExtensionSource.open(runnable(draft), engine, host, callTimeoutMs = TestTimeoutMs)
        SourceResult.Ok(source)
    } catch (error: CancellationException) {
        throw error
    } catch (error: Throwable) {
        AppLog.warn(label, "the draft could not be started, ${error.message}")
        SourceResult.Err(SourceError.Script(error.message ?: "The source could not be started"))
    }

    // A source written for the old engine no longer runs. It has to be installed again from a repo of the current format.
    private fun runnable(installed: InstalledSource): InstalledSource {
        if (installed.engineKind ==
            EngineKind.Old
        ) {
            throw IllegalStateException(
                "${installed.name} was made for the old engine, which is gone. Install it again from a repo.",
            )
        }
        return installed
    }

    // Closes the hidden pages that are kept, so the next request opens a new one that has what a person just passed.
    suspend fun resetBrowser() = broker.resetSessions()

    suspend fun close(id: String) = lock.withLock {
        running.remove(id)?.source?.close()
        runningIds = running.keys.toList()
    }

    // How many hidden browser pages are open now.
    suspend fun browserPages(): Int = broker.openPages()

    // Lets go of everything, for when the profile this manager belongs to is left.
    suspend fun shutdown() {
        lock.withLock {
            running.values.forEach { it.source.close() }
            running.clear()
            runningIds = emptyList()
        }
        broker.close()
        if (sharedEngine.isInitialized()) sharedEngine.value.close()
    }
}
