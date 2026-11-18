package com.sumizuri.app

import com.sumizuri.app.core.log.AppLog
import java.io.File
import java.net.InetAddress
import java.net.InetSocketAddress
import java.net.ServerSocket
import java.net.Socket
import java.util.UUID
import kotlin.concurrent.thread

// How long a second start waits for the copy that runs to answer.
private const val AnswerMs = 2_000

// One copy of the app opens a library. A second start, such as a clicked sumizuri link, hands what it was started with to the copy that runs and ends, so the library is never opened twice.
internal object SingleInstance {
    // The copy that runs writes the port it listens on and a secret beside the library, so a stale file or another program is never taken for it.
    private fun file(folder: File, name: String) = File(folder, name)

    // The name of the file of the installed app, and the one of a run from the build, which listens apart so the two never take the starts of the other.
    const val AppFile = "instance.port"
    const val BuildFile = "build.port"

    // Gives the copy that runs the link, or an empty line to just come forward. True when it answered, and this start should end.
    fun handOver(folder: File, link: String?, name: String = AppFile): Boolean {
        val (port, secret) = file(folder, name)
            .takeIf { it.isFile }
            ?.readText()
            ?.trim()
            ?.split(' ')
            ?.takeIf { it.size == 2 }
            ?.let { (p, s) -> (p.toIntOrNull() ?: return false) to s } ?: return false
        return runCatching {
            Socket().use { socket ->
                socket.connect(InetSocketAddress(InetAddress.getLoopbackAddress(), port), AnswerMs)
                socket.soTimeout = AnswerMs
                socket.getOutputStream().bufferedWriter().apply {
                    write("$secret ${link.orEmpty()}\n")
                    flush()
                }
                socket.getInputStream().bufferedReader().readLine() == "ok"
            }
        }.getOrDefault(false).also { if (it) AppLog.info("app", "handed the start to the copy that runs") }
    }

    // Listens for later starts on this computer only. Each one that knows the secret is passed on with the link it brought, which is empty when it had none.
    fun listen(folder: File, name: String = AppFile, onStart: (String) -> Unit) {
        val server = runCatching { ServerSocket(0, 8, InetAddress.getLoopbackAddress()) }.getOrElse {
            AppLog.warn("app", "could not listen for later starts: ${it.message}")
            return
        }
        val secret = UUID.randomUUID().toString()
        val target = file(folder, name)
        runCatching { target.writeText("${server.localPort} $secret") }
        Runtime.getRuntime().addShutdownHook(
            Thread {
                runCatching { if (target.readText().startsWith("${server.localPort} ")) target.delete() }
            },
        )
        thread(isDaemon = true, name = "later-starts") {
            while (true) {
                val socket = runCatching { server.accept() }.getOrNull() ?: break
                runCatching {
                    socket.use {
                        it.soTimeout = AnswerMs
                        val line = it
                            .getInputStream()
                            .bufferedReader()
                            .readLine()
                            .orEmpty()
                        if (line.substringBefore(' ') != secret) return@use
                        it.getOutputStream().bufferedWriter().apply {
                            write("ok\n")
                            flush()
                        }
                        onStart(line.substringAfter(' ', "").trim())
                    }
                }
            }
        }
    }
}
