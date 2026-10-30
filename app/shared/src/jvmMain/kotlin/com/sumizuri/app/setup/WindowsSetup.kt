package com.sumizuri.app.setup

import com.sumizuri.app.core.log.AppLog
import java.io.File
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.util.concurrent.TimeUnit

private const val Tag = "setup"

// Sumizuri as it is already on this computer: its folder, its version and the folder of its library.
internal data class Installed(val folder: File, val version: String?, val dataFolder: File?)

// Sumizuri as an earlier installer put it in, which the setup takes away before it installs: an MSI made by jpackage, or an install of Inno Setup.
internal data class Legacy(val key: String, val folder: File?, val msi: Boolean, val uninstaller: String?)

// What the setup does on Windows: find what is installed, close the app, copy it, and leave the records Windows uses to list it and take it away. Everything is for the person only, in their own folders and their part of the registry.
internal object WindowsSetup {
    const val Exe = "Sumizuri.exe"
    private const val Uninstall = "Software\\Microsoft\\Windows\\CurrentVersion\\Uninstall"
    private const val OurKey = "$Uninstall\\Sumizuri"
    private const val SettingsFile = "sumizuri.ini"

    private val home = File(System.getProperty("user.home"))
    private val localAppData = File(System.getenv("LOCALAPPDATA") ?: File(home, "AppData\\Local").path)
    private val appData = File(System.getenv("APPDATA") ?: File(home, "AppData\\Roaming").path)

    fun defaultAppFolder(): File = File(localAppData, "Programs\\Sumizuri")

    fun defaultDataFolder(): File = File(home, ".sumizuri")

    // The folder of the app this setup comes with: the one the launcher that started it sits in. A run from the build can name one for trying the setup out.
    fun appImage(): File? {
        val chosen = System.getProperty("sumizuri.setup.source")?.let(::File)
        val launcher = System.getProperty("jpackage.app-path")?.let { File(it).parentFile }
        return (chosen ?: launcher)?.takeIf {
            File(it, Exe).isFile && File(it, "app").isDirectory &&
                File(it, "runtime").isDirectory
        }
    }

    fun installed(): Installed? {
        val folder =
            WinRegistry.text(OurKey, "InstallLocation")?.let(::File)?.takeIf { File(it, Exe).isFile } ?: return null
        return Installed(folder, WinRegistry.text(OurKey, "DisplayVersion"), dataFolderOf(folder))
    }

    // The library folder an install chose, from the file beside the app.
    fun dataFolderOf(folder: File): File? = runCatching {
        File(folder, SettingsFile)
            .takeIf { it.isFile }
            ?.readLines(Charsets.UTF_8)
            ?.map { it.removePrefix("").trim() }
            ?.firstOrNull { it.startsWith("DataFolder=") }
            ?.substringAfter('=')
            ?.trim()
            ?.takeIf { it.isNotEmpty() }
            ?.let(::File)
    }.getOrNull()

    fun legacy(): List<Legacy> = WinRegistry.children(Uninstall).mapNotNull { key ->
        if (key == "Sumizuri") return@mapNotNull null
        val path = "$Uninstall\\$key"
        if (WinRegistry.text(path, "DisplayName") != "Sumizuri") return@mapNotNull null
        val msi = WinRegistry.number(path, "WindowsInstaller") == 1
        val folder = WinRegistry.text(path, "InstallLocation")?.takeIf { it.isNotBlank() }?.let(::File)
            ?: if (msi) File(localAppData, "Sumizuri") else null
        Legacy(key, folder, msi, WinRegistry.text(path, "UninstallString"))
    }

    // Copies of Sumizuri that run from any of the folders given, other than this one. The launcher that started this one is left out too: it starts the app as its child, and ending it would end this.
    fun running(folders: List<File>): List<ProcessHandle> {
        val roots = folders.map { it.absolutePath.lowercase().trimEnd('\\') + "\\" }
        val mine = lineage().map { it.pid() }.toSet()
        return ProcessHandle
            .allProcesses()
            .filter { process ->
                val command = process
                    .info()
                    .command()
                    .orElse(null)
                    ?.lowercase() ?: return@filter false
                process.pid() !in mine && command.endsWith(Exe.lowercase()) && roots.any { command.startsWith(it) }
            }.toList()
    }

    // This process and those that started it, nearest first, so far as Windows still knows them.
    fun lineage(): List<ProcessHandle> = generateSequence(ProcessHandle.current()) {
        it.parent().orElse(null)
    }.take(16).toList()

    // Whether the record of Sumizuri in the apps of Windows is the one of this folder, and not of another copy.
    fun registeredAt(folder: File): Boolean =
        WinRegistry.text(OurKey, "InstallLocation")?.let { File(it).absoluteFile == folder.absoluteFile } == true

    // Asks each to end, and ends it when it does not within a few seconds. The library keeps a journal, so what it wrote last is safe.
    fun close(processes: List<ProcessHandle>) {
        for (process in processes) {
            process.destroy()
            runCatching { process.onExit().get(5, TimeUnit.SECONDS) }.onFailure { process.destroyForcibly() }
        }
    }

