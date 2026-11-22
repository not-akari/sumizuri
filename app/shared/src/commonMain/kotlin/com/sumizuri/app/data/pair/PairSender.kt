package com.sumizuri.app.data.pair

// Sends a locked package to the TV of a link and tells whether the TV took it.
expect suspend fun sendPair(link: PairLink, body: ByteArray): Boolean

// Whether the address of a link is one on a home network: 10, 172.16 to 172.31 or 192.168, with a port. A phone sends to nothing else, so a code seen somewhere else cannot make it send a password across the internet.
fun isHomeAddress(address: String): Boolean {
    val host = address.substringBefore(':')
    val port = address.substringAfter(':', "").toIntOrNull() ?: return false
    if (port !in 1..65535) return false
    val parts = host.split('.').mapNotNull { it.toIntOrNull() }
    if (parts.size != 4 || parts.any { it !in 0..255 }) return false
    return parts[0] == 10 || (parts[0] == 172 && parts[1] in 16..31) || (parts[0] == 192 && parts[1] == 168)
}
