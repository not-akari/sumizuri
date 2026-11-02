package com.sumizuri.app.data.account

// Settings that belong to the device and never sync: the look and layout, the language, the theme, memory and storage, downloads, the app lock, app updates, backups, the timing and notices of the library check, where the app was left, and the sync settings themselves.
private val DevicePrefixes = listOf(
    "app.",
    "layout.",
    "theme.",
    "cache.",
    "debug.",
    "downloads.",
    "security.",
    "appupdate.",
    "backup.",
    "session.",
    "controls.",
    "profile.",
    "sync.",
)

// Single settings of the device, by their whole name.
private val DeviceNames = setOf(
    "themeMode",
    "onboarding.done",
    "settings.seen",
    "web.inApp",
    "browse.style",
    "pace.pageTenths",
    "lastUpdateCheck",
    "lastSourceCheck",
    "library.update.background",
    "library.update.charging",
    "library.update.hours",
    "library.update.wifiOnly",
    "library.update.notify",
    "library.update.noticeAsked",
)

// The parts of the reader that depend on the screen in hand, for the defaults and for each title alike.
private val DeviceReaderFields = setOf(
    "orientation",
    "dim",
    "warmth",
    "keepScreenOn",
    "hideSystemBars",
    "controlShade",
    "pageStrip",
    "progressBar",
    "quality",
    "width",
    "autoSpeed",
)

// The parts of the player that depend on the device: touch gestures, the quality for its connection and the log.
private val DevicePlayerFields = setOf(
    "showLog",
    "qualityMode",
    "preferredQuality",
    "swipeGestures",
    "doubleTapSeek",
    "doubleTapSeconds",
    "ambient",
)

// Whether a setting goes to the other devices of the account. Reading habits do, such as the reading mode, the text size, the subtitles and which titles the library check skips, and what belongs to this device stays on it.
fun syncsAcrossDevices(name: String): Boolean {
    if (name in DeviceNames || DevicePrefixes.any { name.startsWith(it) }) return false
    val field = name.substringAfterLast('.')
    if (name.startsWith("reader.") && field in DeviceReaderFields) return false
    if (name.startsWith("player.") && field in DevicePlayerFields) return false
    return true
}
