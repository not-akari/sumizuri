package com.sumizuri.app.data.download

import kotlin.test.Test
import kotlin.test.assertEquals

class LocalPlaylistTest {
    // Segments, keys and maps point at local files, relative addresses are made whole, and a part listed twice is fetched once.
    @Test
    fun pointsEveryPartAtALocalFile() {
        val text = """
            #EXTM3U
            #EXT-X-KEY:METHOD=AES-128,URI="key.bin",IV=0x1
            #EXT-X-MAP:URI="/init.mp4"
            #EXTINF:4.0,
            seg/1.jpg?t=9
            #EXTINF:4.0,
            https://cdn.example/seg/2.html
            #EXT-X-BYTERANGE:100@0
            #EXTINF:4.0,
            seg/1.jpg?t=9
            #EXT-X-ENDLIST
        """.trimIndent()
        val (playlist, parts) = localPlaylist(text, "https://site.example/hls/main.m3u8?token=1", "v")
        assertEquals(
            listOf(
                "https://site.example/hls/key.bin",
                "https://site.example/init.mp4",
                "https://site.example/hls/seg/1.jpg?t=9",
                "https://cdn.example/seg/2.html",
            ),
            parts.map { it.url },
        )
        assertEquals(
            """
            #EXTM3U
            #EXT-X-KEY:METHOD=AES-128,URI="v00000.key",IV=0x1
            #EXT-X-MAP:URI="v00001.mp4"
            #EXTINF:4.0,
            v00002.m4s
            #EXTINF:4.0,
            v00003.m4s
            #EXT-X-BYTERANGE:100@0
            #EXTINF:4.0,
            v00002.m4s
            #EXT-X-ENDLIST
            """.trimIndent(),
            playlist,
        )
    }
}
