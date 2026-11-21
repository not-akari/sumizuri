package com.sumizuri.app.source.host.net

import com.sumizuri.app.data.net.hostOf
import com.sumizuri.app.source.host.BlockedException
import com.sumizuri.app.source.host.BridgeException

// Only public web addresses are allowed, so a source cannot reach this device or the network around it.
internal object AddressGuard {
    fun check(url: String): String {
        val trimmed = url.trim()
        val scheme = trimmed.substringBefore("://", missingDelimiterValue = "").lowercase()
        if (scheme != "http" && scheme != "https") {
            if (!trimmed.contains("://")) throw BridgeException("Not a valid absolute URL: \"$url\"")
            throw BridgeException("Only http and https addresses are allowed, got \"$scheme\"")
        }
        val host = hostOf(trimmed)
        if (host.isEmpty()) throw BridgeException("Not a valid absolute URL: \"$url\"")
        if (isBlockedHost(host)) throw BlockedException("Refusing to fetch a private or internal address: \"$host\"")
        return trimmed
    }

    // True for a host written as an IP address, which needs no lookup.
    fun isLiteralAddress(host: String): Boolean = parseIpv4(host.lowercase()) != null || host.contains(':')

    fun isBlockedHost(host: String): Boolean {
        val lower = host.lowercase().trimEnd('.')
        if (lower == "localhost" || lower.endsWith(".localhost") || lower.endsWith(".local")) return true
        parseIpv4(lower)?.let { return isBlockedIpv4(it) }
        if (lower.contains(':')) return isBlockedIpv6(lower)
        return false
    }

    private fun parseIpv4(host: String): List<Int>? {
        val parts = host.split('.')
        if (parts.size != 4) return null
        val numbers = parts.map { it.toIntOrNull() ?: return null }
        return if (numbers.all { it in 0..255 }) numbers else null
    }

    private fun isBlockedIpv4(b: List<Int>): Boolean = when {
        b[0] == 0 || b[0] == 127 -> true
        b[0] == 10 -> true
        b[0] == 172 && b[1] in 16..31 -> true
        b[0] == 192 && b[1] == 168 -> true
        b[0] == 169 && b[1] == 254 -> true
        b[0] == 100 && b[1] in 64..127 -> true
        b[0] >= 224 -> true
        else -> false
    }

    private fun isBlockedIpv6(host: String): Boolean {
        if (host == "::1" || host == "::") return true
        if (host.startsWith("fe8") || host.startsWith("fe9") || host.startsWith("fea") ||
            host.startsWith("feb")
        ) {
            return true
        }
        if (host.startsWith("fc") || host.startsWith("fd")) return true
        if (host.startsWith("ff")) return true
        // An IPv4 address written inside an IPv6 one.
        if (host.startsWith("::ffff:")) {
            val v4 = host.removePrefix("::ffff:")
            parseIpv4(v4)?.let { return isBlockedIpv4(it) }
            return true
        }
        return false
    }
}