    fun removeLegacy(old: Legacy) {
        AppLog.info(Tag, "removing the earlier install ${old.key}")
        val command = when {
            old.msi -> listOf("msiexec.exe", "/x", old.key, "/qn", "/norestart")

            old.uninstaller != null -> listOf(
                old.uninstaller.trim('"'),
                "/VERYSILENT",
                "/SUPPRESSMSGBOXES",
                "/NORESTART",
            )

            else -> return
        }
        val process = ProcessBuilder(command).redirectErrorStream(true).start()
        process.inputStream.readAllBytes()
        process.waitFor(3, TimeUnit.MINUTES)
    }

    fun sizeOf(folder: File): Long = folder.walkTopDown().filter { it.isFile }.sumOf { it.length() }

    // Copies the app into its folder. An update first takes out the old app and runtime, whose files are named after their contents and would pile up. A folder that holds something else is never cleared.
    fun copy(from: File, to: File, progress: (done: Long, total: Long) -> Unit) {
        if (File(to, Exe).isFile) {
            // Java leaves its class archives read only, which Windows will not delete.
            for (old in listOf(File(to, "app"), File(to, "runtime"))) {
                old.walkTopDown().filter { it.isFile && !it.canWrite() }.forEach { it.setWritable(true) }
                old.deleteRecursively()
            }
        }
        val files = from.walkTopDown().filter { it.isFile }.toList()
        val total = files.sumOf { it.length() }.coerceAtLeast(1)
        var done = 0L
        val buffer = ByteArray(1 shl 20)
        for (file in files) {
            val target = File(to, file.relativeTo(from).path)
            target.parentFile.mkdirs()
            file.inputStream().use { input ->
                target.outputStream().use { output ->
                    while (true) {
                        val read = input.read(buffer)
                        if (read < 0) break
                        output.write(buffer, 0, read)
                        done += read
                        progress(done, total)
                    }
                }
            }
            target.setLastModified(file.lastModified())
        }
    }

    // Writes the choices the app reads when it starts: for now the folder of its library.
    fun writeSettings(folder: File, dataFolder: File) {
        File(
            folder,
            SettingsFile,
        ).writeText(
            "; Written by the setup of Sumizuri. The app reads where its library is from here.\nDataFolder=${dataFolder.absolutePath}\n",
            Charsets.UTF_8,
        )
    }

    // Lists the app in the apps of Windows, with its version and size, and what takes it away again, and opens sumizuri links with it.
    fun register(folder: File, version: String, bytes: Long) {
        val exe = File(folder, Exe).absolutePath
        WinRegistry.write(
            OurKey,
            texts = mapOf(
                "DisplayName" to "Sumizuri",
                "DisplayVersion" to version,
                "Publisher" to "Sumizuri",
                "DisplayIcon" to "$exe,0",
                "InstallLocation" to folder.absolutePath,
                "UninstallString" to "\"$exe\" --uninstall",
                "InstallDate" to LocalDate.now().format(DateTimeFormatter.BASIC_ISO_DATE),
            ),
            numbers = mapOf("NoModify" to 1, "NoRepair" to 1, "EstimatedSize" to (bytes / 1024).toInt()),
        )
        registerAppLinks(File(exe))
    }

    private fun shortcut(place: String): File = when (place) {
        "menu" -> File(
            shellFolder("Programs", File(appData, "Microsoft\\Windows\\Start Menu\\Programs")),
            "Sumizuri.lnk",
        )

        "startup" -> File(
            shellFolder("Startup", File(appData, "Microsoft\\Windows\\Start Menu\\Programs\\Startup")),
            "Sumizuri.lnk",
        )

        else -> File(shellFolder("Desktop", File(home, "Desktop")), "Sumizuri.lnk")
    }

    // A folder of the person, such as the desktop, which they may have moved, as Windows keeps it, with the names in it such as %USERPROFILE% filled in.
    private fun shellFolder(name: String, fallback: File): File {
        val raw =
            WinRegistry.text("Software\\Microsoft\\Windows\\CurrentVersion\\Explorer\\User Shell Folders", name)
                ?: return fallback
        val path = Regex("%([^%]+)%").replace(raw) { found -> System.getenv(found.groupValues[1]) ?: found.value }
        return File(path).takeIf { it.isDirectory } ?: fallback
    }

    fun hasShortcut(place: String): Boolean = shortcut(place).isFile

    // Every shortcut the setup may have made, for the removal.
    fun shortcutFiles(): List<File> = listOf("menu", "desktop", "startup").map(::shortcut)

    // Makes or takes away the shortcuts of the Start menu, the desktop and the start of Windows.
    fun shortcuts(folder: File, menu: Boolean, desktop: Boolean, startup: Boolean) {
        val wanted = mapOf("menu" to menu, "desktop" to desktop, "startup" to startup)
        for ((place, keep) in wanted) if (!keep) shortcut(place).delete()
        links(folder, wanted.filterValues { it }.keys.map { shortcut(it) })
    }

    // Makes shortcuts to the app at the files given.
    fun links(folder: File, make: List<File>) {
        for (link in make) ShellLinks.make(link, File(folder, Exe), "Sumizuri")
    }

    // Opens the app, apart from the setup so it stays open when the setup ends.
    fun launch(folder: File) {
        val exe = File(folder, Exe)
        if (!StartApart.start(
                "\"${exe.absolutePath}\"",
                folder,
                hidden = false,
            )
        ) {
            ProcessBuilder(exe.absolutePath).directory(folder).start()
        }
    }
}
