package com.sumizuri.app.source.browser.page

import com.sumizuri.app.core.log.AppLog
import java.io.File

private const val Tag = "desktop-browser"

// The most the cache of pages may hold, and the most the websites may keep for working offline before it is cleared.
private const val PageCacheBytes = 100L * 1024 * 1024
private const val OfflineMostBytes = 50L * 1024 * 1024

// How many page processes Chromium may run at once, which share when there are more pages.
private const val PageProcesses = 4

// Chromium keeps one list of features to turn off, so the ones the browser engine turns off on its own are named again here, with the spare page process it keeps ready.
private val OffFeatures = listOf(
    "AutofillActorMode",
    "EnableHangWatcher",
    "GlicActorUi",
    "KillOnInvalidNavigationHeaders",
    "LensOverlay",
    "SpareRendererForSitePerProcess",
    "Translate",
    "OptimizationHints",
    "OptimizationGuideModelDownloading",
    "MediaRouter",
    "DialMediaRouteProvider",
    "AutofillServerCommunication",
    // Pages that were left stay in memory for the back button, and links get loaded ahead on a guess, which a page that moves on all the time never uses.
    "BackForwardCache",
    "Prerender2",
)

// The parts of Chromium the app never uses, turned off: its own downloads of extra parts, extensions, translation, sync, the checks it makes in the background, crash reports and the size of the cache. Logins and cookies are left alone, so a bot check that was passed stays passed.
internal val TrimmedSwitches = listOf(
    "--disable-component-update",
    "--disable-extensions",
    "--disable-background-networking",
    "--disable-sync",
    "--disable-default-apps",
    "--disable-breakpad",
    "--disable-domain-reliability",
    "--disable-client-side-phishing-detection",
    "--no-pings",
    "--no-first-run",
    "--no-default-browser-check",
    "--disable-spell-checking",
    // Video and sound wait for a click, so ads on hidden pages never play.
    "--autoplay-policy=user-gesture-required",
    "--disable-features=${OffFeatures.joinToString(",")}",
    "--disk-cache-size=$PageCacheBytes",
    "--renderer-process-limit=$PageProcesses",
) + systemSwitches()

// Chromium locks its cookies with a key from the keyring of Linux or the keychain of a Mac, which can stop the start to ask for a password, so it keeps its own key in its folder instead. On Linux it also draws through X11, as the window of Java it draws into is always an X11 one, under Wayland too.
private fun systemSwitches(): List<String> {
    val system = System.getProperty("os.name").orEmpty()
    return when {
        system.startsWith("Linux") -> listOf("--password-store=basic", "--ozone-platform=x11")
        system.startsWith("Mac") -> listOf("--use-mock-keychain")
        else -> emptyList()
    }
}

// The extra parts Chromium downloaded for itself before they were turned off, which take a lot of room and nothing in the app uses: a speech engine, the module for paid video, models for search hints and their downloads.
private val UnusedParts = listOf(
    "component_crx_cache",
    "extensions_crx_cache",
    "WasmTtsEngine",
    "WidevineCdm",
    "OnDeviceHeadSuggestModel",
    "ActorSafetyLists",
    "OptimizationHints",
    "optimization_guide_model_store",
    "segmentation_platform",
    "hyphen-data",
    "ZxcvbnData",
    "MEIPreload",
    "AmountExtractionHeuristicRegexes",
    "CaptchaProviders",
    "PrivacySandboxAttestationsPreloaded",
    // Small lists that no longer update with the downloads off, where Chromium falls back to the ones built into it.
    "CertificateRevocation",
    "PKIMetadata",
    "Crowd Deny",
    "Dictionaries",
    "FileTypePolicies",
    "Safe Browsing",
    "SafetyTips",
    "SSLErrorAssistant",
    "Subresource Filter",
    "TrustTokenKeyCommitments",
)

// Clears what the browser keeps but does not need, before it starts, while nothing holds the files.
internal fun trimBrowserFolder(cacheDir: File) {
    if (!cacheDir.isDirectory) return
    var freed = 0L
    for (name in UnusedParts) {
        val part = File(cacheDir, name)
        if (!part.exists()) continue
        freed += sizeOf(part)
        part.deleteRecursively()
    }
    // What websites keep to work offline grows without end, and the app never opens a site offline.
    val offline = File(cacheDir, "Default/Service Worker/CacheStorage")
    val kept = sizeOf(offline)
    if (kept > OfflineMostBytes) {
        offline.deleteRecursively()
        freed += kept
    }
    if (freed >= 1 shl 20) AppLog.info(Tag, "cleared ${freed / (1 shl 20)} MB the browser does not need")
}

private fun sizeOf(file: File): Long = if (!file.exists()) {
    0
} else {
    file
        .walkTopDown()
        .filter {
            it.isFile
        }.sumOf { it.length() }
}
