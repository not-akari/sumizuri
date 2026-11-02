package com.sumizuri.app.feature.updates.row

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.Kind
import com.sumizuri.app.data.text.numberText
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.feed_chapter_range
import com.sumizuri.app.shared.resources.feed_chapter_titled
import com.sumizuri.app.shared.resources.feed_episode_range
import com.sumizuri.app.shared.resources.feed_episode_titled
import com.sumizuri.app.ui.text.numberedUnit
import org.jetbrains.compose.resources.stringResource

// A small tinted chip such as one new chapter, or grey for the count of the rest.
@Composable
internal fun FeedChip(label: String, quiet: Boolean = false) {
    val colors = MaterialTheme.colorScheme
    Text(
        label,
        Modifier.clip(RoundedCornerShape(10.dp)).background(if (quiet) colors.surfaceContainerHighest else colors.primary.copy(alpha = 0.14f)).padding(horizontal = 8.dp, vertical = 2.dp),
        style = MaterialTheme.typography.labelMedium,
        fontWeight = FontWeight.SemiBold,
        color = if (quiet) colors.onSurfaceVariant else colors.primary,
        // A chip stays one line, so a narrow row never breaks its word in half.
        maxLines = 1,
        overflow = TextOverflow.Ellipsis,
    )
}

// What a new chapter or episode is called: its number, and its name after it when it has one. A name that only says the number again, such as Chapter 281 for chapter 281, is left out.
@Composable
internal fun feedChapterText(kind: Kind, number: Double, name: String?): String = when {
    name.isNullOrBlank() || onlyNumber(name, number) -> numberedUnit(kind, number)
    kind == Kind.Anime -> stringResource(Res.string.feed_episode_titled, number.numberText(), name)
    else -> stringResource(Res.string.feed_chapter_titled, number.numberText(), name)
}

// What a row of a feed is called: the one chapter it holds with its name, or the first and the last number when it holds several.
@Composable
internal fun feedSpanText(kind: Kind, numbers: List<Double>, name: String?): String {
    val low = numbers.minOrNull() ?: return ""
    val high = numbers.max()
    if (low == high) return feedChapterText(kind, low, name)
    return stringResource(if (kind == Kind.Anime) Res.string.feed_episode_range else Res.string.feed_chapter_range, low.numberText(), high.numberText())
}

// The words of a name that are only a way of saying a chapter or an episode, in the languages sources use most.
private val NumberWords = setOf("chapter", "chap", "ch", "episode", "ep", "capitulo", "capítulo", "cap", "chapitre", "kapitel", "глава", "第", "话", "話", "화", "回")

// The marks between the words of a name, a dot after a word as in Ch.12, and the seams where letters meet digits as in 第12話.
private val Gaps = Regex("(?<=\\p{L})\\.|[^\\p{L}\\p{N}.]+")
private val Seams = Regex("(?<=\\p{L})(?=\\p{N})|(?<=\\p{N})(?=\\p{L})")

// True when a name is nothing but the number, with or without a word for chapter before or after it.
private fun onlyNumber(name: String, number: Double): Boolean {
    val words = name
        .lowercase()
        .replace(Gaps, " ")
        .replace(Seams, " ")
        .split(' ')
        .filter { it.isNotBlank() }
    val digits = words.filter { word -> word.any { it.isDigit() } }
    return digits.size == 1 && digits[0].trimEnd('.').toDoubleOrNull() == number && words.all { it in digits || it in NumberWords }
}
