package com.sumizuri.app.setup

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateMapOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.sumizuri.app.BuildInfo
import com.sumizuri.app.core.log.AppLog
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import java.io.File

// Whether the setup puts Sumizuri in or takes it away.
enum class SetupMode { Install, Uninstall }

// The pages of the setup, in the order they come.
internal enum class SetupStep { Welcome, Folder, Library, Shortcuts, Working, Done, Failed, Remove, Removed }

// The parts of an install, each shown in the list while it runs, with the share of the whole bar it takes.
internal enum class SetupPhase(val weight: Float) {
    Close(0.05f),
    Old(0.1f),
    Copy(0.7f),
    Shortcuts(0.08f),
    Finish(0.07f),
}

internal enum class PhaseState { Waiting, Running, Done }

// Each part of the install stays on screen at least this long, so the list can be read as it goes.
private const val MinPhaseMs = 450L

// What the setup knows and what the person chose, and the work behind the buttons. The work runs away from the window and reports back through the state the pages read.
internal class SetupModel(val mode: SetupMode, private val scope: CoroutineScope) {
    val source: File? = WindowsSetup.appImage()
    val installed: Installed? = if (mode == SetupMode.Install) WindowsSetup.installed() else null
    val legacy: List<Legacy> = if (mode == SetupMode.Install) WindowsSetup.legacy() else emptyList()
    val version = BuildInfo.Version
    val updating = installed != null || legacy.isNotEmpty()
    val size: Long = source?.let(WindowsSetup::sizeOf) ?: 0L

    var step by mutableStateOf(if (mode == SetupMode.Uninstall) SetupStep.Remove else SetupStep.Welcome)
    var custom by mutableStateOf(false)
    var appFolder by mutableStateOf(
        installed?.folder
            ?: if (mode == SetupMode.Uninstall && source != null) source else WindowsSetup.defaultAppFolder(),
    )
    var dataFolder by mutableStateOf(
        installed?.dataFolder ?: (if (mode == SetupMode.Uninstall) source?.let(WindowsSetup::dataFolderOf) else null)
            ?: WindowsSetup.defaultDataFolder(),
    )
    var menu by mutableStateOf(true)
    var desktop by mutableStateOf(if (updating) WindowsSetup.hasShortcut("desktop") else true)
    var startup by mutableStateOf(if (updating) WindowsSetup.hasShortcut("startup") else false)
    var removeData by mutableStateOf(false)
    var runningCount by mutableStateOf(0)
    var failure by mutableStateOf<String?>(null)
    val phases = mutableStateMapOf<SetupPhase, PhaseState>()

    // How much of the app has been copied, and of how much.
    val copied = MutableStateFlow(0L to 1L)

    // What to do once the window has closed: open the app, or start the removal.
    var afterClose: (() -> Unit)? = null

    // The steps the rail at the side lists for the way the person goes.
    val rail: List<SetupStep>
        get() = when {
            mode == SetupMode.Uninstall -> listOf(SetupStep.Remove, SetupStep.Removed)

            custom -> listOf(
                SetupStep.Welcome,
                SetupStep.Folder,
                SetupStep.Library,
                SetupStep.Shortcuts,
                SetupStep.Working,
                SetupStep.Done,
            )

            else -> listOf(SetupStep.Welcome, SetupStep.Working, SetupStep.Done)
        }

    // Whether a page that changes nothing on the computer is showing, so the window may be closed.
    val canClose: Boolean get() = step != SetupStep.Working

    private val folders: List<File> get() = (
        listOfNotNull(appFolder, installed?.folder) +
            legacy.mapNotNull { it.folder }
        ).distinct()

    // How many copies of Sumizuri run from the folders the setup will touch. It looks at every process, so it is asked away from the window.
    fun countRunning(): Int = runCatching { WindowsSetup.running(folders).size }.getOrDefault(0)

    // Free space on the drive of the app folder, or null when it cannot be read.
    fun freeSpace(): Long? = generateSequence(appFolder) { it.parentFile }.firstOrNull { it.exists() }?.usableSpace

    val enoughSpace: Boolean get() = (freeSpace() ?: Long.MAX_VALUE) > size

    // The library folder must not be inside the app folder, which an update partly clears.
    val libraryInsideApp: Boolean
        get() = dataFolder.absolutePath
            .lowercase()
            .trimEnd('\\')
            .plus('\\')
            .startsWith(appFolder.absolutePath.lowercase().trimEnd('\\') + "\\")

    val libraryFound: Boolean get() = File(dataFolder, "sumizuri.db").isFile || File(dataFolder, "profiles.json").isFile

    fun customize() {
        custom = true
        step = SetupStep.Folder
    }

    fun next() {
        step = when (step) {
            SetupStep.Folder -> SetupStep.Library
            SetupStep.Library -> SetupStep.Shortcuts
            else -> step
        }
    }

