package com.sumizuri.app.ui.text

import androidx.compose.runtime.Composable
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.numberText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.chapter_number
import com.sumizuri.app.shared.resources.chapters_count
import com.sumizuri.app.shared.resources.episode_number
import com.sumizuri.app.shared.resources.episodes_count
import org.jetbrains.compose.resources.pluralStringResource
import org.jetbrains.compose.resources.stringResource
import kotlin.math.roundToLong

// 163 chapters or 12 episodes, with the plural of the language.
@Composable
fun unitCount(kind: Kind, count: Int): String = pluralStringResource(
    if (kind ==
        Kind.Anime
    ) {
        Res.plurals.episodes_count
    } else {
        Res.plurals.chapters_count
    },
    count,
    count,
)

// Chapter 12 or Episode 12, in the language of the screen.
@Composable
fun numberedUnit(kind: Kind, number: Double): String = stringResource(
    if (kind ==
        Kind.Anime
    ) {
        Res.string.episode_number
    } else {
        Res.string.chapter_number
    },
    number.numberText(),
)

// A size in bytes as a short number with a unit, such as 12.3 MB.
fun byteSizeText(bytes: Long): String {
    val units = listOf("B", "KB", "MB", "GB")
    var value = bytes.toDouble()
    var unit = 0
    while (value >= 1024 && unit < units.lastIndex) {
        value /= 1024
        unit++
    }
    val shown = if (unit == 0 ||
        value >= 100
    ) {
        value.roundToLong().toString()
    } else {
        ((value * 10).roundToLong() / 10.0).toString()
    }
    return "$shown ${units[unit]}"
}

// A chapter or an episode as its number and its name. A name that only says the number again, such as Episode 2 or Episode 2: Episode 2, is shown alone, and so is one that starts with the number, such as Episode 2: The Plan.
@Composable
fun numberedName(kind: Kind, number: Double, name: String?): String {
    val numbered = numberedUnit(kind, number)
    val text = name?.trim()?.takeIf { it.isNotEmpty() } ?: return numbered
    val head = text.substringBefore(':').trim()
    val tail = text.substringAfter(':', "").trim()
    val plain = if (tail.isNotEmpty() && tail.equals(head, ignoreCase = true)) head else text
    val starts = plain.startsWith(numbered, ignoreCase = true) && plain.getOrNull(numbered.length)?.isDigit() != true
    return if (starts) plain else "$numbered · $plain"
}
