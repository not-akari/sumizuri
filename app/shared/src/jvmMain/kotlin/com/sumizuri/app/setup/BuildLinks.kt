package com.sumizuri.app.setup

import com.sumizuri.app.core.log.AppLog
import java.io.File
import java.lang.management.ManagementFactory

private const val CommandKey = "$LinkKey\\shell\\open\\command"

// While a run from the build is open on Windows, sumizuri links start a short run of the same build, which hands the link to the open one and ends. So signing in to a tracker from the build comes back to the build. The run gives the links back to the installed app when it ends, and the installed app takes them back at its next start in any case.
object BuildLinks {
    fun take(argFile: File) {
        if (!System.getProperty("os.name").orEmpty().startsWith("Windows")) return
        val main = System.getProperty("sun.java.command")?.substringBefore(' ')?.takeIf { it.isNotBlank() } ?: return
        val java = File(System.getProperty("java.home"), "bin/javaw.exe").takeIf { it.isFile } ?: return
        runCatching {
            // Only the settings of the run are passed on. A debugger it was started with would not let a second run start.
            val options = ManagementFactory
                .getRuntimeMXBean()
                .inputArguments
                .filter { it.startsWith("-D") }
                .let { if ("-Dsumizuri.debug=true" in it) it else it + "-Dsumizuri.debug=true" }
            val words = options + listOf("-cp", System.getProperty("java.class.path"), main)
            argFile.writeText(words.joinToString("\n") { quoted(it) })
            val before = WinRegistry.text(CommandKey, "")
            val ours = "\"${java.absolutePath}\" @\"${argFile.absolutePath}\" \"%1\""
            WinRegistry.write(LinkKey, texts = mapOf("" to "URL:Sumizuri", "URL Protocol" to ""), numbers = emptyMap())
            WinRegistry.write(CommandKey, texts = mapOf("" to ours), numbers = emptyMap())
            AppLog.info("setup", "sumizuri links open with this run of the build while it is open")
            Runtime.getRuntime().addShutdownHook(
                Thread {
                    if (before != null && WinRegistry.text(CommandKey, "") == ours) {
                        runCatching { WinRegistry.write(CommandKey, texts = mapOf("" to before), numbers = emptyMap()) }
                    }
                },
            )
        }.onFailure { AppLog.warn("setup", "the sumizuri links could not be taken by this run: ${it.message}") }
    }

    // One word of a file of arguments for java, where a backslash escapes the next letter inside quotes.
    private fun quoted(word: String) = "\"" + word.replace("\\", "\\\\").replace("\"", "\\\"") + "\""
}
