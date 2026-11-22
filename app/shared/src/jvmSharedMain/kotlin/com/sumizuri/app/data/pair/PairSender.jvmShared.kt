package com.sumizuri.app.data.pair

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.net.InetSocketAddress
import java.net.Socket

private const val ConnectMs = 8_000
private const val AnswerMs = 15_000

// Posts the body over a plain socket, since the TV listens on the home network with no certificate, and reads the first line of its answer.
actual suspend fun sendPair(link: PairLink, body: ByteArray): Boolean = withContext(Dispatchers.IO) {
    if (!isHomeAddress(link.address)) return@withContext false
    runCatching {
        Socket().use { socket ->
            socket.connect(
                InetSocketAddress(link.address.substringBefore(':'), link.address.substringAfter(':').toInt()),
                ConnectMs,
            )
            socket.soTimeout = AnswerMs
            val head =
                "POST /${link.token} HTTP/1.1\r\nHost: ${link.address}\r\nContent-Type: application/octet-stream\r\n" +
                    "Content-Length: ${body.size}\r\nConnection: close\r\n\r\n"
            socket.getOutputStream().apply {
                write(head.encodeToByteArray())
                write(body)
                flush()
            }
            val answer = socket
                .getInputStream()
                .bufferedReader()
                .readLine()
                .orEmpty()
            answer.split(' ').getOrNull(1) == "200"
        }
    }.getOrDefault(false)
}
