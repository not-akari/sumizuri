package com.sumizuri.app.playback

import androidx.compose.runtime.Composable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.Modifier
import io.ktor.client.HttpClient
import io.ktor.client.plugins.HttpTimeout
import io.ktor.client.request.get
import io.ktor.client.request.header
import io.ktor.client.statement.bodyAsText
import io.ktor.client.statement.readRawBytes
import io.ktor.http.isSuccess

// True on a phone or tablet held in the hands, where swipes, holding to speed up and locking the controls make sense, and false on a computer with a mouse and keys.
expect val touchPlayer: Boolean

// Makes the window fill the whole screen and puts it back, for a computer. A phone has nothing to give.
class FullscreenControl(val active: Boolean, val toggle: () -> Unit)

val LocalFullscreen = staticCompositionLocalOf<FullscreenControl?> { null }

// The small floating player: picture in picture on a phone, and a small window that stays over the others on a computer. The player asks for it with the shape of its picture, the width over the height.
class MiniPlayerControl(val active: Boolean, val enter: (aspect: Float) -> Unit, val exit: () -> Unit)

val LocalMiniPlayer = staticCompositionLocalOf<MiniPlayerControl?> { null }

// Whether a video is playing now, so a phone can go to picture in picture by itself when the person leaves the app.
object PlayingNow {
    @kotlin.concurrent.Volatile
    var aspect: Float? = null
}

// On a phone, turns the screen sideways and hides the bars of the system from the moment an episode is opened until it is left.
@Composable
expect fun PlayerWindow()

// Holds the screen on while a video plays.
@Composable
expect fun PlayerSystemUi(keepOn: Boolean)

// Makes the engine of the system and lets go of it when the screen leaves. The style is how subtitles look.
@Composable
expect fun rememberPlayerEngine(style: SubtitleStyle): PlayerEngine

// Draws the picture of the engine in the space it is given.
@Composable
expect fun PlayerSurface(engine: PlayerEngine, aspect: AspectMode, modifier: Modifier)

// The client playlists are read with, made the first time one is.
private val playlists = lazy { HttpClient { install(HttpTimeout) { requestTimeoutMillis = 8_000 } } }

// Reads a playlist as text from its address with the headers a site wants, or gives null when it cannot be read in a few seconds.
suspend fun fetchPlaylist(url: String, headers: Map<String, String>): String? = runCatching {
    val response = playlists.value.get(url) { headers.forEach { (name, value) -> header(name, value) } }
    if (response.status.isSuccess()) response.bodyAsText() else null
}.getOrNull()

// Reads a small file, such as the key of a stream or one part of it, as bytes with the headers a site wants, or gives null when it cannot be read.
suspend fun fetchBytes(url: String, headers: Map<String, String>): ByteArray? = runCatching {
    val response = playlists.value.get(url) { headers.forEach { (name, value) -> header(name, value) } }
    if (response.status.isSuccess()) response.readRawBytes() else null
}.getOrNull()
