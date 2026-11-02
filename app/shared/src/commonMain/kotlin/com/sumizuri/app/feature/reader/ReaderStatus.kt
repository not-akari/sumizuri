package com.sumizuri.app.feature.reader

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.ErrorOutline
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.sumizuri.app.data.model.ChapterPlace
import com.sumizuri.app.shared.resources.Res
import com.sumizuri.app.shared.resources.challenge_open
import com.sumizuri.app.shared.resources.try_again
import com.sumizuri.app.ui.kit.art.InkButton
import com.sumizuri.app.ui.kit.input.ActionButton
import com.sumizuri.app.ui.text.numberedUnit
import org.jetbrains.compose.resources.stringResource

// What the reader shows while the chapter is coming in, or why it cannot be shown, in the opening the player shares. The names of the reader win, and until it has them the ones the opener knew show, so the card is there from the start.
@Composable
fun ReaderStatus(
    state: ReaderState,
    onRetry: () -> Unit,
    onSolve: () -> Unit,
    onBack: () -> Unit,
    opening: ChapterPlace? = null,
) {
    val own = state.titleName.isNotEmpty()
    val known = own || opening != null
    val chapterName = if (own) state.chapterName else opening?.name?.takeIf { it.isNotBlank() }
    val number = if (own) state.chapterNumber else opening?.number ?: 0.0
    val message = state.message
    ChapterOpening(
        cover = state.coverUrl ?: opening?.coverUrl,
        sourceId = state.sourceId ?: opening?.sourceId,
        heading = if (known) chapterName ?: numberedUnit(opening?.kind ?: state.kind, number) else null,
        titleName = state.titleName.ifEmpty { opening?.titleName.orEmpty() },
        onBack = onBack,
        now = message != null,
        bottom = message?.let { { Failure(it, state.challengeUrl != null, onRetry, onSolve) } },
    )
}

// Why the chapter cannot be shown, with the ways out under it.
@Composable
private fun Failure(message: ReaderMessage, challenge: Boolean, onRetry: () -> Unit, onSolve: () -> Unit) {
    Column(horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(14.dp)) {
        Icon(Icons.Outlined.ErrorOutline, null, Modifier.size(32.dp), tint = MaterialTheme.colorScheme.error)
        Text(messageText(message), style = MaterialTheme.typography.bodyMedium, textAlign = TextAlign.Center)
        InkButton(onRetry) { Text(stringResource(Res.string.try_again)) }
        if (challenge) ActionButton(Res.string.challenge_open, onSolve)
    }
}

@Composable
private fun messageText(message: ReaderMessage): String = when (message) {
    is ReaderMessage.Fixed -> stringResource(message.text)
    is ReaderMessage.Detail -> message.text
}
