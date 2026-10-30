package com.sumizuri.app.setup

import com.sumizuri.app.BuildInfo
import com.sumizuri.app.core.log.AppLog
import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer
import java.io.File
import java.nio.file.Files
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread

private const val Tag = "archive"
private const val Name = "sumizuri.jsa"

// How long after the start the archive is made, so it never competes with the app opening.
private const val StartAfterMs = 20_000L

// A half done archive this recent means another start is still making it.
private const val BusyMs = 10 * 60_000L

// The longest each step may take before it is given up, at the lowest priority on a busy computer.
private const val StepMinutes = 20L

@Suppress("FunctionName")
private interface Kernel32Priority : Library {
    fun OpenProcess(access: Int, inherit: Boolean, pid: Int): Pointer?

    fun SetPriorityClass(process: Pointer, priority: Int): Boolean

    fun CloseHandle(handle: Pointer): Boolean
}

// The archive of the classes of the installed app, which lets Java start them without reading and checking each one, so the app and every page open quickly. Java only writes one while the app runs very slowly, so it is made in the background after an install or update, at the lowest priority, and used from the next start on.
object ClassArchive {
    fun makeLater() {
        val appDir = System.getProperty("compose.application.resources.dir")?.let { File(it).parentFile } ?: return
        val java = javaOf(appDir) ?: return
        val archive = File(appDir, Name)
        val stamp = File(appDir, "$Name.version")
        if (archive.isFile && stamp.isFile && stamp.readText() == BuildInfo.Version) return
        if (!appDir.canWrite()) return
        val half = File(appDir, "$Name.part")
        if (half.isFile && System.currentTimeMillis() - half.lastModified() < BusyMs) return
        thread(isDaemon = true, name = "class-archive", priority = Thread.MIN_PRIORITY) {
            Thread.sleep(StartAfterMs)
            runCatching {
                make(appDir, java, archive, half, stamp)
            }.onFailure { AppLog.error(Tag, "the class archive could not be made", it) }
        }
    }

    // Makes the archive at once and waits for it, for a Linux package that installs the app where only root can write and starts this from its install script.
    fun makeNow() {
        val appDir = System.getProperty("compose.application.resources.dir")?.let { File(it).parentFile } ?: return
        val java = javaOf(appDir) ?: return
        runCatching {
            make(
                appDir,
                java,
                File(appDir, Name),
                File(appDir, "$Name.part"),
                File(appDir, "$Name.version"),
            )
        }
    }

    // First a hidden run lists the classes the app uses, then Java writes the archive from that list.
    private fun make(appDir: File, java: File, archive: File, half: File, stamp: File) {
        val launcher = appDir.listFiles { file -> file.extension == "cfg" }?.firstOrNull() ?: return
        val lines = launcher.readLines()
        val here = appDir.absolutePath
        fun value(line: String) = line.substringAfter('=').replace("\$APPDIR", here)
        val classPath = lines
            .filter {
                it.startsWith(
                    "app.classpath=",
                )
            }.joinToString(File.pathSeparator, transform = ::value)
        val main = lines.firstOrNull { it.startsWith("app.mainclass=") }?.let(::value) ?: return
        val options = lines
            .filter {
                it.startsWith(
                    "java-options=",
                )
            }.map(::value)
            .filterNot { "SharedArchiveFile" in it || it.startsWith("-splash") }
        val work = Files.createTempDirectory("sumizuri-archive").toFile()
        try {
            val list = File(work, "classes.lst")
            val started = System.nanoTime()
            run(
                java,
                work,
                "list",
                listOf("-Xshare:off", "-XX:DumpLoadedClassList=${list.path}") + options +
                    listOf("-cp", classPath, main, "--warm"),
            )
            if (!list.isFile) return
            half.delete()
            run(
                java,
                work,
                "dump",
                listOf("-Xshare:dump", "-XX:SharedClassListFile=${list.path}", "-XX:SharedArchiveFile=${half.path}") +
                    options +
                    listOf("-cp", classPath),
            )
            if (!half.isFile) return
            // Java writes the archive read only, which on Windows would stop the next update from removing it.
            half.setWritable(true)
            archive.setWritable(true)
            archive.delete()
            if (!half.renameTo(archive)) return
            stamp.writeText(BuildInfo.Version)
            AppLog.info(
                Tag,
                "made the class archive in ${(System.nanoTime() - started) / 1_000_000_000} s, ${archive.length() / (1 shl 20)} MB",
            )
        } finally {
            work.deleteRecursively()
        }
    }

    // Runs Java with its options in a file, as the class path is longer than a command may be, at the lowest priority of the computer.
    private fun run(java: File, work: File, name: String, args: List<String>) {
        val file = File(work, "$name.args")
        file.writeText(args.joinToString("\n") { "\"" + it.replace("\\", "\\\\").replace("\"", "\\\"") + "\"" })
        val windows = File.separatorChar == '\\'
        val command = if (!windows &&
            File("/usr/bin/nice").isFile
        ) {
            listOf("/usr/bin/nice", "-n", "19", java.path, "@${file.path}")
        } else {
            listOf(java.path, "@${file.path}")
        }
        val process = ProcessBuilder(command)
            .redirectOutput(ProcessBuilder.Redirect.DISCARD)
            .redirectError(ProcessBuilder.Redirect.DISCARD)
            .start()
        if (windows) lowest(process.pid())
        if (!process.waitFor(StepMinutes, TimeUnit.MINUTES)) {
            process.destroyForcibly()
            AppLog.warn(Tag, "the $name step took too long and was stopped")
        }
    }

    // Gives a process the idle priority of Windows, so it only runs when nothing else wants the processor.
    private fun lowest(pid: Long) {
        runCatching {
            val kernel = Native.load("kernel32", Kernel32Priority::class.java)
            val process = kernel.OpenProcess(SetInformation, false, pid.toInt()) ?: return
            kernel.SetPriorityClass(process, IdlePriority)
            kernel.CloseHandle(process)
        }
    }

    // The java command of the runtime that comes with the app, which sits beside the app folder on Windows and Linux and inside the bundle on a Mac.
    private fun javaOf(appDir: File): File? {
        val root = appDir.parentFile ?: return null
        return listOf(
            File(root, "runtime/bin/java.exe"),
            File(root, "runtime/bin/java"),
            File(root, "runtime/Contents/Home/bin/java"),
        ).firstOrNull { it.isFile }
    }

    private const val SetInformation = 0x0200
    private const val IdlePriority = 0x40
}
