package com.sumizuri.app.playback

import com.sun.jna.Callback
import com.sun.jna.Library
import com.sun.jna.Memory
import com.sun.jna.Native
import com.sun.jna.NativeLibrary
import com.sun.jna.Platform
import com.sun.jna.Pointer
import com.sun.jna.ptr.PointerByReference
import java.io.File

// The calls of libmpv the player uses: the client, which plays and answers questions, and the software renderer, which draws each frame into memory.
@Suppress("FunctionName")
internal interface MpvApi : Library {
    fun mpv_create(): Pointer?
    fun mpv_initialize(handle: Pointer): Int
    fun mpv_terminate_destroy(handle: Pointer)
    fun mpv_set_option_string(handle: Pointer, name: String, data: String): Int
    fun mpv_set_property_string(handle: Pointer, name: String, data: String): Int
    fun mpv_get_property_string(handle: Pointer, name: String): Pointer?
    fun mpv_free(data: Pointer)
    fun mpv_command(handle: Pointer, args: Array<String?>): Int
    fun mpv_wait_event(handle: Pointer, timeout: Double): Pointer
    fun mpv_request_log_messages(handle: Pointer, minimum: String): Int
    fun mpv_error_string(error: Int): String
    fun mpv_render_context_create(result: PointerByReference, handle: Pointer, params: Pointer): Int
    fun mpv_render_context_set_update_callback(context: Pointer, callback: MpvUpdate?, data: Pointer?)
    fun mpv_render_context_update(context: Pointer): Long
    fun mpv_render_context_render(context: Pointer, params: Pointer): Int
    fun mpv_render_context_free(context: Pointer)
}

// Called by mpv from its own thread when a new frame can be drawn. Nothing of mpv may be called from inside it.
internal fun interface MpvUpdate : Callback {
    fun invoke(data: Pointer?)
}

// The numbers libmpv uses for its events, the parts of a render call, and how a file ended.
internal object Mpv {
    const val EventShutdown = 1
    const val EventLogMessage = 2
    const val EventEndFile = 7
    const val EventFileLoaded = 8
    const val EventVideoReconfig = 17
    const val EventPlaybackRestart = 21

    const val EndEof = 0
    const val EndError = 4

    const val ParamApiType = 1
    const val ParamSwSize = 17
    const val ParamSwFormat = 18
    const val ParamSwStride = 19
    const val ParamSwPointer = 20

    // The bit of an update that says a new frame is ready.
    const val UpdateFrame = 1L

    // A list of render parameters as libmpv reads it: each a number and a pointer, and an empty one at the end.
    fun params(vararg entries: Pair<Int, Pointer>): Memory {
        val size = Native.POINTER_SIZE * 2
        val memory = Memory(size.toLong() * (entries.size + 1))
        memory.clear()
        entries.forEachIndexed { index, (type, data) ->
            memory.setInt(index.toLong() * size, type)
            memory.setPointer(index.toLong() * size + Native.POINTER_SIZE, data)
        }
        return memory
    }

    // A string in memory that stays while the memory is held.
    fun text(value: String): Memory = Memory(value.toByteArray().size + 1L).apply { setString(0, value) }
}

// Finds libmpv once while the app runs. On Windows it comes with the app, in the folder of its resources or, while the app is built, in the folder the build puts it in. Elsewhere it is the one the system has, from Homebrew on a Mac or a package such as libmpv2 on Linux.
internal object MpvLibrary {
    @Volatile private var loaded: MpvApi? = null

    @Volatile private var tried = false

    fun api(): MpvApi? {
        if (tried) return loaded
        return synchronized(this) {
            if (!tried) {
                loaded = load()
                tried = true
            }
            loaded
        }
    }

    private fun load(): MpvApi? {
        val system = System.getProperty("os.name").orEmpty().lowercase()
        val names = if ("win" in system) listOf("libmpv-2", "mpv-2", "libmpv-1", "mpv-1") else listOf("mpv")
        val folders = buildList {
            System.getProperty("sumizuri.mpv.dir")?.let { add(it) }
            System.getProperty("compose.application.resources.dir")?.let { add(it) }
            // A run started from the folder of the desktop app, such as a hot reload run, finds the copy the build made.
            add(File(System.getProperty("user.dir"), "build/app-resources/windows").path)
            if ("mac" in system) addAll(listOf("/opt/homebrew/lib", "/usr/local/lib"))
        }.filter { File(it).isDirectory }
        for (name in names) for (folder in folders) NativeLibrary.addSearchPath(name, folder)
        for (name in names) {
            val api = runCatching { Native.load(name, MpvApi::class.java) }.getOrNull()
            if (api != null) {
                if ("win" !in system) numbersInC(mac = "mac" in system)
                return api
            }
        }
        return null
    }

    // Java takes the locale of the system when it starts, and libmpv refuses to start unless numbers are written the C way with a dot, so a Spanish or German system would have no player.
    private fun numbersInC(mac: Boolean) {
        val numeric = if (mac) MacNumeric else LinuxNumeric
        runCatching { Native.load(Platform.C_LIBRARY_NAME, LibC::class.java).setlocale(numeric, "C") }
    }
}

// The number of the numbers part of the locale, which differs between the C library of Linux and of a Mac.
private const val LinuxNumeric = 1
private const val MacNumeric = 4

private interface LibC : Library {
    fun setlocale(category: Int, locale: String?): Pointer?
}
