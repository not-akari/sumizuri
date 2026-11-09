package com.sumizuri.app.playback.hls

// Reads the master playlist of an HLS stream, which lists its qualities and its separate audio. Addresses in it may be relative and are made whole against the address of the playlist.
object HlsPlaylist {
    fun isMaster(text: String): Boolean = text.contains("#EXT-X-STREAM-INF")

    fun parseMaster(text: String, base: String): HlsMaster {
        val variants = mutableListOf<HlsVariant>()
        val audios = mutableListOf<HlsAudio>()
        val lines = text.lines().map { it.trim() }
        lines.forEachIndexed { index, line ->
            when {
                line.startsWith("#EXT-X-STREAM-INF:") -> {
                    val attributes = attributesOf(line.substringAfter(':'))
                    val address =
                        lines.drop(index + 1).firstOrNull { it.isNotEmpty() && !it.startsWith("#") }
                            ?: return@forEachIndexed
                    val height = attributes["RESOLUTION"]?.substringAfter('x', "")?.toIntOrNull()
                    variants +=
                        HlsVariant(
                            resolve(base, address),
                            attributes["BANDWIDTH"]?.toLongOrNull(),
                            height,
                            attributes["AUDIO"],
                        )
                }

                line.startsWith("#EXT-X-MEDIA:") -> {
                    val attributes = attributesOf(line.substringAfter(':'))
                    if (attributes["TYPE"] == "AUDIO") {
                        audios +=
                            HlsAudio(
                                attributes["GROUP-ID"].orEmpty(),
                                attributes["NAME"].orEmpty(),
                                attributes["LANGUAGE"],
                                attributes["URI"]?.let {
                                    resolve(base, it)
                                },
                                attributes["DEFAULT"] == "YES",
                            )
                    }
                }
            }
        }
        return HlsMaster(variants, audios)
    }

    // The separate audio a variant needs, when its group has a rendition with an address: the default one, or the first.
    fun audioFor(master: HlsMaster, variant: HlsVariant): HlsAudio? {
        val group = variant.audioGroup ?: return null
        val pool = master.audios.filter { it.group == group && it.uri != null }
        return pool.firstOrNull { it.isDefault } ?: pool.firstOrNull()
    }

    // The attributes of a tag as names and values, split at the commas that are not inside quotes.
    private fun attributesOf(text: String): Map<String, String> {
        val result = mutableMapOf<String, String>()
        val parts = mutableListOf<String>()
        val current = StringBuilder()
        var quoted = false
        for (char in text) {
            when {
                char == '"' -> {
                    quoted = !quoted
                    current.append(char)
                }

                char == ',' && !quoted -> {
                    parts += current.toString()
                    current.clear()
                }

                else -> current.append(char)
            }
        }
        parts += current.toString()
        for (part in parts) {
            val at = part.indexOf('=')
            if (at > 0) result[part.substring(0, at).trim()] = part.substring(at + 1).trim().trim('"')
        }
        return result
    }

    // An address made whole against the address it was found in.
    fun resolve(base: String, reference: String): String {
        if (SchemeStart.containsMatchIn(reference)) return reference
        val scheme = base.substringBefore("://", "https")
        if (reference.startsWith("//")) return "$scheme:$reference"
        val origin = OriginStart.find(base)?.value ?: return reference
        if (reference.startsWith("/")) return origin + reference
        val folder = base.substringBefore('?').substringBeforeLast('/', origin)
        return "$folder/$reference"
    }
}

// One quality of an HLS stream: where its playlist is, how many bits a second it takes, how tall its picture is, and the group of audio it goes with.
class HlsVariant(val uri: String, val bandwidth: Long?, val height: Int?, val audioGroup: String?)

// An audio rendition of an HLS stream. One with no address is carried inside the variants themselves.
class HlsAudio(val group: String, val name: String, val language: String?, val uri: String?, val isDefault: Boolean)

class HlsMaster(val variants: List<HlsVariant>, val audios: List<HlsAudio>)

// The scheme at the start of a whole address, and the scheme with the host. A saved episode resolves every one of its segments, so they are made once.
private val SchemeStart = Regex("^[a-zA-Z][a-zA-Z0-9+.-]*://")
private val OriginStart = Regex("^[a-zA-Z][a-zA-Z0-9+.-]*://[^/]+")
