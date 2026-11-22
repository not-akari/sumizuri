package com.sumizuri.app.source.host.store

import com.sumizuri.app.data.account.DeviceSecret
import com.sumizuri.app.data.net.hostOf
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.io.encoding.Base64

// The start of a value locked with the key of this device. Such a value opens only here, so it is never put in a backup or sent to other devices.
const val SealMark = "sealed:"

// The setting of a source that lets it reach addresses on the home network. It is kept with the settings of the source.
const val HomeNetworkKey = "sumizuri.homeNetwork"

// A setting or a saved value locked with the key of this device, or the text as it is when this device cannot lock.
fun sealText(text: String): String =
    DeviceSecret.seal(text.encodeToByteArray())?.let { SealMark + Base64.encode(it) } ?: text

// The text of a saved value, opened when it was locked. A value locked on another device gives null.
fun openText(stored: String): String? {
    if (!stored.startsWith(SealMark)) return stored
    val bytes = runCatching { Base64.decode(stored.removePrefix(SealMark)) }.getOrNull() ?: return null
    return DeviceSecret.open(bytes)?.decodeToString()
}

// Whether each source may reach the home network, read once from the store and kept here, since every request asks. Each profile has its own store, so the store is part of the key.
object HomeNetwork {
    private val known = mutableMapOf<Pair<ValueStore, String>, Boolean>()

    // Requests run side by side, so the map is only touched with this lock held.
    private val lock = Mutex()

    suspend fun allowed(scope: String, values: ValueStore): Boolean {
        lock.withLock { known[values to scope] }?.let { return it }
        val on = values.get(scope, ValueArea.Preference, HomeNetworkKey) == "true"
        lock.withLock { known[values to scope] = on }
        return on
    }

    // The next request of the source reads the switch again.
    suspend fun changed(scope: String) = lock.withLock { known.keys.removeAll { it.second == scope } }
}

// Headers for pictures that a source fills from its settings, such as an API key, and the hosts they may be sent to.
class SettingHeaders(val hosts: Set<String>, val headers: Map<String, String>)

// The picture headers of each source filled from its settings. They only go to a server named in the settings of that source, never to another site.
object FilledHeaders {
    private val state = MutableStateFlow<Map<String, SettingHeaders>>(emptyMap())
    val bySource: StateFlow<Map<String, SettingHeaders>> = state

    private val Placeholder = Regex("""\{\{(\w+)\}\}""")

    // Fills the headers of one source from its settings, or forgets them when nothing is left to send.
    fun update(scope: String, templates: Map<String, String>, settings: Map<String, String>) {
        val hosts = settings.values
            .map { it.trim() }
            .filter { it.startsWith("http://", ignoreCase = true) || it.startsWith("https://", ignoreCase = true) }
            .map { hostOf(it).lowercase() }
            .filter { it.isNotEmpty() }
            .toSet()
        val headers = templates
            .mapNotNull { (name, template) ->
                var missing = false
                val value = Placeholder.replace(template) { match ->
                    settings[match.groupValues[1]].orEmpty().also { if (it.isBlank()) missing = true }
                }
                if (missing) null else name to value
            }.toMap()
        state.update { now ->
            if (hosts.isEmpty() || headers.isEmpty()) now - scope else now + (scope to SettingHeaders(hosts, headers))
        }
    }

    fun forget(scope: String) = state.update { it - scope }

    // The filled headers of a source for one address, empty unless the address is on its server.
    fun forUrl(scope: String?, url: String?): Map<String, String> {
        if (scope.isNullOrEmpty() || url.isNullOrEmpty()) return emptyMap()
        val filled = state.value[scope] ?: return emptyMap()
        return if (hostOf(url).lowercase() in filled.hosts) filled.headers else emptyMap()
    }
}
