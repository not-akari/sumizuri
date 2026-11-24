package com.sumizuri.app.setup

import com.sumizuri.app.core.log.AppLog
import com.sun.jna.Library
import com.sun.jna.Native
import com.sun.jna.Pointer
import java.io.File
import java.util.concurrent.TimeUnit

// The key under the classes of the person that tells Windows to open sumizuri links with the app.
internal const val LinkKey = "Software\\Classes\\sumizuri"

// The keys that tell Windows to open .sumizuri files, such as a shared backup or theme, with the app: the ending names a type, and the type names the app.
internal const val FileEndingKey = "Software\\Classes\\.sumizuri"
internal const val FileTypeKey = "Software\\Classes\\Sumizuri.File"

// The entry that tells a Linux desktop to open sumizuri links and files with the app. It is hidden from the menu of apps, which keeps the entry of the package.
private const val LinuxEntry = "sumizuri-links.desktop"

// The type of the files of the app, as Linux desktops name types.
private const val LinuxFileType = "application/x-sumizuri"

// The event that tells the Explorer the types of files changed.
private const val AssociationsChanged = 0x08000000

private interface Shell32 : Library {
    fun SHChangeNotify(event: Int, flags: Int, item1: Pointer?, item2: Pointer?)
}

// Tells Windows that sumizuri links, such as an Open in Sumizuri button on the page of a repo, and .sumizuri files open with this copy of the app.
internal fun registerAppLinks(exe: File) {
    val icon = mapOf("" to "\"${exe.absolutePath}\",0")
    val command = mapOf("" to "\"${exe.absolutePath}\" \"%1\"")
    WinRegistry.write(LinkKey, texts = mapOf("" to "URL:Sumizuri", "URL Protocol" to ""), numbers = emptyMap())
    WinRegistry.write("$LinkKey\\DefaultIcon", texts = icon, numbers = emptyMap())
    WinRegistry.write("$LinkKey\\shell\\open\\command", texts = command, numbers = emptyMap())
    WinRegistry.write(FileEndingKey, texts = mapOf("" to "Sumizuri.File"), numbers = emptyMap())
    WinRegistry.write(FileTypeKey, texts = mapOf("" to "Sumizuri file"), numbers = emptyMap())
    WinRegistry.write("$FileTypeKey\\DefaultIcon", texts = icon, numbers = emptyMap())
    WinRegistry.write("$FileTypeKey\\shell\\open\\command", texts = command, numbers = emptyMap())
    // The Explorer learns at once that the files have an app and an icon now.
    runCatching { Native.load("shell32", Shell32::class.java).SHChangeNotify(AssociationsChanged, 0, null, null) }
}

// Run at each start of an installed app, so the links and files follow the copy that runs, also after it moved or was updated. A run from the build leaves them alone.
fun refreshAppLinks() {
    val launcher = System.getProperty("jpackage.app-path")?.let(::File) ?: return
    val system = System.getProperty("os.name").orEmpty()
    when {
        system.startsWith("Windows") -> refreshWindows(launcher)
        system.startsWith("Linux") -> refreshLinux(launcher)
    }
}

private fun refreshWindows(launcher: File) {
    val folder = launcher.parentFile ?: return
    if (!WindowsSetup.registeredAt(folder)) return
    val wanted = "\"${launcher.absolutePath}\" \"%1\""
    val linked = WinRegistry.text("$LinkKey\\shell\\open\\command", "") == wanted
    if (linked && WinRegistry.text("$FileTypeKey\\shell\\open\\command", "") == wanted) return
    runCatching {
        registerAppLinks(launcher)
    }.onFailure { AppLog.warn("setup", "the sumizuri links could not be registered: ${it.message}") }
}

// Writes the entry of the links in the folder of apps of the person, the way the desktop standard asks, and makes it the one for sumizuri links and files. The package or the unpacked folder both work, as the entry names the launcher that runs now.
private fun refreshLinux(launcher: File) {
    val data =
        System.getenv("XDG_DATA_HOME")?.takeIf { it.isNotBlank() }?.let(::File)
            ?: File(System.getProperty("user.home"), ".local/share")
    registerLinuxFileType(data)
    val folder = File(data, "applications")
    val entry = File(folder, LinuxEntry)
    val icon = launcher.parentFile
        ?.parentFile
        ?.resolve("lib")
        ?.listFiles { file -> file.extension == "png" }
        ?.firstOrNull()
    val wanted = buildString {
        appendLine("[Desktop Entry]")
        appendLine("Type=Application")
        appendLine("Name=Sumizuri")
        appendLine("Exec=\"${launcher.absolutePath.replace("\"", "\\\"")}\" %u")
        icon?.let { appendLine("Icon=${it.absolutePath}") }
        appendLine("NoDisplay=true")
        appendLine("Terminal=false")
        appendLine("MimeType=x-scheme-handler/sumizuri;$LinuxFileType;")
    }
    if (entry.isFile && entry.readText() == wanted) return
    runCatching {
        folder.mkdirs()
        entry.writeText(wanted)
        // xdg-mime makes the entry the one for the links and the files. A desktop without it reads the entry by its types the next time it looks.
        run("xdg-mime", "default", LinuxEntry, "x-scheme-handler/sumizuri")
        run("xdg-mime", "default", LinuxEntry, LinuxFileType)
        run("update-desktop-database", folder.absolutePath)
        AppLog.info("setup", "sumizuri links and files open with ${launcher.absolutePath}")
    }.onFailure { AppLog.warn("setup", "the sumizuri links could not be registered: ${it.message}") }
}

// The type of .sumizuri files, which a Linux desktop reads from a small file in the folder of types of the person.
private fun registerLinuxFileType(data: File) {
    val types = File(data, "mime")
    val file = File(types, "packages/sumizuri.xml")
    val wanted = """
        <?xml version="1.0" encoding="UTF-8"?>
        <mime-info xmlns="http://www.freedesktop.org/standards/shared-mime-info">
          <mime-type type="$LinuxFileType">
            <comment>Sumizuri file</comment>
            <glob pattern="*.sumizuri"/>
          </mime-type>
        </mime-info>
    """.trimIndent() + "\n"
    if (file.isFile && file.readText() == wanted) return
    runCatching {
        file.parentFile.mkdirs()
        file.writeText(wanted)
        run("update-mime-database", types.absolutePath)
    }.onFailure { AppLog.warn("setup", "the type of .sumizuri files could not be registered: ${it.message}") }
}

// Runs a tool of the desktop and waits a little for it. A tool that is not there is passed over.
private fun run(vararg command: String) {
    runCatching { ProcessBuilder(*command).redirectErrorStream(true).start().waitFor(5, TimeUnit.SECONDS) }
}
