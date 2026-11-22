package com.sumizuri.app.data.pair

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.InputStream
import java.net.Inet4Address
import java.net.InetSocketAddress
import java.net.NetworkInterface
import java.net.ServerSocket
import java.net.Socket

// The most a phone may send, which a package of repos and a sign in stays far below.
private const val MaxBody = 256 * 1024

// How long a phone may take to send once it has connected.
private const val ReadMs = 15_000

// Listens on every address of this device on a free port, and names the address of the home network a phone reaches it at.
actual fun openPairListener(): PairListener? = runCatching {
    val here = homeAddress() ?: return null
    val server = ServerSocket()
    server.bind(InetSocketAddress(0))
    SocketListener(server, "$here:${server.localPort}")
}.getOrNull()

private class SocketListener(private val server: ServerSocket, override val address: String) : PairListener {
    override suspend fun receive(path: String): ByteArray = withContext(Dispatchers.IO) {
        var body: ByteArray? = null
        while (body == null) body = server.accept().use { read(it, path) }
        body
    }

    override fun close() {
        runCatching { server.close() }
    }
}

// Reads one plain HTTP request and answers it. Gives the body of a post to the path, and null for anything else.
private fun read(socket: Socket, path: String): ByteArray? {
    socket.soTimeout = ReadMs
    val input = BufferedInputStream(socket.getInputStream())
    val start = line(input) ?: return null
    val parts = start.split(' ')
    var length = 0
    while (true) {
        val header = line(input) ?: return null
        if (header.isEmpty()) break
        val name = header.substringBefore(':').trim()
        if (name.equals("Content-Length", ignoreCase = true)) {
            length =
                header.substringAfter(':').trim().toIntOrNull() ?: 0
        }
    }
    val right = parts.size >= 2 && parts[0] == "POST" && parts[1].trimStart('/') == path && length in 1..MaxBody
    val body = if (right) bodyOf(input, length) else null
    val status = if (body != null) "200 OK" else "404 Not Found"
    socket.getOutputStream().apply {
        write("HTTP/1.1 $status\r\nContent-Length: 0\r\nConnection: close\r\n\r\n".encodeToByteArray())
        flush()
    }
    return body
}

// One line of the request, without its end, or null when the phone stopped sending.
private fun line(input: InputStream): String? {
    val bytes = StringBuilder()
    while (true) {
        val next = input.read()
        if (next == -1) return null
        if (next == '\n'.code) return bytes.toString().trimEnd('\r')
        if (bytes.length > 8192) return null
        bytes.append(next.toChar())
    }
}

// The names of the network adapters of virtual machines and containers, which a phone cannot reach.
private val VirtualNames =
    listOf("vethernet", "docker", "virbr", "br-", "veth", "vmnet", "vbox", "hyper-v", "wsl", "tun", "tap", "utun")

// The address of this device on the home network: a private IPv4 address of a real interface that is up, the kinds homes use most first, 192.168, then 10, then 172.16 to 172.31.
private fun homeAddress(): String? = NetworkInterface
    .getNetworkInterfaces()
    .toList()
    .filter { face ->
        val name = (face.name + " " + face.displayName.orEmpty()).lowercase()
        face.isUp && !face.isLoopback && !face.isVirtual && VirtualNames.none { it in name }
    }.flatMap { it.inetAddresses.toList() }
    .filterIsInstance<Inet4Address>()
    .filter { it.isSiteLocalAddress }
    .minByOrNull { address ->
        val host = address.hostAddress.orEmpty()
        when {
            host.startsWith("192.168.") -> 0
            host.startsWith("10.") -> 1
            else -> 2
        }
    }?.hostAddress

// Exactly the given number of bytes, or null when the phone stopped before them.
private fun bodyOf(input: InputStream, length: Int): ByteArray? {
    val bytes = ByteArray(length)
    var at = 0
    while (at < length) {
        val got = input.read(bytes, at, length - at)
        if (got == -1) return null
        at += got
    }
    return bytes
}
