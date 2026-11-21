package com.sumizuri.app.data.net

import com.sumizuri.app.data.model.Kind
import kotlin.concurrent.atomics.AtomicReference
import kotlin.concurrent.atomics.ExperimentalAtomicApi

// The kinds of titles each site served, learned as the app asks for them: the sites of a source, the hosts of its pictures and pages, and the hosts of videos. The router reads it to give each site the way of its kind.
@OptIn(ExperimentalAtomicApi::class)
object SiteKinds {
    private val seen = AtomicReference<Map<String, Set<Traffic>>>(emptyMap())
    private val sources = AtomicReference<Map<String, Set<String>>>(emptyMap())

    // The kind of each installed source, kept up to date by the app, so a picture that names its source can be placed.
    var bySource: Map<String, Kind> = emptyMap()

    fun of(host: String): Set<Traffic> = seen.load()[host.lowercase()].orEmpty()

    // The sources that asked a site, for the routes set for single sources.
    fun sourcesOf(host: String): Set<String> = sources.load()[host.lowercase()].orEmpty()

    fun mark(url: String, kind: Kind, sourceId: String? = null) {
        val host = hostOf(url).ifEmpty { return }
        sourceId?.let { add(sources, host, it) }
        val traffic = trafficOf(kind)
        while (true) {
            val now = seen.load()
            if (traffic in now[host].orEmpty()) return
            if (seen.compareAndSet(now, now + (host to (now[host].orEmpty() + traffic)))) return
        }
    }

    fun markFor(url: String, sourceId: String?) {
        val kind = sourceId?.let { bySource[it] } ?: return
        mark(url, kind, sourceId)
    }
}

@OptIn(ExperimentalAtomicApi::class)
private fun <T> add(map: AtomicReference<Map<String, Set<T>>>, host: String, value: T) {
    while (true) {
        val now = map.load()
        if (value in now[host].orEmpty()) return
        if (map.compareAndSet(now, now + (host to (now[host].orEmpty() + value)))) return
    }
}