    fun back() {
        step = when (step) {
            SetupStep.Folder -> SetupStep.Welcome.also { custom = false }
            SetupStep.Library -> SetupStep.Folder
            SetupStep.Shortcuts -> SetupStep.Library
            else -> step
        }
    }

    // A folder picked for the app: one that already holds other things gets a Sumizuri folder inside it, so the app never mixes with them.
    fun pickedApp(folder: File) {
        appFolder =
            if (isEmptyOrMissing(folder) || File(folder, WindowsSetup.Exe).isFile ||
                folder.name.equals("Sumizuri", true)
            ) {
                folder
            } else {
                File(folder, "Sumizuri")
            }
    }

    // The same for the library, which may be picked where a library already is.
    fun pickedLibrary(folder: File) {
        val hasLibrary = File(folder, "sumizuri.db").isFile || File(folder, "profiles.json").isFile
        dataFolder =
            if (isEmptyOrMissing(folder) || hasLibrary ||
                folder.name.equals("Sumizuri", true)
            ) {
                folder
            } else {
                File(folder, "Sumizuri")
            }
    }

    private fun isEmptyOrMissing(folder: File) = !folder.exists() || folder.list().isNullOrEmpty()

    fun install() {
        val from = source
        if (from == null) {
            failure = "This setup has no app with it to install."
            step = SetupStep.Failed
            return
        }
        failure = null
        step = SetupStep.Working
        phases.clear()
        copied.value = 0L to 1L
        scope.launch {
            val plan = buildList {
                if (withContext(Dispatchers.IO) { WindowsSetup.running(folders).isNotEmpty() }) add(SetupPhase.Close)
                if (legacy.isNotEmpty()) add(SetupPhase.Old)
                add(SetupPhase.Copy)
                add(SetupPhase.Shortcuts)
                add(SetupPhase.Finish)
            }
            plan.forEach { phases[it] = PhaseState.Waiting }
            val result = runCatching {
                for (phase in plan) {
                    phases[phase] = PhaseState.Running
                    val started = System.nanoTime()
                    withContext(Dispatchers.IO) { run(phase, from) }
                    val passed = (System.nanoTime() - started) / 1_000_000
                    if (passed < MinPhaseMs) delay(MinPhaseMs - passed)
                    phases[phase] = PhaseState.Done
                }
            }
            result
                .onSuccess {
                    AppLog.info(
                        "setup",
                        "installed ${BuildInfo.Version} in ${appFolder.absolutePath}, library in ${dataFolder.absolutePath}",
                    )
                    step = SetupStep.Done
                }.onFailure { error ->
                    AppLog.error("setup", "the install failed", error)
                    failure = error.message ?: error.toString()
                    step = SetupStep.Failed
                }
        }
    }

    private fun run(phase: SetupPhase, from: File) {
        when (phase) {
            SetupPhase.Close -> WindowsSetup.close(WindowsSetup.running(folders))

            SetupPhase.Old -> legacy.forEach(WindowsSetup::removeLegacy)

            SetupPhase.Copy -> WindowsSetup.copy(from, appFolder) { done, total -> copied.value = done to total }

            SetupPhase.Shortcuts -> WindowsSetup.shortcuts(appFolder, menu, desktop, startup)

            SetupPhase.Finish -> {
                dataFolder.mkdirs()
                WindowsSetup.writeSettings(appFolder, dataFolder)
                WindowsSetup.register(appFolder, version, size)
                // The first start shows the light or dark picture to match Windows, as later starts do.
                LaunchSplash.follow(File(appFolder, "app/resources"))
            }
        }
    }

    // The share of the whole install done, from the parts finished and the part running.
    fun progress(): Float {
        val total = phases.keys
            .sumOf { it.weight.toDouble() }
            .toFloat()
            .coerceAtLeast(0.01f)
        var done = 0f
        for ((phase, state) in phases) {
            done += when (state) {
                PhaseState.Done -> phase.weight

                PhaseState.Running -> if (phase ==
                    SetupPhase.Copy
                ) {
                    phase.weight * copied.value.let { (a, b) -> a.toFloat() / b }
                } else {
                    phase.weight *
                        0.3f
                }

                PhaseState.Waiting -> 0f
            }
        }
        return (done / total).coerceIn(0f, 1f)
    }

    fun openWhenClosed() {
        val folder = appFolder
        afterClose = { WindowsSetup.launch(folder) }
    }

    // Closes any other Sumizuri running from the folder, then leaves the removal to run once the window closes.
    fun remove() {
        val folder = source
        if (folder == null || !SetupRemoval.isInstall(folder)) {
            failure = "Sumizuri was not found where this uninstaller runs."
            step = SetupStep.Failed
            return
        }
        step = SetupStep.Working
        scope.launch {
            withContext(Dispatchers.IO) { WindowsSetup.close(WindowsSetup.running(listOf(folder))) }
            delay(1_200)
            val library = if (removeData) dataFolder else null
            afterClose = { SetupRemoval.schedule(folder, library) }
            step = SetupStep.Removed
        }
    }
}
