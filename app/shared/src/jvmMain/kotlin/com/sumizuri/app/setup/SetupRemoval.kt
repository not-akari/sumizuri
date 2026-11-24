package com.sumizuri.app.setup

import com.sumizuri.app.core.log.AppLog
import java.io.File

// What the app keeps in its library folder, by name. Removing the library takes only these, so nothing else in a folder the person chose is touched, and their own files in local stay.
private val LibraryItems = listOf("profiles", "downloads", "browser", "logs", "profiles.json", "sumizuri.db", "sumizuri.db-wal", "sumizuri.db-shm", "sumizuri.db.lck")

// What the setup puts in the folder of the app, and the files the app writes beside them.
private val AppItems = listOf("Sumizuri.exe", "app", "runtime", "sumizuri.ini")

// Takes Sumizuri away. It runs from the folder it removes, which Windows will not let it delete while it runs, so a short script in the temporary folder waits for this process and its launcher to end and then deletes the app, its shortcuts and its record in the apps of Windows, and the library when that was asked, and lastly itself. The script is started apart from the setup, since the job the launcher runs the setup in would end it together with the setup.
internal object SetupRemoval {
    private val script = """
        ${'$'}ErrorActionPreference = 'SilentlyContinue'
        while (${'$'}waitFor | Where-Object { Get-Process -Id ${'$'}_ }) { Start-Sleep -Milliseconds 200 }
        Start-Sleep -Milliseconds 300
        foreach (${'$'}name in ${'$'}appItems) { Remove-Item -LiteralPath (Join-Path ${'$'}app ${'$'}name) -Recurse -Force }
        if (-not (Get-ChildItem -LiteralPath ${'$'}app -Force)) { Remove-Item -LiteralPath ${'$'}app -Force }
        foreach (${'$'}link in ${'$'}links) { Remove-Item -LiteralPath ${'$'}link -Force }
        if (${'$'}dropRecord) { Remove-Item -LiteralPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\Sumizuri' -Recurse -Force; Remove-Item -LiteralPath 'HKCU:\Software\Classes\sumizuri' -Recurse -Force; Remove-Item -LiteralPath 'HKCU:\Software\Classes\.sumizuri' -Recurse -Force; Remove-Item -LiteralPath 'HKCU:\Software\Classes\Sumizuri.File' -Recurse -Force }
        if (${'$'}data) {
            foreach (${'$'}name in ${'$'}dataItems) { Remove-Item -LiteralPath (Join-Path ${'$'}data ${'$'}name) -Recurse -Force }
            if (-not (Get-ChildItem -LiteralPath ${'$'}data -Force)) { Remove-Item -LiteralPath ${'$'}data -Force }
            Remove-Item -LiteralPath (Join-Path ${'$'}env:TEMP 'sumizuri_covers') -Recurse -Force
            Remove-Item -LiteralPath (Join-Path ${'$'}env:TEMP 'sumizuri-updates') -Recurse -Force
        }
        Remove-Item -LiteralPath ${'$'}PSCommandPath -Force
    """.trimIndent()

    // Whether a folder is really an install of Sumizuri, which is all the removal will ever touch.
    fun isInstall(folder: File): Boolean = File(folder, WindowsSetup.Exe).isFile && File(folder, "app").isDirectory && File(folder, "runtime").isDirectory

    // Starts the script, which goes on after this process ends. Only the shortcuts that start this copy go, and the record in the apps of Windows only when it is the one of this copy, so removing one copy never touches another. The library goes too when its folder is given.
    fun schedule(folder: File, dataFolder: File?) {
        check(isInstall(folder)) { "${folder.absolutePath} is not an install of Sumizuri" }
        val links = WindowsSetup.shortcutFiles().filter { link -> link.isFile && ShellLinks.target(link)?.let { inside(it, folder) } == true }
        // This process and the launcher that started it both run from the folder, and the files stay locked until both have ended.
        val waitFor = WindowsSetup
            .lineage()
            .filter {
                it.pid() == ProcessHandle.current().pid() || it
                    .info()
                    .command()
                    .orElse(null)
                    ?.let { command -> inside(File(command), folder) } == true
            }.map { it.pid() }

        // The values go into the script itself, as a program started apart does not share the environment of this one.
        fun text(value: String) = "'" + value.replace("'", "''") + "'"
        fun list(values: List<String>) = "@(" + values.joinToString(", ", transform = ::text) + ")"
        val values = listOf(
            "${'$'}waitFor = @(${waitFor.joinToString(", ")})",
            "${'$'}app = ${text(folder.absolutePath)}",
            "${'$'}appItems = ${list(AppItems)}",
            "${'$'}links = ${list(links.map { it.absolutePath })}",
            "${'$'}dropRecord = ${if (WindowsSetup.registeredAt(folder)) "${'$'}true" else "${'$'}false"}",
            "${'$'}data = ${text(dataFolder?.absolutePath ?: "")}",
            "${'$'}dataItems = ${list(LibraryItems)}",
        )
        val file = File.createTempFile("sumizuri-remove-", ".ps1")
        // PowerShell reads a script with a byte order mark as UTF-8, so folders in any language come through.
        file.writeText("" + values.joinToString("\n") + "\n" + script, Charsets.UTF_8)
        AppLog.info("setup", "removing ${folder.absolutePath}" + (dataFolder?.let { " and the library in ${it.absolutePath}" } ?: "") + ", ${links.size} shortcuts")
        val command = StartApart.scriptCommand(file)
        if (!StartApart.start(command, file.parentFile, hidden = true)) ProcessBuilder(StartApart.powerShell.absolutePath, "-NoProfile", "-NonInteractive", "-ExecutionPolicy", "Bypass", "-WindowStyle", "Hidden", "-File", file.absolutePath).start()
    }

    // Whether a file lies in a folder or any folder under it.
    private fun inside(file: File, folder: File): Boolean = file.absoluteFile
        .toPath()
        .normalize()
        .startsWith(folder.absoluteFile.toPath().normalize())
}
