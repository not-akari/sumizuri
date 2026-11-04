package com.sumizuri.app.data

import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.setValue
import com.sumizuri.app.core.AppBuild
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.launch

// The color behind the book. Keep these in step with scripts/app-icons.js, which makes the Android launcher icons.
enum class IconBack(val color: Long) {
    Ink(0xFF0F1114),
    Paper(0xFFEDE6D6),
    Sakura(0xFFE7A3B6),
    Indigo(0xFF2E3170),
    Matcha(0xFF6F8F55),
    Night(0xFF1A1D24),
}

// How the book and the disc under it are drawn: the disc, the two pages, the spine, the written lines and the two page edges under the book.
enum class IconBook(
    val disc: Long,
    val leftPage: Long,
    val rightPage: Long,
    val spine: Long,
    val lines: Long,
    val edgeDark: Long,
    val edgeLight: Long,
) {
    Classic(0xFF1A1D24, 0xFFF4F1E4, 0xFFD9D6CA, 0xFFBEBBAF, 0xFFB8B5A9, 0xFF8E8A7E, 0xFFB4B0A2),
    Mono(0xFF141414, 0xFFFFFFFF, 0xFFD4D4D4, 0xFFB0B0B0, 0xFF9A9A9A, 0xFF5E5E5E, 0xFF9A9A9A),
    Moon(0xFFE8E0B0, 0xFF1A1D24, 0xFF2C303A, 0xFF3C414D, 0xFF5D6473, 0xFF0F1114, 0xFF3C414D),
    Gold(0xFF0F1114, 0xFFF4F1E4, 0xFFD9D6CA, 0xFFBEBBAF, 0xFFC79A4A, 0xFF8E8A7E, 0xFFB4B0A2),
}

// The ring round the disc, or none.
enum class IconRing(val color: Long?) {
    Cream(0xFFE8E0B0),
    Gold(0xFFD9A441),
    White(0xFFFFFFFF),
    None(null),
}

// The icon of the app, put together from a background, a book and a ring.
data class AppIcon(val back: IconBack, val book: IconBook, val ring: IconRing) {
    // How it is kept.
    val key: String get() = "${back.name}-${book.name}-${ring.name}"

    // The name of its launcher entry on Android. The five icons of earlier versions keep their old names.
    val launcherName: String
        get() = if (book == IconBook.Classic && ring == IconRing.Cream && back != IconBack.Night) {
            "Icon${back.name}"
        } else {
            "Icon${back.name}${book.name}${ring.name}"
        }

    companion object {
        val Usual = AppIcon(IconBack.Ink, IconBook.Classic, IconRing.Cream)

        val all: List<AppIcon> by lazy {
            IconBack.entries.flatMap { back ->
                IconBook.entries.flatMap { book -> IconRing.entries.map { ring -> AppIcon(back, book, ring) } }
            }
        }

        fun of(key: String?): AppIcon? = all.firstOrNull { it.key == key }
    }
}

expect object AppIcons {
    // Whether this system lets the app change its icon.
    val supported: Boolean

    // Whether the icon picked is the one in the launcher, and not only the one of the open window.
    val launcher: Boolean

    // Whether a shortcut with the exact icon can be put on the home screen.
    val canPin: Boolean

    fun current(): AppIcon

    // Puts the icon in place. On Android it goes through every launcher entry, so it is called away from the main thread.
    fun choose(icon: AppIcon)

    // The design a person made, kept on this device alone.
    fun loadDesign(): String?

    fun saveDesign(text: String)

    // Asks the home screen for a shortcut that opens the app with the exact icon, and gives whether it was asked.
    fun pin(design: IconDesign, label: String): Boolean

    // Gives a shortcut already on the home screen the new icon.
    fun refreshPin(design: IconDesign)
}

// The icon in use, which the editor and the window of a computer follow. It changes at once, and the system catches up a moment after the last change, so dragging a color does not swap the launcher entry each time.
object AppIconShown {
    var design by mutableStateOf<IconDesign?>(null)
        private set

    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    private val wanted = MutableStateFlow<IconDesign?>(null)

    init {
        scope.launch {
            wanted.filterNotNull().collectLatest { chosen ->
                delay(SettleMs)
                runCatching {
                    AppIcons.saveDesign(chosen.encode())
                    AppIcons.choose(chosen.closest())
                    AppIcons.refreshPin(chosen)
                }
            }
        }
    }

    fun now(): IconDesign =
        design ?: (IconDesign.decode(AppIcons.loadDesign()) ?: IconDesign.of(AppIcons.current())).also { design = it }

    fun pick(chosen: IconDesign) {
        design = chosen
        wanted.value = chosen
    }

    // Puts an icon picked while the editor was public back to the usual one, once per start and away from the main thread, since it reads every launcher entry.
    private var resetDone = false

    internal fun resetSoon() {
        if (resetDone) return
        resetDone = true
        scope.launch { runCatching { if (AppIcons.current() != AppIcon.Usual) AppIcons.choose(AppIcon.Usual) } }
    }
}

// How long the icon waits after the last change before the system is told.
private const val SettleMs = 400L

// Whether people can pick the icon yet. It stays off until the icons are ready to be shown to everyone.
const val AppIconsReady = false

// Whether the editor shows: once ready for everyone, and always in a debug build so it can be tried before then.
val appIconsShown: Boolean get() = AppIconsReady || AppBuild.isDebug

// While the icons are hidden, an icon picked in an earlier version is put back to the usual one, since there is no other way back to it.
fun AppIcons.resetWhileHidden() {
    if (appIconsShown || !supported) return
    AppIconShown.resetSoon()
}
